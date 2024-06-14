/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry point to the command-line application.
*/

import ArgumentParser // Available from Apple: https://github.com/apple/swift-argument-parser
import Foundation

@main
struct WritingSpatialPhotos: ParsableCommand {

    @Option(
        name: [.customShort("l"), .customLong("leftImage")],
        help: "A path to a left eye image."
    )
    var leftImagePath: String

    @Option(
        name: [.customShort("r"), .customLong("rightImage")],
        help: "A path to a right eye image."
    )
    var rightImagePath: String

    @Option(
        name: [.customShort("o"), .customLong("outputImage")],
        help: "A path at which to write the output spatial HEIC image."
    )
    var outputImagePath: String

    @Option(
        name: [.customShort("b"), .customLong("baseline")],
        help: "The baseline (distance between the centers of the two cameras), in millimeters."
    )
    var baselineInMillimeters: Double

    @Option(
        name: [.customShort("f"), .customLong("fov")],
        help: "The horizontal field of view of each camera, in degrees."
    )
    var horizontalFOV: Double

    @Option(
        name: [.customShort("d"), .customLong("disparityAdjustment")],
        help: "A horizontal presentation adjustment to apply as a fraction of the image width (-1...1)."
    )
    var disparityAdjustment: Double

    mutating func run() throws {

        let leftImageURL = URL(fileURLWithPath: leftImagePath)
        let rightImageURL = URL(fileURLWithPath: rightImagePath)
        let outputImageURL = URL(fileURLWithPath: outputImagePath)

        let converter = SpatialPhotoConverter(
            leftImageURL: leftImageURL,
            rightImageURL: rightImageURL,
            outputImageURL: outputImageURL,
            baselineInMillimeters: baselineInMillimeters,
            horizontalFOV: horizontalFOV,
            disparityAdjustment: disparityAdjustment
        )

        // Delete a previous output file with the same name if one exists.
        if FileManager.default.fileExists(atPath: outputImageURL.path()) {
            try FileManager.default.removeItem(at: outputImageURL)
        }

        try converter.convert()
        print("Spatial photo written to \(outputImageURL).")

    }

}
