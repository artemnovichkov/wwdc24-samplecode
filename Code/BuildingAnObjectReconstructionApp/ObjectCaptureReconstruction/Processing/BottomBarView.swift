/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Show the reconstruction progress.
*/

import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: ObjectCaptureReconstructionApp.subsystem,
                            category: "BottomBarView")

struct BottomBarView: View {
    @Binding var firstModelFileURL: URL?
    @Binding var processedRequestsDetailLevel: [String]

    @Environment(AppDataModel.self) private var appDataModel: AppDataModel
    @State private var progress = 0.0
    @State private var estimatedRemainingTime: TimeInterval?
    @State private var currentRequestDetailLevel: PhotogrammetrySession.Request.Detail?
    @State private var processingComplete = false
    @State private var isCancelling = false
    @State private var numProcessedModels = 1

    var body: some View {
        VStack {
            if processingComplete {
                HStack {
                    Text("All models completed.")
                    
                    Spacer()
                    
                    Button("Reprocess...") {
                        appDataModel.state = .ready
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 16)
            } else {
                HStack {
                    if let imageFolder = appDataModel.imageFolder, let firstImageURL = getFirstImage(from: imageFolder) {
                        ThumbnailView(imageFolderURL: firstImageURL)
                            .frame(width: 55, height: 55)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(statusMessage)

                        HStack {
                            if appDataModel.session != nil {
                                ProgressView(value: progress)
                                .task {
                                    await getSessionOutput()
                                }
                            } else {
                                ProgressView(value: 0)
                            }
                            
                            Button {
                                logger.log("Cancel button is clicked!")
                                isCancelling = true
                                if let session = appDataModel.session {
                                    logger.log("Cancelling the session...")
                                    session.cancel()
                                } else {
                                    logger.log("Canceled the session before processing has started. Going back to the settings view...")
                                    logger.log("session: \(String(describing: appDataModel.session))")
                                    logger.log("session: \(String(describing: appDataModel.session?.isProcessing))")
                                    appDataModel.state = .ready
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        HStack {
                            Text(formattedEstimatedRemainingTime)
                            
                            Spacer()
                            
                            Text("Model \(numProcessedModels) of \(appDataModel.numRequestedModels)")
                        }
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    }
                }
                .padding()
            }
        }
    }

    private var statusMessage: String {
        guard appDataModel.session != nil, let currentRequestDetailLevel = currentRequestDetailLevel else { return "Preparing images..." }
        let detailLevel = "\(String(describing: currentRequestDetailLevel))".capitalized
        return "Creating \(detailLevel) 3D Model..."
    }

    private var formattedEstimatedRemainingTime: String {
        let calculating = "Calculating..."
        guard let estimatedRemainingTime = estimatedRemainingTime else { return calculating }

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.minute, .second]
        
        if let estimatedRemainingTime = formatter.string(from: estimatedRemainingTime) {
            return "About " + estimatedRemainingTime + " remaining"
        } else {
            return calculating
        }
    }

    private func getFirstImage(from url: URL) -> URL? {
        let imagesURL: URL? = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [])
            .filter { !$0.hasDirectoryPath && isLoadableImageFile($0) }
            .sorted(by: { $0.path < $1.path })
            .first
        return imagesURL
    }

    private func isLoadableImageFile(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        let suffix = url.pathExtension.lowercased()
        return ImageHelper.validImageSuffixes.contains(suffix)
    }
    
    func getSessionOutput() async {
        do {
            guard let session = appDataModel.session else { return }
            for try await output in session.outputs {
                switch output {
                case .requestProgress(let request, let fractionComplete):
                    requestProgress(request: request, fractionComplete: fractionComplete)
                  
                case .requestProgressInfo(_, let progressInfo):
                    estimatedRemainingTime = progressInfo.estimatedRemainingTime
                    logger.log("estimatedRemainingTime: \(String(describing: estimatedRemainingTime))")
                    
                case .requestError(_, let error):
                    logger.log("requestError received: \(error)")
                
                    appDataModel.state = isCancelling ? .ready : .error
                    appDataModel.alertMessage = isCancelling ? "" : "Reconstruction Failed"
                    
                case .requestComplete(let request, _):
                    logger.log("requestComplete received: \(String(describing: output))")
                    requestComplete(request: request)
                    
                case .processingComplete:
                    logger.log("processingComplete received")
                    
                    if appDataModel.state != .error {
                        processingComplete = true
                    }
                    
                default:
                    continue
                }
            }
        } catch {
            logger.error("Getting output failed with \(error)")
        }
    }
    
    // MARK: - helper functions
    func requestProgress(request: PhotogrammetrySession.Request, fractionComplete: Double) {
        progress = fractionComplete
        logger.log("fractionComplete: \(fractionComplete)")
        
        if case .modelFile(_, let detail, _) = request, currentRequestDetailLevel != detail {
            currentRequestDetailLevel = detail
        }
    }
    
    func requestComplete(request: PhotogrammetrySession.Request) {
        if case .modelFile(let url, let detail, _) = request {
            processedRequestsDetailLevel.append("\(detail)")
            if firstModelFileURL == nil {
                firstModelFileURL = url
            }
            numProcessedModels += 1

            // Update the app's state to show the model after completing the first request.
            appDataModel.state = .viewing
        }
    }
}
