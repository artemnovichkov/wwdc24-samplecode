/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Data model for maintaining the app state.
*/

import Foundation
import RealityKit

import os

private let logger = Logger(subsystem: ObjectCaptureReconstructionApp.subsystem,
                            category: "AppDataModel")

@MainActor @Observable class AppDataModel {
    enum State {
        case ready
        case reconstructing
        case viewing
        case error
    }

    // The session to manage the creation of 3D models.
    private(set) var session: PhotogrammetrySession?

    // App's current state.
    var state: State = .ready {
        didSet {
            logger.log("State switched to \(String(describing: self.state))")
            if state == .ready { session = nil }
        }
    }

    // The folder where the images are stored.
    var imageFolder: URL?

    // The folder where the models are stored.
    var modelFolder: URL?

    // The model name selected by the person.
    var modelName: String?

    // The first generated model file to display through ModelView.
    var modelFileURLToDisplay: URL?

    // The session configuration set by the person in SettingsView.
    var sessionConfiguration: PhotogrammetrySession.Configuration = PhotogrammetrySession.Configuration()

    // The detail levels that show up under the Quality menu in SettingsView.
    var detailLevelOptionsUnderQualityMenu = PhotogrammetrySession.Request.Detail.medium

    // The detail levels that show up under the Advanced Reconstruction Options in SettingsView.
    var detailLevelOptionsUnderAdvancedMenu: Set<PhotogrammetrySession.Request.Detail> = []

    // The alert message shown in the pop up when the app goes into the error state.
    var alertMessage: String = ""

    // This is the number of models that the person has requested.
    var numRequestedModels = 0
    
    // Used to enable or disable the crop menu option.
    var boundingBoxAvailable = false

    // Creates a PhotogrammetrySession to generate 3D models for all detail levels requested by the person for the images in the imageFolder.
    // The models are saved in the modelFolder. The model name consists of the modelName and its detail level.
    func startReconstruction() async {
        // Go to the error state if the required fileds aren't filled.
        guard let imageFolder = imageFolder else {
            alertMessage = "Image folder is not selected"
            state = .error
            logger.info("\(self.alertMessage)")
            return
        }
        guard let modelName = modelName else {
            alertMessage = "Model name is not selected"
            state = .error
            logger.info("\(self.alertMessage)")
            return
        }
        guard let modelFolder = modelFolder else {
            alertMessage = "Model folder is not selected"
            state = .error
            logger.info("\(self.alertMessage)")
            return
        }

        // Get a list of all detail levels selected by the person through both the Quality menu and under the Advanced Reconstruction options.
        var detailLevelList = detailLevelOptionsUnderAdvancedMenu
        detailLevelList.insert(detailLevelOptionsUnderQualityMenu)
        
        // Create a request for each detail level.
        var requests: [PhotogrammetrySession.Request] = []
        for detailLevel in detailLevelList {
            let modelFileURL = modelFolder.appending(path: (modelName) + "-\(detailLevel)" + ".usdz")
            requests.append(PhotogrammetrySession.Request.modelFile(url: modelFileURL, detail: detailLevel))
        }
        numRequestedModels = detailLevelList.count

        // Update the app's state so that ProcessingView is visible.
        state = .reconstructing

        do {
            // Create the session.
            logger.log("Creating the session...")
            session = try await createSession(imageFolder: imageFolder, configuration: sessionConfiguration)

            // Start processing the requests.
            logger.log("Processing requests...")
            try session?.process(requests: requests)
            logger.log("Processing requests started...")
        } catch {
            logger.warning("Creating the session or processing the session failed!")
            alertMessage = "\(error)"
            state = .error
        }
    }

    // Create a PhotogrammetrySession asynchronously.
    nonisolated private func createSession(imageFolder: URL,
                                           configuration: PhotogrammetrySession.Configuration) async throws -> PhotogrammetrySession {
        logger.log("Creating PhotogrammetrySession with \(String(describing: configuration))")
        return try PhotogrammetrySession(input: imageFolder, configuration: configuration)
    }
}

extension PhotogrammetrySession.Error: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidImages:
            return "No valid images found in selected folder"
        case .invalidOutput:
            return "Cannot save to selected folder"
        case .insufficientStorage:
            return "Not enough disk space available to begin processing."
        @unknown default:
            logger.warning("Unknown Error case: \(self)")
            return "\(self)"
        }
    }
}

extension PhotogrammetrySession.Configuration.CustomDetailSpecification.TextureFormat: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .png: break
        case .jpeg(let compressionQuality):
            hasher.combine(compressionQuality)
        @unknown default:
            fatalError("Unknown texture format: \(self)")
        }
    }
}
