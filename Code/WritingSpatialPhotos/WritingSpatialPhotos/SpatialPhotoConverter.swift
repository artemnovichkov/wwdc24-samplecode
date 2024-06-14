/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Converts a left- and right-eye image, plus spatial metadata, into a spatial photo.
*/

import ImageIO
import UniformTypeIdentifiers

/// Converts a left- and right-eye image, plus spatial metadata, into a spatial photo.
/// - Tag: SpatialPhotoConverter
final class SpatialPhotoConverter {

    let leftImageURL: URL
    let rightImageURL: URL
    let outputImageURL: URL
    let baselineInMillimeters: Double
    let horizontalFOV: Double
    let disparityAdjustment: Double

    init(
        leftImageURL: URL,
        rightImageURL: URL,
        outputImageURL: URL,
        baselineInMillimeters: Double,
        horizontalFOV: Double,
        disparityAdjustment: Double
    ) {
        self.leftImageURL = leftImageURL
        self.rightImageURL = rightImageURL
        self.outputImageURL = outputImageURL
        self.baselineInMillimeters = baselineInMillimeters
        self.horizontalFOV = horizontalFOV
        self.disparityAdjustment = disparityAdjustment
    }

    /// A 3x3 identity rotation matrix.
    static let identityRotation: [Double] = [
        1, 0, 0,
        0, 1, 0,
        0, 0, 1
    ]

    /// An image from a `CGImageSource` for the left or right image in a stereo pair,
    /// together with the index of the primary image in the image source,
    /// and the width and height of that primary image.
    /// - Tag: StereoPairImage
    struct StereoPairImage {

        let source: CGImageSource
        let primaryImageIndex: Int
        let width: Int
        let height: Int

        init(url: URL) throws {

            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                throw ConversionError.couldNotOpenURLAsImageSource
            }
            self.source = source

            primaryImageIndex = CGImageSourceGetPrimaryImageIndex(source)

            guard let properties = CGImageSourceCopyPropertiesAtIndex(source, primaryImageIndex, nil) as? [CFString: Any] else {
                throw ConversionError.couldNotCopyImageProperties
            }
            guard let width = properties[kCGImagePropertyPixelWidth] as? Int,
                let height = properties[kCGImagePropertyPixelHeight] as? Int else {
                throw ConversionError.unableToReadImageSize
            }
            self.width = width
            self.height = height

        }

        /// Returns a 3x3 intrinsics matrix (with values expressed in pixels)
        /// for a simplified pinhole camera model with a spherical lens.
        /// The lens is assumed to have the provided horizontal field of view in degrees,
        /// with the camera's principal point at the image center, and no shear.
        /// - Tag: StereoPairImageIntrinsics
        func intrinsics(horizontalFOV: Double) -> [Double] {
            let width = Double(width)
            let height = Double(height)
            let horizontalFOVInRadians = horizontalFOV / 180.0 * .pi
            let focalLengthX = (width * 0.5) / (tan(horizontalFOVInRadians * 0.5))
            // For a spherical pinhole camera, the focal length is the same in both X and Y.
            let focalLengthY = focalLengthX
            // The app assumes the principal point of the camera is located at the center of the image.
            let principalPointX = 0.5 * width
            let principalPointY = 0.5 * height
            return [
                focalLengthX, 0, principalPointX,
                0, focalLengthY, principalPointY,
                0, 0, 1
            ]
        }

    }

    /// Returns a properties dictionary that describes the spatial metadata for
    /// a left or right image in a stereo pair group.
    /// - Tag: PropertiesDictionary
    func propertiesDictionary(
        isLeft: Bool,
        encodedDisparityAdjustment: Int,
        position: [Double],
        intrinsics: [Double]
    ) -> [CFString: Any] {
        return [
            kCGImagePropertyGroups: [
                kCGImagePropertyGroupIndex: 0,
                kCGImagePropertyGroupType: kCGImagePropertyGroupTypeStereoPair,
                (isLeft ? kCGImagePropertyGroupImageIsLeftImage : kCGImagePropertyGroupImageIsRightImage): true,
                kCGImagePropertyGroupImageDisparityAdjustment: encodedDisparityAdjustment
            ],
            kCGImagePropertyHEIFDictionary: [
                kIIOMetadata_CameraExtrinsicsKey: [
                    kIIOCameraExtrinsics_Position: position,
                    kIIOCameraExtrinsics_Rotation: Self.identityRotation
                ],
                kIIOMetadata_CameraModelKey: [
                    kIIOCameraModel_Intrinsics: intrinsics,
                    kIIOCameraModel_ModelType: kIIOCameraModelType_SimplifiedPinhole
                ]
            ],
            kCGImagePropertyHasAlpha: false
        ]
    }

    /// Performs the task of converting two input images, plus spatial metadata, into an output spatial photo.
    /// - Tag: Convert
    func convert() throws {

        // Open both images.
        let leftImage = try StereoPairImage(url: leftImageURL)
        let rightImage = try StereoPairImage(url: rightImageURL)

        // Validate that both images are the same size.
        guard leftImage.width == rightImage.width, leftImage.height == rightImage.height else {
            throw ConversionError.leftAndRightImageSizesDoNotMatch
        }

        // Convert the baseline from millimeters to meters.
        let baselineInMeters = baselineInMillimeters / 1000.0

        // Define a pair of extrinsic positions that describe how the two cameras are positioned relative to each other in 3D space.
        //
        // Place the left camera at the origin,
        // with the right camera translated in positive x by the baseline in meters.
        let leftPosition: [Double] = [0, 0, 0]
        let rightPosition: [Double] = [baselineInMeters, 0, 0]

        // Calculate an intrinsics matrix for both cameras.
        // The code above already validated that the left and right images have the same size,
        // so the intrinsics from the left image are used for both images in the code below.
        let intrinsics = leftImage.intrinsics(horizontalFOV: horizontalFOV)

        // Encode the provided floating-point disparity adjustment
        // into the integer form expected by the spatial photo format.
        let encodedDisparityAdjustment = Int(disparityAdjustment * 1e4)

        // Create property dictionaries.
        let leftProperties = propertiesDictionary(
            isLeft: true,
            encodedDisparityAdjustment: encodedDisparityAdjustment,
            position: leftPosition,
            intrinsics: intrinsics
        )
        let rightProperties = propertiesDictionary(
            isLeft: false,
            encodedDisparityAdjustment: encodedDisparityAdjustment,
            position: rightPosition,
            intrinsics: intrinsics
        )

        // Create a HEIC image destination at the provided output URL.
        let destinationProperties: [CFString: Any] = [kCGImagePropertyPrimaryImage: 0]
        guard let destination = CGImageDestinationCreateWithURL(
            outputImageURL as CFURL,
            UTType.heic.description as CFString,
            2,
            destinationProperties as CFDictionary
        ) else {
            throw ConversionError.unableToCreateImageDestination
        }

        // Add the left and right images to the destination with appropriate properties.
        CGImageDestinationAddImageFromSource(
            destination,
            leftImage.source,
            leftImage.primaryImageIndex,
            leftProperties as CFDictionary
        )
        CGImageDestinationAddImageFromSource(
            destination,
            rightImage.source,
            rightImage.primaryImageIndex,
            rightProperties as CFDictionary
        )

        // Finalize the image destination to write the spatial photo to disk.
        guard CGImageDestinationFinalize(destination) else {
            throw ConversionError.unableToFinalizeImageDestination
        }

    }

    /// Errors that can occur during the creation of a spatial photo.
    enum ConversionError: LocalizedError {

        case couldNotOpenURLAsImageSource
        case couldNotCopyImageProperties
        case unableToReadImageSize
        case leftAndRightImageSizesDoNotMatch
        case unableToCreateImageDestination
        case unableToFinalizeImageDestination

        var errorDescription: String? {
            switch self {
            case .couldNotOpenURLAsImageSource:
                return "Could not open image URL as an image source."
            case .couldNotCopyImageProperties:
                return "Could not copy image properties."
            case .unableToReadImageSize:
                return "Unable to read image size."
            case .leftAndRightImageSizesDoNotMatch:
                return "Left and right image sizes do not match."
            case .unableToCreateImageDestination:
                return "Unable to create image destination."
            case .unableToFinalizeImageDestination:
                return "Unable to finalize image destination."
            }
        }

    }

}
