/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Reads side-by-side video input and performs conversion to a multiview QuickTime video file.
*/

import Foundation
@preconcurrency import AVFoundation
import CoreMedia
import VideoToolbox

/// The left eye is video layer ID 0 (the hero eye) and the right eye is layer ID 1.
/// - Tag: VideoLayers
let MVHEVCVideoLayerIDs = [0, 1]

// For simplicity, choose view IDs that match the layer IDs.
let MVHEVCViewIDs = [0, 1]

// The first element in this array is the view ID of the left eye.
let MVHEVCLeftAndRightViewIDs = [0, 1]

/// Transcodes side-by-side HEVC to MV-HEVC.
final class SideBySideConverter: Sendable {
    let sideBySideFrameSize: CGSize
    let eyeFrameSize: CGSize
    
    let reader: AVAssetReader
    let sideBySideTrack: AVAssetReaderTrackOutput

    /// Loads a video to read for conversion.
    /// - Parameter url: A URL to a side-by-side HEVC file.
    /// - Tag: ReadInputVideo
    init(from url: URL) async throws {
        let asset = AVURLAsset(url: url)
        reader = try AVAssetReader(asset: asset)

        // Get the side-by-side video track.
        guard let videoTrack = try await asset.loadTracks(withMediaCharacteristic: .visual).first else {
            fatalError("Error loading side-by-side video input")
        }
        
        sideBySideFrameSize = try await videoTrack.load(.naturalSize)
        eyeFrameSize = CGSize(width: sideBySideFrameSize.width / 2, height: sideBySideFrameSize.height)

        let readerSettings: [String: Any] = [
            kCVPixelBufferIOSurfacePropertiesKey as String: [String: String]()
        ]
        sideBySideTrack = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerSettings)

        if reader.canAdd(sideBySideTrack) {
            reader.add(sideBySideTrack)
        }

        if !reader.startReading() {
            fatalError(reader.error?.localizedDescription ?? "Unknown error during track read start")
        }
    }
    
    /// Transcodes side-by-side HEVC media to MV-HEVC.
    /// - Parameter output: The output URL to write the MV-HEVC file to.
    /// - Parameter spatialMetadata: Optional spatial metadata to add to the output file.
    /// - Tag: TranscodeVideo
    func transcodeToMVHEVC(output videoOutputURL: URL, spatialMetadata: SpatialMetadata?) async {
        await withCheckedContinuation { continuation in
            Task {
                let multiviewWriter = try AVAssetWriter(outputURL: videoOutputURL, fileType: AVFileType.mov)

                var multiviewCompressionProperties: [CFString: Any] = [
                    kVTCompressionPropertyKey_MVHEVCVideoLayerIDs: MVHEVCVideoLayerIDs,
                    kVTCompressionPropertyKey_MVHEVCViewIDs: MVHEVCViewIDs,
                    kVTCompressionPropertyKey_MVHEVCLeftAndRightViewIDs: MVHEVCLeftAndRightViewIDs,
                    kVTCompressionPropertyKey_HasLeftStereoEyeView: true,
                    kVTCompressionPropertyKey_HasRightStereoEyeView: true
                ]

                if let spatialMetadata {

                    let baselineInMicrometers = UInt32(1000.0 * spatialMetadata.baselineInMillimeters)
                    let encodedHorizontalFOV = UInt32(1000.0 * spatialMetadata.horizontalFOV)
                    let encodedDisparityAdjustment = Int32(10_000.0 * spatialMetadata.disparityAdjustment)

                    multiviewCompressionProperties[kVTCompressionPropertyKey_ProjectionKind] = kCMFormatDescriptionProjectionKind_Rectilinear
                    multiviewCompressionProperties[kVTCompressionPropertyKey_StereoCameraBaseline] = baselineInMicrometers
                    multiviewCompressionProperties[kVTCompressionPropertyKey_HorizontalFieldOfView] = encodedHorizontalFOV
                    multiviewCompressionProperties[kVTCompressionPropertyKey_HorizontalDisparityAdjustment] = encodedDisparityAdjustment

                }

                let multiviewSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.hevc,
                    AVVideoWidthKey: self.eyeFrameSize.width,
                    AVVideoHeightKey: self.eyeFrameSize.height,
                    AVVideoCompressionPropertiesKey: multiviewCompressionProperties
                ]
        
                guard multiviewWriter.canApply(outputSettings: multiviewSettings, forMediaType: AVMediaType.video) else {
                    fatalError("Error applying output settings")
                }

                let frameInput = AVAssetWriterInput(mediaType: .video, outputSettings: multiviewSettings)

                let sourcePixelAttributes: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                    kCVPixelBufferWidthKey as String: self.sideBySideFrameSize.width,
                    kCVPixelBufferHeightKey as String: self.sideBySideFrameSize.height
                ]

                let bufferInputAdapter = AVAssetWriterInputTaggedPixelBufferGroupAdaptor(assetWriterInput: frameInput, sourcePixelBufferAttributes: sourcePixelAttributes)

                guard multiviewWriter.canAdd(frameInput) else {
                    fatalError("Error adding side-by-side video frames as input")
                }
                multiviewWriter.add(frameInput)

                guard multiviewWriter.startWriting() else {
                    fatalError("Failed to start writing multiview output file")
                }
                multiviewWriter.startSession(atSourceTime: CMTime.zero)

                // The dispatch queue executes the closure when media reads from the input file are available.
                frameInput.requestMediaDataWhenReady(on: DispatchQueue(label: "Multiview HEVC Writer")) {
                    var session: VTPixelTransferSession? = nil
                    guard VTPixelTransferSessionCreate(allocator: kCFAllocatorDefault, pixelTransferSessionOut: &session) == noErr, let session else {
                        fatalError("Failed to create pixel transfer")
                    }
                    guard let pixelBufferPool = bufferInputAdapter.pixelBufferPool else {
                        fatalError("Failed to retrieve existing pixel buffer pool")
                    }
                   
                    // Handling all available frames within the closure improves performance.
                    while frameInput.isReadyForMoreMediaData && bufferInputAdapter.assetWriterInput.isReadyForMoreMediaData {
                        if let sampleBuffer = self.sideBySideTrack.copyNextSampleBuffer() {
                            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                                fatalError("Failed to load source samples as an image buffer")
                            }
                            let taggedBuffers = self.convertFrame(fromSideBySide: imageBuffer, with: pixelBufferPool, in: session)
                            let newPTS = sampleBuffer.outputPresentationTimeStamp
                            if !bufferInputAdapter.appendTaggedBuffers(taggedBuffers, withPresentationTime: newPTS) {
                                fatalError("Failed to append tagged buffers to multiview output")
                            }
                        } else {
                            frameInput.markAsFinished()
                            multiviewWriter.finishWriting {
                                continuation.resume()
                            }

                            break
                        }
                    }
                }
            }
        }
    }
    
    /// Splits a side-by-side sample buffer into two tagged buffers for left and right eyes.
    /// - Parameters:
    ///   - fromSideBySide: The side-by-side sample buffer to extract individual eye buffers from.
    ///   - with: The pixel buffer pool used to create temporary buffers for pixel copies.
    ///   - in: The transfer session to perform the pixel transfer.
    /// - Returns: Group of tagged buffers for the left and right eyes.
    /// - Tag: ConvertFrame
    func convertFrame(fromSideBySide imageBuffer: CVImageBuffer, with pixelBufferPool: CVPixelBufferPool, in session: VTPixelTransferSession) -> [CMTaggedBuffer] {
        // Output contains two tagged buffers, with the left eye frame first.
        var taggedBuffers: [CMTaggedBuffer] = []
        let eyes: [CMStereoViewComponents] = [.leftEye, .rightEye]

        for (layerID, eye) in zip(MVHEVCVideoLayerIDs, eyes) {
            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
            guard let pixelBuffer else {
                fatalError("Failed to create pixel buffer for layer \(layerID)")
            }

            // Crop the transfer region to the current eye.
            let apertureOffset = -(self.eyeFrameSize.width / 2) + CGFloat(layerID) * self.eyeFrameSize.width
            let cropRectDict = [
                kCVImageBufferCleanApertureHorizontalOffsetKey: apertureOffset,
                kCVImageBufferCleanApertureVerticalOffsetKey: 0,
                kCVImageBufferCleanApertureWidthKey: self.eyeFrameSize.width,
                kCVImageBufferCleanApertureHeightKey: self.eyeFrameSize.height
            ]
            CVBufferSetAttachment(imageBuffer, kCVImageBufferCleanApertureKey, cropRectDict as CFDictionary, CVAttachmentMode.shouldPropagate)
            VTSessionSetProperty(session, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_CropSourceToCleanAperture)

            // Transfer the image to the pixel buffer.
            guard VTPixelTransferSessionTransferImage(session, from: imageBuffer, to: pixelBuffer) == noErr else {
                fatalError("Error during pixel transfer session for layer \(layerID)")
            }

            // Create and append a tagged buffer for this eye.
            let tags: [CMTag] = [.videoLayerID(Int64(layerID)), .stereoView(eye)]
            let buffer = CMTaggedBuffer(tags: tags, buffer: .pixelBuffer(pixelBuffer))
            taggedBuffers.append(buffer)
        }
        
        return taggedBuffers
    }
}
