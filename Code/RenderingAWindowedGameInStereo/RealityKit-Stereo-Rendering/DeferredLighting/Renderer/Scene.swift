/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A container for all of the resources (textures, buffers, and meshes) that the renderer uses.
*/


import MetalKit

// The max number of command buffers in flight
let maxFramesInFlight = 3

// MARK: - Scene
class Scene {
    
    var camera = Camera(nearPlane: 1, farPlane: 150, fieldOfView: 65)
    
    // Current frame number
    var frameTime: Float = 0.0

    // The total number of lights
    let numberOfLights = 256
    
    // 30% of lights are around the tree
    let treeLights: Int
    
    // 40% of lights are on the ground inside the columns
    let groundLights: Int
    
    // 30% of lights are around the outside of the columns
    let columnLights: Int
    
    // Number of vertices in our 2D fairy model
    let fairyVerticesCount = 7
    
    // The projection matrix for the shadow map pass
    let shadowProjectionMatrix = Transform.orthographicProjection(-53, 53, -33, 53, -53, 53)
    
    // Current buffer index to fill with dynamic uniform data and set for the current frame
    var currentBufferIndex: Int = 0
    
    // The textures that make up the "geometry buffer".
    var gBufferTextures = GBufferTextures()
    
    // Depth texture used to render shadows
    let shadowMap: MTLTexture

    // Buffers used to store dynamically changing per frame data
    private var frameDataBuffers = [BufferView<AAPLFrameData>]()

    // Returns the frameData buffer for the current frame.
    var frameData: BufferView<AAPLFrameData> {
        frameDataBuffers[currentBufferIndex]
    }

    // Buffers used to story dynamically changing light positions
    private var lightPositionsBuffers = [BufferView<SIMD4<Float>>]()
    
    var lightPositions: BufferView<SIMD4<Float>> {
        lightPositionsBuffers[currentBufferIndex]
    }
    
    // Light positions before transformation to positions in current frame
    private var originalLightPositions = [SIMD4<Float>]()
    
    // Buffer for constant light data
    let pointLights: BufferView<AAPLPointLight>
    
    // Mesh for an icosahedron used for rendering point lights
    let icosahedron: Mesh
    
    // Array of meshes loaded from the model file
    var meshes = [Mesh]()
    
    // Mesh buffer for simple Quad
    let quadVertexBuffer: BufferView<AAPLSimpleVertex>
    
    // Mesh for sphere use to render the skybox
    var skyMesh: Mesh!
    
    // Texture for skybox
    var skyMap: MTLTexture!
    
    // Mesh buffer for fairies
    var fairy: BufferView<AAPLSimpleVertex>!
    
    // Texture to create smooth round particles
    var fairyMap: MTLTexture!
    
    // Default look at parameters
    let eyePosition = SIMD3<Float>(x: 0, y: 18, z: -50)
    let targetPosition = SIMD3<Float>(x: 0, y: 5, z: 0)

    let up = SIMD3<Float>(x: 0, y: 1, z: 0)
    
    // Vertex descriptor for models loaded with MetalKit
    let defaultVertexDescriptor: MTLVertexDescriptor = {
        let descriptor = MTLVertexDescriptor()
        // Positions.
        let position = descriptor.attributes[AAPLVertexAttributePosition.rawValue]
        position.format = .float3
        position.bufferIndex = Int(AAPLBufferIndexMeshPositions.rawValue)
        
        // Texture coordinates.
        let texcoord = descriptor.attributes[AAPLVertexAttributeTexcoord.rawValue]
        texcoord.format = .float2
        texcoord.bufferIndex = Int(AAPLBufferIndexMeshGenerics.rawValue)
        
        // Normals.
        let normals = descriptor.attributes[AAPLVertexAttributeNormal.rawValue]
        normals.format = .half4
        normals.offset = 8
        normals.bufferIndex = Int(AAPLBufferIndexMeshGenerics.rawValue)
        
        // Tangents.
        let tangents = descriptor.attributes[AAPLVertexAttributeTangent.rawValue]
        tangents.format = .half4
        tangents.offset = 16
        tangents.bufferIndex = Int(AAPLBufferIndexMeshGenerics.rawValue)
        
        // Bitangents.
        let bitangents = descriptor.attributes[AAPLVertexAttributeBitangent.rawValue]
        bitangents.format = .half4
        bitangents.offset = 24
        bitangents.bufferIndex = Int(AAPLBufferIndexMeshGenerics.rawValue)
        
        // Position Buffer Layout.
        descriptor.layouts[AAPLBufferIndexMeshPositions.rawValue].stride = 12
        
        // Generic Attribute Buffer Layout.
        descriptor.layouts[AAPLBufferIndexMeshGenerics.rawValue].stride = 32
        
        return descriptor
    }()
    
    // Vertex descriptor for models loaded with MetalKit
    let skyVertexDescriptor: MTLVertexDescriptor = {
        let descriptor = MTLVertexDescriptor()
        
        let position = descriptor.attributes[AAPLVertexAttributePosition.rawValue]
        position.format = .float3
        position.offset = 0
        position.bufferIndex = Int(AAPLBufferIndexMeshPositions.rawValue)
        
        descriptor.layouts[AAPLBufferIndexMeshPositions.rawValue].stride = 12
        
        let normals = descriptor.attributes[AAPLVertexAttributeNormal.rawValue]
        normals.format = .float3
        normals.offset = 0
        normals.bufferIndex = Int(AAPLBufferIndexMeshGenerics.rawValue)
        
        descriptor.layouts[AAPLBufferIndexMeshGenerics.rawValue].stride = 12
        return descriptor
    }()

    init(device: MTLDevice) {
        
        treeLights = Int(0.30 * Float(numberOfLights))
        groundLights = Int(Float(treeLights) + 0.40 * Float(numberOfLights))
        columnLights = Int(Float(groundLights) + 0.30 * Float(numberOfLights))
        
        // Create shadow map texture.
        let shadowTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(pixelFormat: .depth32Float,
                                 width: 2048,
                                 height: 2048,
                                 mipmapped: false)
        shadowTextureDescriptor.resourceOptions = .storageModePrivate
        shadowTextureDescriptor.usage = [.renderTarget, .shaderRead]
        
        guard let shadowMap = device.makeTexture(descriptor: shadowTextureDescriptor) else {
            fatalError("Failed to make shadowMap with: \(shadowTextureDescriptor.description)")
        }
        shadowMap.label = "Shadow Map"
        
        self.shadowMap = shadowMap
        
        // Create quad for fullscreen composition drawing
        let quadVertices: [AAPLSimpleVertex] = [
            .init(position: .init(x: -1, y: -1)),
            .init(position: .init(x: -1, y: 1)),
            .init(position: .init(x: 1, y: -1)),
            
            .init(position: .init(x: 1, y: -1)),
            .init(position: .init(x: -1, y: 1)),
            .init(position: .init(x: 1, y: 1))
        ]
        
        quadVertexBuffer = .init(device: device, array: quadVertices)
        
        pointLights = .init(device: device,
                            count: numberOfLights,
                            label: "LightData",
                            options: .storageModeShared)
        
        let storageMode = MTLResourceOptions.storageModeShared
        for index in 0..<maxFramesInFlight {
            let frameDataBuffer = BufferView<AAPLFrameData>(device: device,
                                                     count: 1,
                                                     label: "FrameData \(index)",
                                                     options: storageMode)
            frameDataBuffers.append(frameDataBuffer)
            
            let lightPositionsBuffer = BufferView<SIMD4<Float>>(device: device,
                                                            count: numberOfLights,
                                                            label: "LightPositions \(index)",
                                                            options: storageMode)
            lightPositionsBuffers.append(lightPositionsBuffer)
        }

        // Create a ModelIO vertexDescriptor so that the format/layout of the ModelIO mesh vertices
        //   cah be made to match Metal render pipeline's vertex descriptor layout
        let modelIOVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(defaultVertexDescriptor)
        
        // Indicate how each Metal vertex descriptor attribute maps to each ModelIO  attribute
        modelIOVertexDescriptor.attribute(AAPLVertexAttributePosition.rawValue).name = MDLVertexAttributePosition
        modelIOVertexDescriptor.attribute(AAPLVertexAttributeTexcoord.rawValue).name = MDLVertexAttributeTextureCoordinate
        modelIOVertexDescriptor.attribute(AAPLVertexAttributeNormal.rawValue).name = MDLVertexAttributeNormal
        modelIOVertexDescriptor.attribute(AAPLVertexAttributeTangent.rawValue).name = MDLVertexAttributeTangent
        modelIOVertexDescriptor.attribute(AAPLVertexAttributeBitangent.rawValue).name = MDLVertexAttributeBitangent
        
        guard let modelFileURL = Bundle.main.url(forResource: "Temple", withExtension: "obj") else {
            fatalError("Assets/Meshes/Temple.obj not found in Main Bundle.")
        }
        
        meshes = Mesh.loadMeshes(url: modelFileURL, vertexDescriptor: modelIOVertexDescriptor, device: device)
        
        // Create an icosahedron mesh for fairy light volumes
        do {
            let bufferAllocator = MTKMeshBufferAllocator(device: device)
            
            let unitInscribe = sqrtf(3.0) / 12.0 * (3.0 + sqrtf(5.0))
            
            let icosahedronMDLMesh = MDLMesh.newIcosahedron(withRadius: 1 / unitInscribe, inwardNormals: false, allocator: bufferAllocator)
            
            let icosahedronDescriptor = MDLVertexDescriptor()
            
            let positionAttribute = icosahedronDescriptor.attribute(AAPLVertexAttributePosition.rawValue)
            positionAttribute.name = MDLVertexAttributePosition
            positionAttribute.format = .float4
            positionAttribute.offset = 0
            positionAttribute.bufferIndex = .init(AAPLBufferIndexMeshPositions.rawValue)

            icosahedronDescriptor.layout(AAPLVertexAttributePosition.rawValue).stride = .init(MemoryLayout<SIMD4<Float>>.stride)
            
            icosahedronMDLMesh.vertexDescriptor = icosahedronDescriptor
            
            do {
                let mtkMesh = try MTKMesh(mesh: icosahedronMDLMesh, device: device)
                icosahedron = Mesh(metalKitMesh: mtkMesh)
            } catch {
                fatalError("Failed to create MTKMesh: \(error.localizedDescription)")
            }
        }
        
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        
        let sphereMDLMesh = MDLMesh.newEllipsoid(withRadii: SIMD3<Float>(repeating: 150),
                                                 radialSegments: 20,
                                                 verticalSegments: 20,
                                                 geometryType: .triangles,
                                                 inwardNormals: false,
                                                 hemisphere: false,
                                                 allocator: bufferAllocator)
        
        let sphereDescriptor = MTKModelIOVertexDescriptorFromMetal(skyVertexDescriptor)
        sphereDescriptor.attribute(AAPLVertexAttributePosition.rawValue).name = MDLVertexAttributePosition
        sphereDescriptor.attribute(AAPLVertexAttributeNormal.rawValue).name = MDLVertexAttributeNormal
        
        // Set the vertex descriptor to relayout vertices
        sphereMDLMesh.vertexDescriptor = sphereDescriptor
        
        do {
            let metalKitMesh = try MTKMesh(mesh: sphereMDLMesh, device: device)
            skyMesh = Mesh(metalKitMesh: metalKitMesh)
        } catch {
            fatalError("Failed to create MTKMesh: \(error.localizedDescription)")
        }
        
        let textureLoader = MTKTextureLoader(device: device)
        
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [.textureUsage: MTLTextureUsage.shaderRead.rawValue,
                                                                    .textureStorageMode: MTLStorageMode.private.rawValue]
        
        do {
            let skyMap = try textureLoader.newTexture(name: "SkyMap",
                                              scaleFactor: 1.0,
                                              bundle: nil,
                                              options: textureLoaderOptions)
            skyMap.label = "Sky Map"
            
            self.skyMap = skyMap
        } catch {
            fatalError("Failed to create texture: \(error.localizedDescription)")
        }
        
        // Create a simple 2D triangle strip circle mesh for fairies
        var fairyVertices = [AAPLSimpleVertex]()
        let angle = 2 * .pi / Float(fairyVerticesCount)
        for index in 0..<fairyVerticesCount {
            let point = Float((index % 2) == 1 ? (index + 1) / 2 : -index / 2)
            let position = SIMD2<Float>(sinf(point * angle), cosf(point * angle))
            fairyVertices.append(AAPLSimpleVertex(position: position))
        }
        
        fairy = .init(device: device, array: fairyVertices)
        
        do {
            fairyMap = try textureLoader.newTexture(name: "FairyMap",
                                                    scaleFactor: 1.0,
                                                    bundle: nil,
                                                    options: textureLoaderOptions)
            
        } catch {
            fatalError("Failed to create texture: \(error.localizedDescription)")
        }
                
        populateLights()
    }
    
    /// Initialize light positions and colors
    func populateLights() {
                
        for index in 0..<numberOfLights {
            var distance: Float = 0
            var height: Float = 0
            var angle: Float = 0
            var speed: Float = 0
            
            if index < treeLights {
                distance = .random(in: 38...42)
                height = .random(in: 0...1)
                angle = .random(in: 0...(2 * .pi))
                speed = .random(in: 0.003...0.014)
            } else if index < groundLights {
                distance = .random(in: 140...260)
                height = .random(in: 140...150)
                angle = .random(in: 0...(2 * .pi))
                speed = .random(in: 0.006...0.027)
                speed *= .randomSign
            } else if index < columnLights {
                distance = .random(in: 365...380)
                height = .random(in: 150...190)
                angle = .random(in: 0...2 * .pi)
                speed = .random(in: 0.004...0.014)
                speed *= .randomSign
            }
            
            speed *= 0.5
            
            let position = SIMD4<Float>(distance * sinf(angle), height, distance * cosf(angle), 1)
            originalLightPositions.append(position)
            
            var pointLight = AAPLPointLight()
            
            pointLight.light_radius = .random(in: 25...35) / 10.0
            pointLight.light_speed = speed
            
            let colorId = .random(in: 0...Int.max) % 3
            if colorId == 0 {
                pointLight.light_color = .init(x: .random(in: 4...6), y: .random(in: 0...4), z: .random(in: 0...4))
            } else if colorId == 1 {
                pointLight.light_color = .init(x: .random(in: 0...4), y: .random(in: 4...6), z: .random(in: 0...4))
            } else {
                pointLight.light_color = .init(x: .random(in: 0...4), y: .random(in: 0...4), z: .random(in: 4...6))
            }
            pointLights.assign(pointLight, at: index)
        }
    }
    
    /// Update light positions for the current frame.
    func updateLights(frameTime: Float, modelViewMatrix: simd_float4x4) {

        for lightIndex in 0..<numberOfLights {
            var currentPosition = SIMD4<Float>.zero
            let pointLight: AAPLPointLight = pointLights[lightIndex]

            if lightIndex < treeLights {
                
                var lightPeriod = Double(pointLight.light_speed * frameTime)

                lightPeriod += Double(originalLightPositions[lightIndex].y)
                lightPeriod -= floor(lightPeriod)

                // Use pow to slowly move the light outward as it reaches the branches of the tree
                let r = 1.2 + 10.0 * powf(Float(lightPeriod), 5.0)
                
                currentPosition.x = originalLightPositions[lightIndex].x * r
                currentPosition.y = 200.0 + Float(lightPeriod) * 400.0
                currentPosition.z = originalLightPositions[lightIndex].z * r
                currentPosition.w = 1
            } else {
                let rotationRadians = pointLight.light_speed * frameTime
                let rotation = Transform.rotationMatrix(radians: rotationRadians, axis: .init(x: 0, y: 1, z: 0))
                currentPosition = rotation * originalLightPositions[lightIndex]
            }
            
            currentPosition = modelViewMatrix * currentPosition
            
            lightPositionsBuffers[currentBufferIndex].assign(currentPosition, at: lightIndex)
        }
    }

    func simulate(deltaTime: TimeInterval) {
        frameTime += Float(deltaTime)
    }

    var sceneScale: Float = 1.0
    var sceneTranslation: SIMD3<Float> = .init()

    /// Update resources for the current frame.
    func update(viewMatrix: simd_float4x4, projectionMatrix: simd_float4x4) {

        var frameData = AAPLFrameData()
        
        // Set projection matrix and calculate inverted projection matrix
        frameData.projection_matrix = projectionMatrix // camera.projectionMatrix
        frameData.projection_matrix_inverse = projectionMatrix.inverse // camera.projectionMatrix.inverse
        
        // Set screen dimensions
        frameData.framebuffer_width = gBufferTextures.width
        frameData.framebuffer_height = gBufferTextures.height
        
        frameData.shininess_factor = 1
        frameData.fairy_specular_intensity = 32

        let cameraAnimation: Bool = false

        let cameraRotationRadians = (cameraAnimation ? frameTime * 0.0025 : 0) + .pi

        let cameraRotationAxis = SIMD3<Float>(0, 1, 0)
        let cameraRotationMatrix = Transform.rotationMatrix(radians: cameraRotationRadians, axis: cameraRotationAxis)
        
        let rotatedViewMatrix = viewMatrix * cameraRotationMatrix
        frameData.view_matrix = rotatedViewMatrix
        
        let templeScaleMatrix = Transform.scaleMatrix(.init(0.1, 0.1, 0.1) * sceneScale)

        let templeTranslationMatrix = Transform.translationMatrix(.init(0, -10, 0) + sceneTranslation)
        let templeModelMatrix = templeTranslationMatrix * templeScaleMatrix
        frameData.temple_model_matrix = templeModelMatrix
        frameData.temple_modelview_matrix = rotatedViewMatrix * templeModelMatrix
        frameData.temple_normal_matrix = Transform.normalMatrix(from: templeModelMatrix)
        
        let skyRotation = frameTime * 0.005 - .pi * 0.75
        let skyRotationAxis = SIMD3<Float>(0, 1, 0)
        let skyModelMatrix = Transform.rotationMatrix(radians: skyRotation, axis: skyRotationAxis)
        frameData.sky_modelview_matrix = cameraAnimation ? (cameraRotationMatrix * skyModelMatrix) : cameraRotationMatrix

        // Update directional light color
        let sunColor = SIMD4<Float>(0.5, 0.5, 0.5, 1)
        frameData.sun_color = sunColor
        frameData.sun_specular_intensity = 1
        
        // Update sun direction in view space
        let sunModelPosition = SIMD4<Float>(-0.25, -0.5, 1, 0)
        let sunWorldPosition = skyModelMatrix * sunModelPosition
        let sunWorldDirection = -sunWorldPosition
        
        frameData.sun_eye_direction = rotatedViewMatrix * sunWorldDirection
        
        let directionalLightUpVector = normalize((skyModelMatrix * SIMD4<Float>(0, 1, 1, 1)).xyz)
        let shadowViewMatrix = Transform.look(eye: sunWorldDirection.xyz / 10, target: .zero, up: directionalLightUpVector)
        let shadowModelViewMatrix = shadowViewMatrix * templeModelMatrix
        frameData.shadow_mvp_matrix = shadowProjectionMatrix * shadowModelViewMatrix
        
        // When calculating texture coordinates to sample from shadow map, flip the y/t coordinate and
        // convert from the [-1, 1] range of clip coordinates to the [0, 1] range
        // used for texture sampling
        let shadowScale = Transform.scaleMatrix(.init(0.5, -0.5, 1))
        let shadowTranslate = Transform.translationMatrix(.init(0.5, 0.5, 0))
        let shadowTransform = shadowTranslate * shadowScale
        
        frameData.shadow_mvp_xform_matrix = shadowTransform * frameData.shadow_mvp_matrix
        
        frameData.fairy_size = 0.4
        
        currentBufferIndex = (currentBufferIndex + 1) % maxFramesInFlight
        
        frameDataBuffers[currentBufferIndex].assign(frameData)
        
        updateLights(frameTime: frameTime, modelViewMatrix: frameData.temple_modelview_matrix)
    }
    
    func setGBufferTextures(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setFragmentTexture(gBufferTextures.albedoSpecular, index: Int(AAPLRenderTargetAlbedo.rawValue))
        renderEncoder.setFragmentTexture(gBufferTextures.normalShadow, index: Int(AAPLRenderTargetNormal.rawValue))
        renderEncoder.setFragmentTexture(gBufferTextures.depth, index: Int(AAPLRenderTargetDepth.rawValue))
    }
    
    func setGBufferTextures(_ renderPassDescriptor: MTLRenderPassDescriptor) {
        renderPassDescriptor.colorAttachments[Int(AAPLRenderTargetAlbedo.rawValue)].texture = gBufferTextures.albedoSpecular
        
        renderPassDescriptor.colorAttachments[Int(AAPLRenderTargetNormal.rawValue)].texture = gBufferTextures.normalShadow
        
        renderPassDescriptor.colorAttachments[Int(AAPLRenderTargetDepth.rawValue)].texture = gBufferTextures.depth
    }
    
}
