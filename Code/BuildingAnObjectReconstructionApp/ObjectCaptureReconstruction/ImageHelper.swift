/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Helper class for getting image's metadata.
*/

import Foundation
import RealityKit
import Synchronization

import os

private let logger = Logger(subsystem: ObjectCaptureReconstructionApp.subsystem,
                            category: "ImageHelper")

class ImageHelper {
    static let validImageSuffixes: Set<String> = [ "heic", "jpg", "jpeg", "png"]

    // Returns a list of URLs for all images in the given folder.
    // Filter the URLs to only include images that can be loaded by PhotogrammetrySession.
    static func getListOfURLs(from folder: URL?) -> [URL] {
        guard let folder = folder else { return [] }
        do {
            return try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [ .creationDateKey ])
                .filter { isLoadableImageFile($0) }
        } catch let error {
            logger.warning("contentsOfDirectory error: \(error)")
            return []
        }
    }

    struct MetadataAvailability {
        var depth = false
        var gravity = false
        var boundingBox = false
    }

    // Returns the aggregated metadata availability for the list of image URLs.
    static func getMetadataAvailability(for urls: [URL]) async -> MetadataAvailability {
        guard !urls.isEmpty else { return MetadataAvailability() }

        // Create a subtask for each URL to read its metadata.
        return await withTaskGroup(of: MetadataAvailability?.self, returning: MetadataAvailability.self) { group in
            let currentURLIndex = Atomic<Int>(0)
            var metadataAvailability = MetadataAvailability()

            // Avoid creating many tasks by adding a limit on the number of concurrent tasks.
            let maxNumOfConcurrentTasks = min(5, urls.count)
            for _ in 0..<maxNumOfConcurrentTasks {
                let url = urls[currentURLIndex.load(ordering: .relaxed)]
                currentURLIndex.add(1, ordering: .relaxed)
                group.addTask { return await Self.getMetadataAvailability(from: url) }
            }

            // The minimum number of images with gravity and depth required to get a model with an accurate orientation and scale.
            let minNumImagesWithDepth = 3, minNumImagesWithGravity = 3
            var numImagesWithDepthAvailable = 0, numImagesWithGravityAvailable = 0
            while let nextMetadataAvailability = await group.next() {
                if let nextMetadataAvailability {
                    if !metadataAvailability.depth && nextMetadataAvailability.depth {
                        numImagesWithDepthAvailable += 1
                        if numImagesWithDepthAvailable == minNumImagesWithDepth {
                            logger.log("Depth is available...")
                            metadataAvailability.depth = true
                        }
                    }

                    if !metadataAvailability.gravity && nextMetadataAvailability.gravity {
                        numImagesWithGravityAvailable += 1
                        if numImagesWithGravityAvailable == minNumImagesWithGravity {
                            logger.log("Gravity is available...")
                            metadataAvailability.gravity = true
                        }
                    }

                    if !metadataAvailability.boundingBox && nextMetadataAvailability.boundingBox {
                        logger.log("iOS bounding box is available...")
                        metadataAvailability.boundingBox = true
                    }
                }

                // Stop adding new tasks if the task has been canceled or the metadata is available.
                // Otherwise, read the metadata from the next URL in a new task.
                let index = currentURLIndex.load(ordering: .relaxed)
                if !Task.isCancelled && !Self.allFieldsAvailable(in: metadataAvailability) && index < urls.count {
                    group.addTask {
                        let metadataAvailability = await Self.getMetadataAvailability(from: urls[index])
                        currentURLIndex.add(1, ordering: .relaxed)
                        return metadataAvailability
                    }
                }
            }
            return metadataAvailability
        }
    }

    static private func getMetadataAvailability(from url: URL) async -> MetadataAvailability? {
        guard let sample = try? await PhotogrammetrySample(contentsOf: url) else { return nil }
        
        var metadataAvailability = MetadataAvailability()
        
        if sample.depthDataMap != nil { metadataAvailability.depth = true }
        
        if sample.gravity != nil { metadataAvailability.gravity = true }
        
        if sample.boundingBox != nil { metadataAvailability.boundingBox = true }
        
        return metadataAvailability
    }

    static private func allFieldsAvailable(in metadata: MetadataAvailability) -> Bool {
        return metadata.depth && metadata.gravity && metadata.boundingBox
    }

    static private func isLoadableImageFile(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        let suffix = url.pathExtension.lowercased()
        return ImageHelper.validImageSuffixes.contains(suffix)
    }
}
