/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model that holds app state and the logic for updating the scene, placing spheres, and showing virtual content.
*/
import ARKit
import RealityKit
import SwiftUI

/// A model type that holds app state and processes updates from ARKit.
@Observable
@MainActor
class AppState {
    
    enum VisualizationState {
        case none
        case occlusion
        case wall
    }
    
    enum ErrorState: Equatable {
        case noError
        case providerNotSupported
        case providerNotAuthorized
        case sessionError(ARKitSession.Error)
        
        static func == (lhs: AppState.ErrorState, rhs: AppState.ErrorState) -> Bool {
            switch (lhs, rhs) {
            case (.noError, .noError): return true
            case (.providerNotSupported, .providerNotSupported): return true
            case (.providerNotAuthorized, .providerNotAuthorized): return true
            case (.sessionError(let lhsError), .sessionError(let rhsError)): return lhsError.code == rhsError.code
            default: return false
            }
        }
    }
    
    private let session = ARKitSession()
    private let worldTracking = WorldTrackingProvider()
    private let roomTracking = RoomTrackingProvider()
    
    /// Indicates whether an immersive space is currently open.
    var isImmersive: Bool = false
    
    // Indicates whether someone has selected and locked a wall.
    var isWallSelectionLocked: Bool = false
    
    var showPreviewSphere: Bool = false
    
    /// Root for all virtual content.
    private let contentRoot = Entity()
    /// Root for room boundary geometry.
    private let roomRoot = Entity()
    
    private let colliderWallsRoot = Entity()
    private let renderWallRoot = Entity()

    /// A dictionary that contains `RoomAnchor` structures.
    private var roomAnchors = [UUID: RoomAnchor]()
    /// A dictionary that contains `WorldAnchor` structures.
    private var worldAnchors = [UUID: WorldAnchor]()
    /// A dictionary that contains `ModelEntity` structures for spheres.
    private var sphereEntities = [UUID: ModelEntity]()
    /// A dictionary that contains `ModelEntity` structures for room anchors.
    private var roomEntities = [UUID: ModelEntity]()

    private var currentRenderedWall: Entity?
    
    var visualizationState: VisualizationState = VisualizationState.none {
        didSet {
            switch visualizationState {
            case .none:
                roomRoot.isEnabled = false
                renderWallRoot.isEnabled = false
            case .occlusion:
                roomRoot.isEnabled = true
                renderWallRoot.isEnabled = false
            case .wall:
                roomRoot.isEnabled = false
                renderWallRoot.isEnabled = true
            }
        }
    }

    // Material for spheres in the current room.
    private let inRoomSphereMaterial = SimpleMaterial(color: .green, roughness: 0.2, isMetallic: true)
    // Material for spheres not in the current rooms.
    private let outOfRoomSphereMaterial = SimpleMaterial(color: .red, roughness: 0.2, isMetallic: true)
    // Material the app applies to room entities to show occlusion effects.
    private let occlusionMaterial = OcclusionMaterial()
    // Material for current room walls.
    private var wallMaterial = UnlitMaterial(color: .blue)
    // Stores the current room ID. When the current room changes, unlock the selected wall.
    private var currentRoomID: UUID? {
        didSet {
            if oldValue != currentRoomID {
                isWallSelectionLocked = false
            }
        }
    }

    // When a person denies authorization or a data provider state changes to an error condition,
    // the main window displays an error message based on the `errorState`.
    var errorState: ErrorState = .noError
    
    init() {
        
        if !areAllDataProvidersSupported {
            errorState = .providerNotSupported
        }
        Task {
            if await !areAllDataProvidersAuthorized() {
                errorState = .providerNotAuthorized
            }
        }
        
        roomRoot.isEnabled = false
        renderWallRoot.isEnabled = false
        renderWallRoot.components[OpacityComponent.self] = .init(opacity: 0.3)
        colliderWallsRoot.components[OpacityComponent.self] = .init(opacity: 0)
        
        contentRoot.addChild(roomRoot)
        contentRoot.addChild(renderWallRoot)
        contentRoot.addChild(colliderWallsRoot)
    }
    
    /// Sets up the root entity in the scene.
    func setupContentEntity() -> Entity {
        return contentRoot
    }
    
    private var areAllDataProvidersSupported: Bool {
        return WorldTrackingProvider.isSupported && RoomTrackingProvider.isSupported
    }

    func areAllDataProvidersAuthorized() async -> Bool {
        // It's sufficient to check that the authorization status isn't 'denied'.
        // If it's `notdetermined`, ARKit presents a permission pop-up menu that appears as soon
        // as the session runs.
        let authorization = await ARKitSession().queryAuthorization(for: [.worldSensing])
        return authorization[.worldSensing] != .denied
    }

    func runSession() async {
        do {
            try await session.run([worldTracking, roomTracking])
        } catch {
            guard error is ARKitSession.Error else {
                preconditionFailure("Unexpected error \(error).")
            }
            // Session errors are handled in AppState.monitorSessionUpdates().
        }
    }
    
    private func isSphereInCurrentRoom(sphere: WorldAnchor) -> Bool {
        guard let currentRoom = roomTracking.currentRoomAnchor else {
            return false
        }
        let spherePosition = sphere.originFromAnchorTransform.columns.3.xyz
        return currentRoom.contains(spherePosition)
    }

    private func updateSphereState() {
        for (id, worldAnchor) in worldAnchors {
            sphereEntities[id]?.model?.materials = isSphereInCurrentRoom(sphere: worldAnchor) ? [inRoomSphereMaterial] : [outOfRoomSphereMaterial]
        }
    }

    /// From an array of candidate walls, gets the wall whose centroid has the shortest distance to a given queryWall.
    private func getNearestWall(queryWall: Entity, candidateWalls: [Entity]) -> Entity? {
        guard let queryWall = (queryWall as? ModelEntity) else {
            logger.error("Failed to get the centroid of the query wall.")
            return nil
        }
        guard let queryWallCentroid = queryWall.centroid else {
            logger.error("Failed to get the centroid of the query wall.")
            return nil
        }
        
        var nearestWall: Entity?
        var nearestDistance = Float.greatestFiniteMagnitude
        
        for candidateWall in candidateWalls {
            guard let model = candidateWall as? ModelEntity else {
                logger.error("Failed to get the centroid of a candidate wall.")
                continue
            }
            guard let candidateWallCentroid = model.centroid else {
                logger.error("Failed to get the centroid of a candidate wall.")
                continue
            }
            let candidateToQueryDistance = distance(candidateWallCentroid, queryWallCentroid)
            if candidateToQueryDistance < nearestDistance {
                nearestWall = candidateWall
                nearestDistance = candidateToQueryDistance
            }
        }
        return nearestWall
    }

    //  `AppState` is ready to lock the wall entity when there is an existing rendered wall entity.
    var readyToLockWall: Bool {
        currentRenderedWall != nil
    }
    
    private func updateLockedWall(wallCandidateEntities: [Entity]) {
        guard renderWallRoot.isEnabled else {
            return
        }
        
        guard let currentRenderedWall else {
            return
        }
        // Gets the nearest wall to the `currentRenderedWall`.
        guard let newWallToRender = getNearestWall(queryWall: currentRenderedWall, candidateWalls: wallCandidateEntities) else {
            logger.error("Failed to find the nearest wall to the rendered wall.")
            return
        }
        renderWallRoot.children.removeAll()
        self.currentRenderedWall = newWallToRender
        renderWallRoot.addChild(newWallToRender)
    }

    /// Updates the wall in front of the person when a wall isn't in a selected state.
    func updateFacingWall() {
        guard renderWallRoot.isEnabled && !isWallSelectionLocked else {
            return
        }
        // Update within 10 m.
        let distance: Float = 10
        
        let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())
        guard let deviceAnchor, deviceAnchor.isTracked == true else {
            return
        }
        let deviceInOriginCoordinates = deviceAnchor.originFromAnchorTransform
        
        let lookAtPointInDeviceCoordinate = SIMD4<Float>(0, 0, -distance, 1)
        let lookAtPointInOriginCoordinates = deviceInOriginCoordinates * lookAtPointInDeviceCoordinate
        
        guard let scene = colliderWallsRoot.scene else {
            logger.error("Failed to find the scene of `colliderWallsRoot`.")
            return
        }
        
        let hitWall = scene.raycast(from: deviceInOriginCoordinates.columns.3.xyz, to: lookAtPointInOriginCoordinates.xyz, query: .nearest)
        
        guard !hitWall.isEmpty else {
            return
        }
        // Render the first hit wall.
        renderWallRoot.children.removeAll()

        let hitEntity = hitWall[0].entity
        currentRenderedWall = hitEntity
        renderWallRoot.addChild(hitEntity)
    }
    
    /// Updates walls under the collider walls root.
    ///
    /// If someone has chosen and locked a wall, this method updates and renders that wall.
    /// If someone hasn't locked a wall, the method updates and renders the wall in front of
    /// them  in `WorldAndRoomView` at a rate of 10 Hz.
    private func updateCurrentRoomWalls(for roomAnchor: RoomAnchor) async {
        let newColliderWalls = Entity()
        let wallGeometries = roomAnchor.geometries(of: .wall)
        for wallGeometry in wallGeometries {
            guard let wallMeshResource = wallGeometry.asMeshResource() else {
                continue
            }
            
            let wallEntity = ModelEntity(mesh: wallMeshResource, materials: [wallMaterial])
            wallEntity.transform = Transform(matrix: roomAnchor.originFromAnchorTransform)
            
            guard let shape = try? await ShapeResource.generateStaticMesh(from: wallMeshResource) else {
                logger.error("Failed to create ShapeResource from wall geometries.")
                continue
            }
            
            wallEntity.collision = CollisionComponent(shapes: [shape], isStatic: true)
            newColliderWalls.addChild(wallEntity)
        }
        // Clear old walls.
        colliderWallsRoot.children.removeAll()
        colliderWallsRoot.addChild(newColliderWalls)
        
        if isWallSelectionLocked {
            let wallCandidateEntities = Array(newColliderWalls.children)
            updateLockedWall(wallCandidateEntities: wallCandidateEntities)
        }
    }
    
    /// Updates the room tracking anchor as new data arrives from ARKit.
    func processRoomTrackingUpdates() async {
        for await update in roomTracking.anchorUpdates {
            let roomAnchor = update.anchor
            switch update.event {
            case .removed:
                if roomAnchor.isCurrentRoom {
                    colliderWallsRoot.children.removeAll()
                    if let currentRenderedWall {
                        renderWallRoot.removeChild(currentRenderedWall)
                    }
                }
                roomAnchors.removeValue(forKey: roomAnchor.id)
                roomEntities[roomAnchor.id]?.removeFromParent()
                roomEntities.removeValue(forKey: roomAnchor.id)
                updateSphereState()
            case .added, .updated:
                roomAnchors[roomAnchor.id] = roomAnchor
                guard let roomMeshResource = roomAnchor.geometry.asMeshResource() else { continue }
                if update.event == .added {
                    let roomEntity = ModelEntity(mesh: roomMeshResource, materials: [occlusionMaterial])
                    roomEntity.transform = Transform(matrix: roomAnchor.originFromAnchorTransform)
                    roomEntities[roomAnchor.id] = roomEntity
                    roomEntity.isEnabled = roomAnchor.isCurrentRoom
                    roomRoot.addChild(roomEntity)
                    
                } else if update.event == .updated {
                    guard let roomEntity = roomEntities[roomAnchor.id] else { continue }
                    roomEntity.model?.mesh = roomMeshResource
                    roomEntity.transform = Transform(matrix: roomAnchor.originFromAnchorTransform)
                    roomEntity.isEnabled = roomAnchor.isCurrentRoom
                }
                
                updateSphereState()
                
                if roomAnchor.isCurrentRoom {
                    currentRoomID = roomAnchor.id
                    if renderWallRoot.isEnabled {
                        await updateCurrentRoomWalls(for: roomAnchor)
                    }
                }
            }
        }
    }

    /// Updates the world tracking anchor as new data arrives from ARKit.
    func processWorldTrackingUpdates() async {
        for await update in worldTracking.anchorUpdates {
            let worldAnchor = update.anchor
            switch update.event {
            case .added:
                let sphereMesh = MeshResource.generateSphere(radius: 0.1)
                let isInCurrentRoom = isSphereInCurrentRoom(sphere: worldAnchor)
                let material = isInCurrentRoom ? inRoomSphereMaterial : outOfRoomSphereMaterial
                let sphereEntity = ModelEntity(mesh: sphereMesh, materials: [material])
                sphereEntity.transform = Transform(matrix: worldAnchor.originFromAnchorTransform)
                
                worldAnchors[worldAnchor.id] = worldAnchor
                sphereEntities[worldAnchor.id] = sphereEntity
                contentRoot.addChild(sphereEntity)
                
            case .updated:
                guard let entity = sphereEntities[worldAnchor.id] else {
                    logger.info("No existing world tracking entity found.")
                    return
                }
                worldAnchors[worldAnchor.id] = worldAnchor
                entity.transform = Transform(matrix: worldAnchor.originFromAnchorTransform)
                let isInCurrentRoom = isSphereInCurrentRoom(sphere: worldAnchor)
                let material = isInCurrentRoom ? inRoomSphereMaterial : outOfRoomSphereMaterial
                entity.model?.materials = [material]
            case .removed:
                sphereEntities[worldAnchor.id]?.removeFromParent()
                sphereEntities.removeValue(forKey: worldAnchor.id)
                worldAnchors.removeValue(forKey: worldAnchor.id)
            }
        }
    }
    
    /// Responds to events such as authorization revocation.
    func monitorSessionUpdates() async {
        for await event in session.events {
            logger.info("\(event.description)")
            switch event {
            case .authorizationChanged(type: _, status: let status):
                logger.info("Authorization changed to: \(status)")
                
                if status == .denied {
                    errorState = .providerNotAuthorized
                }
            case .dataProviderStateChanged(dataProviders: let providers, newState: let state, error: let error):
                logger.info("Data providers state changed: \(providers), \(state)")
                if let error {
                    logger.error("Data provider reached an error state: \(error)")
                    errorState = .sessionError(error)
                }
            @unknown default:
                fatalError("Unhandled new event type \(event)")
            }
        }
    }
    
    func removeAllWorldAnchors() async {
        for (id, _) in worldAnchors {
            do {
                try await worldTracking.removeAnchor(forID: id)
            } catch {
                logger.info("Failed to remove world anchor id \(id).")
            }
        }
    }
    
    /// Creates a world anchor with the input transform and adds the anchor to the world tracking provider.
    func addWorldAnchor(at transform: simd_float4x4) async {
        
        let worldAnchor = WorldAnchor(originFromAnchorTransform: transform)
        do {
            try await self.worldTracking.addAnchor(worldAnchor)
        } catch {
            // Adding world anchors can fail, for example when you reach the limit
            // for total world anchors per app.
            logger.error("Failed to add world anchor \(worldAnchor.id) with error: \(error).")
        }
    }
}

