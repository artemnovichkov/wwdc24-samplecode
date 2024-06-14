/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Processes command-line arguments and calls the converter from side-by-side to multiview video.
*/

import Foundation
import ArgumentParser // Available from Apple: https://github.com/apple/swift-argument-parser

@main
struct SideBySideToMVHEVC: AsyncParsableCommand {

    @Argument(help: "The side-by-side video file to convert.")
    var sideBySideVideoPath: String

    @Flag(
        name: [.customShort("s"), .customLong("spatial")],
        help: "Write spatial video metadata to the output video."
    )
    var writeSpatialMetadata: Bool = false

    // Additional input values required for writing spatial metadata.

    @Option(
        name: [.customShort("b"), .customLong("baseline")],
        help: "The baseline (distance between the centers of the two cameras), in millimeters."
    )
    var baselineInMillimeters: Double? = nil

    @Option(
        name: [.customShort("f"), .customLong("fov")],
        help: "The horizontal field of view of each camera, in degrees."
    )
    var horizontalFOV: Double? = nil

    @Option(
        name: [.customShort("d"), .customLong("disparityAdjustment")],
        help: "A horizontal presentation adjustment to apply as a fraction of the image width (-1...1)."
    )
    var disparityAdjustment: Double? = nil

    mutating func run() async throws {

        let spatialMetadata: SpatialMetadata?
        let outputVideoType: String

        if writeSpatialMetadata {
            // Validate that the app received all the required spatial metadata.
            guard let baselineInMillimeters, let horizontalFOV, let disparityAdjustment else {
                throw ConversionError("Missing spatial metadata.")
            }
            spatialMetadata = SpatialMetadata(
                baselineInMillimeters: baselineInMillimeters,
                horizontalFOV: horizontalFOV,
                disparityAdjustment: disparityAdjustment
            )
            outputVideoType = "Spatial"
        } else {
            // Spatial output wasn't requested.
            spatialMetadata = nil
            outputVideoType = "MV-HEVC"
        }

        // Determine an appropriate output file URL.
        let inputURL = URL(fileURLWithPath: sideBySideVideoPath)
        let converter = try await SideBySideConverter(from: inputURL)
        let outputFileName = inputURL.deletingPathExtension().lastPathComponent + "_\(outputVideoType).mov"
        let outputURL = inputURL.deletingLastPathComponent().appendingPathComponent(outputFileName)

        // Delete a previous output file with the same name if one exists.
        if FileManager.default.fileExists(atPath: outputURL.path()) {
            try FileManager.default.removeItem(at: outputURL)
        }

        // Perform the video conversion.
        await converter.transcodeToMVHEVC(output: outputURL, spatialMetadata: spatialMetadata)
        print("\(outputVideoType) video written to \(outputURL).")

    }

}

struct SpatialMetadata {
    var baselineInMillimeters: Double
    var horizontalFOV: Double
    var disparityAdjustment: Double
}

struct ConversionError: Error, CustomStringConvertible {
    var description: String
    init(_ description: String) {
        self.description = description
    }
}
