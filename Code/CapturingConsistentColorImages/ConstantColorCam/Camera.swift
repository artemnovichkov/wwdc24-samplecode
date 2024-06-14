/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that manages the app's camera capture features.
*/

import CoreImage
import os.log
import Photos
import SwiftUI
import UIKit
import VideoToolbox

class Camera: NSObject, ObservableObject {
    
    // The applications capture session.
    private let captureSession = AVCaptureSession()
    
    // A Boolean value that indicates whether the session finished its required configuration.
    private var isCaptureSessionConfigured = false
    
    // The video input for the currently selected device camera.
    private var deviceInput: AVCaptureDeviceInput?
    
    // The capture photo output type for this session.
    private var photoOutput: AVCapturePhotoOutput?
    
    // The video data output for this session.
    private var videoOutput: AVCaptureVideoDataOutput?
    
    // Communicate with the session and other session objects on this queue.
    private var sessionQueue: DispatchQueue!
    
    // A Boolean value that indicates whether constant color is enabled in the photo settings.
    var constantColorEnabled = true
    
    // A Boolean value that indicates whether fallback photo delivery is enabled in the photo settings.
    var fallBackPhotoDeliveryEnabled = true
    
    // A Boolean value that indicates whether flash is enabled in the photo settings.
    var flashEnabled = true
    
    // A Boolean value that tracks whether constant color is supported on the photo output.
    var constantColorSupported = false
    
    // The variable to assign the constant color photo object.
    var constantColorPhoto: UIImage?
    
    // The variable to assign the fallback photo object.
    var fallbackFrame: UIImage?
    
    // The variable to assign the confidence map object.
    var confidenceMap: UIImage?
    
    // The variable to assign the confidence level from the float value.
    var confidenceLevel: Float?
    
    // The normal photo object.
    var normalPhoto: UIImage?
    
    // A Boolean value that indicates whether to show the photos view.
    var photosViewVisible = false
    
    // The photo output readiness coordinator.
    var photoOutputReadinessCoordinator: AVCapturePhotoOutputReadinessCoordinator!
    
    // A Boolean value that indicates whether the output is ready to capture.
    var shutterButtonAvailable = true
    
    // The discovery sessions to find the front and back cameras.
    private var allCaptureDevices: [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualWideCamera], mediaType: .video, position: .back).devices
    }
    
    // All front capture devices.
    private var frontCaptureDevices: [AVCaptureDevice] {
        allCaptureDevices
            .filter { $0.position == .front }
    }
    
    // All back capture devices.
    private var backCaptureDevices: [AVCaptureDevice] {
        allCaptureDevices
            .filter { $0.position == .back }
    }
    
    // Populate the capture devices array.
    private var captureDevices: [AVCaptureDevice] {
        var devices = [AVCaptureDevice]()
        #if os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
        devices += allCaptureDevices
        #else
        if let backDevice = backCaptureDevices.first {
            devices += [backDevice]
        }
        if let frontDevice = frontCaptureDevices.first {
            devices += [frontDevice]
        }
        #endif
        return devices
    }
    
    // All available capture devices.
    private var availableCaptureDevices: [AVCaptureDevice] {
        captureDevices
            .filter({ $0.isConnected })
            .filter({ !$0.isSuspended })
    }
    
    // A variable for the AVCaptureDevice for the capture session.
    private var captureDevice: AVCaptureDevice? {
        didSet {
            guard let captureDevice else { return }
            logger.debug("Using capture device: \(captureDevice.localizedName)")
            sessionQueue.async {
                self.updateSessionForCaptureDevice(captureDevice)
            }
        }
    }
    
    // A Boolean value that indicates whether the capture session is running.
    var isRunning: Bool {
        captureSession.isRunning
    }
    
    // A Boolean value that indicates whether the capture device is in the front position.
    var isUsingFrontCaptureDevice: Bool {
        guard let captureDevice else { return false }
        return frontCaptureDevices.contains(captureDevice)
    }
    
    // A Boolean value that indicates whether the capture device is in the back position.
    var isUsingBackCaptureDevice: Bool {
        guard let captureDevice else { return false }
        return backCaptureDevices.contains(captureDevice)
    }
    
    // A Boolean value that indicates whether the preview is paused.
    var isPreviewPaused = false
    
    // An async stream of images.
    let previewStream: AsyncStream<CIImage>
    private let previewContinuation: AsyncStream<CIImage>.Continuation
    
    // An async stream of photo objects.
    let photoStream: AsyncStream<AVCapturePhoto>
    private let photoContinuation: AsyncStream<AVCapturePhoto>.Continuation
    
    override init() {
        let (previewStream, previewContinuation) = AsyncStream.makeStream(of: CIImage.self)
        self.previewStream = previewStream
        self.previewContinuation = previewContinuation
        
        let (photoStream, photoContinuation) = AsyncStream.makeStream(of: AVCapturePhoto.self)
        self.photoStream = photoStream
        self.photoContinuation = photoContinuation
        
        super.init()
        
        initialize()
    }
    
    private func initialize() {
        // Initialize the sessionQueue, captureDevice, and system pressure state for the capture session.
        sessionQueue = DispatchQueue(label: "session queue")
        captureDevice = availableCaptureDevices.first ?? AVCaptureDevice.default(for: .video)
    }
    
    private func configureCaptureSession(completionHandler: (_ success: Bool) -> Void) {
        // A Boolean value that indicates whether the capture session configuration was successful.
        var success = false
        
        // Begin the session configuration for the capture session.
        captureSession.beginConfiguration()
        
        defer {
            self.captureSession.commitConfiguration()
            completionHandler(success)
        }
        
        guard
            let captureDevice = captureDevice,
            // Create the device input for the capture session.
            let deviceInput = try? AVCaptureDeviceInput(device: captureDevice)
        else {
            logger.error("Failed to obtain video input.")
            return
        }
        
        // Initialize the photo output for the capture session.
        let photoOutput = AVCapturePhotoOutput()
        
        // Set the preset to .photo on the capture session.
        captureSession.sessionPreset = .photo

        // Initialize the video data output for the capture session.
        let videoOutput = AVCaptureVideoDataOutput()
        
        // Set the sample buffer delegate for the video output.
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoDataOutputQueue"))

        // Guards to validate adding device input, photo output, and video output on the capture session.
        guard captureSession.canAddInput(deviceInput) else {
            logger.error("Unable to add device input to capture session.")
            return
        }
        guard captureSession.canAddOutput(photoOutput) else {
            logger.error("Unable to add photo output to capture session.")
            return
        }
        guard captureSession.canAddOutput(videoOutput) else {
            logger.error("Unable to add video output to capture session.")
            return
        }
        
        // Add device input, photo output, and video output to the capture session.
        captureSession.addInput(deviceInput)
        captureSession.addOutput(photoOutput)
        captureSession.addOutput(videoOutput)
        
        let readinessCoordinator = AVCapturePhotoOutputReadinessCoordinator(photoOutput: photoOutput)
        self.photoOutputReadinessCoordinator = readinessCoordinator
        readinessCoordinator.delegate = self
        
        videoOutput.connection(with: .video)?.videoRotationAngle = 90
        
        // Initialize the device input, photo output, and video output properties for the capture session.
        self.deviceInput = deviceInput
        self.photoOutput = photoOutput
        self.videoOutput = videoOutput
        
        // Set the max photo dimensions on the photo output.
        photoOutput.maxPhotoDimensions = deviceInput.device.activeFormat.supportedMaxPhotoDimensions.last!
        
        // Set the quality prioritization on the photo output.
        photoOutput.maxPhotoQualityPrioritization = .quality
        
        // Enable constant color on the photo output.
        photoOutput.isConstantColorEnabled = photoOutput.isConstantColorSupported
        constantColorSupported = photoOutput.isConstantColorSupported
        
        // Update the video output connection with the capture device.
        updateVideoOutputConnection()
        
        // The session has been configured successfully.
        isCaptureSessionConfigured = true
        success = true
    }
    
    // A function to check the status for authorization on the capture device.
    func checkCameraAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            logger.debug("Camera access authorized.")
            return true
        case .notDetermined:
            logger.debug("Camera access not determined.")
            sessionQueue.suspend()
            let status = await AVCaptureDevice.requestAccess(for: .video)
            sessionQueue.resume()
            return status
        case .denied:
            logger.debug("Camera access denied.")
            return false
        case .restricted:
            logger.debug("Camera library access restricted.")
            return false
        @unknown default:
            return false
        }
    }
    
    private func checkPhotoAuthorization() async {
        switch await PHPhotoLibrary.requestAuthorization(for: .addOnly) {
        case .authorized:
            logger.debug("Photo access authorized.")
        case .notDetermined:
            logger.debug("Photo access not determined.")
        case .denied:
            logger.debug("Photo access denied.")
        case .restricted:
            logger.debug("Photo access restricted.")
        case .limited:
            logger.debug("Photo access limited.")
        @unknown default:
            logger.debug("Unknown default.")
        }
    }
    
    private func deviceInputFor(device: AVCaptureDevice?) -> AVCaptureDeviceInput? {
        guard let validDevice = device else { return nil }
        do {
            return try AVCaptureDeviceInput(device: validDevice)
        } catch let error {
            logger.error("Error getting capture device input: \(error.localizedDescription)")
            return nil
        }
    }
    
    // A utility function to create a UIImage from a CVPixelBuffer.
    private func createImageFromPixelBuffer(pixelBuffer: CVPixelBuffer) -> UIImage? {
        var cgImage: CGImage?
        
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        guard let cgImage else {
            return nil
        }
        
        return UIImage(cgImage: cgImage).rotate(radians: .pi / 2.0)
    }
    
    // A utility function to convert an AVCapturePhoto to a UIImage.
    private func photoToUIImage(photo: AVCapturePhoto!) -> UIImage! {
        let imageData = photo?.fileDataRepresentation()
        return imageData.flatMap { UIImage(data: $0) }
    }
    
    // A function to update the session for a capture device.
    private func updateSessionForCaptureDevice(_ captureDevice: AVCaptureDevice) {
        guard isCaptureSessionConfigured else { return }
        
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        for input in captureSession.inputs {
            if let deviceInput = input as? AVCaptureDeviceInput {
                captureSession.removeInput(deviceInput)
            }
        }
        
        if let deviceInput = deviceInputFor(device: captureDevice) {
            if !captureSession.inputs.contains(deviceInput), captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }
        }
        
        updateVideoOutputConnection()
    }
    
    // A function to update the video output connection.
    private func updateVideoOutputConnection() {
        if let videoOutput = videoOutput, let videoOutputConnection = videoOutput.connection(with: .video), videoOutputConnection.isVideoMirroringSupported {
            videoOutputConnection.isVideoMirrored = isUsingFrontCaptureDevice
        }
    }
    
    // A function to start running the capture session.
    func start() async {
        let cameraAuthorized = await checkCameraAuthorization()
        guard cameraAuthorized else {
            logger.error("Camera access was not authorized.")
            return
        }
        
        await checkPhotoAuthorization()
        
        if isCaptureSessionConfigured {
            if !captureSession.isRunning {
                sessionQueue.async { [self] in
                    self.captureSession.startRunning()
                }
            }
            return
        }
        
        sessionQueue.async {
            self.configureCaptureSession { success in
                guard success else { return }
                self.captureSession.startRunning()
            }
        }
    }
    
    // A function to stop running the capture session.
    func stop() {
        guard isCaptureSessionConfigured else { return }
        
        if captureSession.isRunning {
            sessionQueue.async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    // A function to switch the capture device.
    func switchCaptureDevice() {
        if let captureDevice = captureDevice, let index = availableCaptureDevices.firstIndex(of: captureDevice) {
            let nextIndex = (index + 1) % availableCaptureDevices.count
            self.captureDevice = availableCaptureDevices[nextIndex]
        } else {
            self.captureDevice = AVCaptureDevice.default(for: .video)
        }
    }
    
    // A function to capture a photo on the photo output.
    func takePhoto() {
        guard let photoOutput else { return }
        
        constantColorPhoto = nil
        fallbackFrame = nil
        confidenceMap = nil
        normalPhoto = nil
        
        // Create an AVCapturePhotoSettings to configure the photo capture.
        let photoSettings = AVCapturePhotoSettings()
        
        // Start tracking capture readiness on the main thread to synchronously update the shutter
        // button's availability and appearance to include this request.
        photoOutputReadinessCoordinator.startTrackingCaptureRequest(using: photoSettings)
        
        sessionQueue.async {
            
            // Set the flash mode.
            photoSettings.flashMode = self.flashEnabled ? .on : .off
            
           if self.constantColorSupported {
                // Enable the constant color in the photo settings.
                photoSettings.isConstantColorEnabled = self.constantColorEnabled
                
                // Enabled fallback photo delivery in the photo settings.
                photoSettings.isConstantColorFallbackPhotoDeliveryEnabled = self.fallBackPhotoDeliveryEnabled
           }
            
            // Set the max photo dimensions in the photo settings.
            photoSettings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
            
            // Set the preview photo format in the photo settings.
            if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
            }
            
            // Set the photo quality prioritization in the photo settings.
            photoSettings.photoQualityPrioritization = .balanced
            
            photoOutput.connection(with: .video)?.videoRotationAngle = 90
            self.videoOutput?.connection(with: .video)?.videoRotationAngle = 90
            
            // Capture the photo on the photo output.
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
            
            // Stop tracking the capture request which has now been handed off to the photo output.
            self.photoOutputReadinessCoordinator.stopTrackingCaptureRequest(using: photoSettings.uniqueID)
        }
    }
    
    func save(photo: AVCapturePhoto) async {
        // Create a data representation of the photo and its attachments.
        if let photoData = photo.fileDataRepresentation() {
            PHPhotoLibrary.shared().performChanges {
                // Save the photo data.
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: photoData, options: nil)
            } completionHandler: { success, error in
                if let error {
                    logger.debug("Error saving photo: \(error.localizedDescription)")
                    return
                }
            }
        }
    }
}

extension Camera: AVCapturePhotoOutputReadinessCoordinatorDelegate {
    func readinessCoordinator(_ coordinator: AVCapturePhotoOutputReadinessCoordinator, captureReadinessDidChange captureReadiness: AVCapturePhotoOutput.CaptureReadiness) {
            // The shutter button's appearance can be customized based on the captureReadiness value.
            // Enable user interaction for the shutter button only when the output is ready to capture.
            shutterButtonAvailable = (captureReadiness == .ready)
        }
}

extension Camera: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error {
            logger.error("Error capturing photo: \(error.localizedDescription)")
            return
        }
        
        // Assign the fallback frame photo.
        if photo.isConstantColorFallbackPhoto && fallBackPhotoDeliveryEnabled {
            fallbackFrame = photoToUIImage(photo: photo)
        } else if constantColorEnabled {
            // Assign the constant color photo, confidence level, and the confidence map.
            constantColorPhoto = photoToUIImage(photo: photo)
            if let photoConfidenceMap = photo.constantColorConfidenceMap {
                confidenceMap = createImageFromPixelBuffer(pixelBuffer: photoConfidenceMap)
            } else {
                confidenceMap = nil
            }
            confidenceLevel = photo.constantColorCenterWeightedMeanConfidenceLevel
        } else {
            // Assign the normal photo.
            normalPhoto = photoToUIImage(photo: photo)
        }
        
        // Show the photos view if all photos are done processing.
        if confidenceMap != nil || !constantColorEnabled {
          photosViewVisible = true
        }
        
        photoContinuation.yield(photo)
        
        Task {
            await save(photo: photo)
        }
    }
}

extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        
        if !isPreviewPaused {
            previewContinuation.yield(CIImage(cvPixelBuffer: pixelBuffer))
        }
    }
}

private let logger = Logger(subsystem: "com.example.apple-samplecode.ConstantColorCam", category: "Camera")

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Move origin to middle
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

