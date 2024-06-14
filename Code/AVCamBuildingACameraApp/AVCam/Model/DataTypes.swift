/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Supporting data types for the app.
*/

import AVFoundation

// MARK: - Supporting types

/// An enumeration that describes the current status of the camera.
enum CameraStatus {
    /// The initial status upon creation.
    case unknown
    /// A status that indicates a person disallows access to the camera or microphone.
    case unauthorized
    /// A status that indicates the camera failed to start.
    case failed
    /// A status that indicates the camera is successfully running.
    case running
    /// A status that indicates higher-priority media processing is interrupting the camera.
    case interrupted
}

/// An enumeration that defines the activity states the capture service supports.
///
/// This type provides feedback to the UI regarding the active status of the `CaptureService` actor.
enum CaptureActivity {
    case idle
    /// A status that indicates the capture service is performing photo capture.
    case photoCapture(willCapture: Bool = false, isLivePhoto: Bool = false)
    /// A status that indicates the capture service is performing movie capture.
    case movieCapture(duration: TimeInterval = 0.0)
    
    var isLivePhoto: Bool {
        if case .photoCapture(_, let isLivePhoto) = self {
            return isLivePhoto
        }
        return false
    }
    
    var willCapture: Bool {
        if case .photoCapture(let willCapture, _) = self {
            return willCapture
        }
        return false
    }
    
    var currentTime: TimeInterval {
        if case .movieCapture(let duration) = self {
            return duration
        }
        return .zero
    }
    
    var isRecording: Bool {
        if case .movieCapture(_) = self {
            return true
        }
        return false
    }
}

/// An enumeration of the capture modes that the camera supports.
enum CaptureMode: String, Identifiable, CaseIterable {
    var id: Self { self }
    /// A mode that enables photo capture.
    case photo
    /// A mode that enables video capture.
    case video
    
    var systemName: String {
        switch self {
        case .photo:
            "camera.fill"
        case .video:
            "video.fill"
        }
    }
}

/// A structure that represents a captured photo.
struct Photo: Sendable {
    let data: Data
    let isProxy: Bool
    let livePhotoMovieURL: URL?
}

/// A structure that contains the uniform type identifier and movie URL.
struct Movie: Sendable {
    /// The temporary location of the file on disk.
    let url: URL
}

@Observable
/// An object that stores the state of a person's enabled photo features.
class PhotoFeatures {
    var isFlashEnabled = false
    var isLivePhotoEnabled = false
    var qualityPrioritization: QualityPrioritization = .quality
    
    var current: EnabledPhotoFeatures {
        .init(isFlashEnabled: isFlashEnabled,
              isLivePhotoEnabled: isLivePhotoEnabled,
              qualityPrioritization: qualityPrioritization)
    }
}

struct EnabledPhotoFeatures {
    let isFlashEnabled: Bool
    let isLivePhotoEnabled: Bool
    let qualityPrioritization: QualityPrioritization
}

/// A structure that represents the capture capabilities of `CaptureService` in
/// its current configuration.
struct CaptureCapabilities {
    let isFlashSupported: Bool
    let isLivePhotoCaptureSupported: Bool
    let isHDRSupported: Bool
    
    init(isFlashSupported: Bool = false,
         isLivePhotoCaptureSupported: Bool = false,
         isHDRSupported: Bool = false) {
        
        self.isFlashSupported = isFlashSupported
        self.isLivePhotoCaptureSupported = isLivePhotoCaptureSupported
        self.isHDRSupported = isHDRSupported
    }
    
    static let unknown = CaptureCapabilities()
}

enum QualityPrioritization: Int, Identifiable, CaseIterable, CustomStringConvertible {
    var id: Self { self }
    case speed = 1
    case balanced
    case quality
    var description: String {
        switch self {
        case.speed:
            return "Speed"
        case .balanced:
            return "Balanced"
        case .quality:
            return "Quality"
        }
    }
}

enum CameraError: Error {
    case videoDeviceUnavailable
    case audioDeviceUnavailable
    case addInputFailed
    case addOutputFailed
    case setupFailed
    case deviceChangeFailed
}

protocol OutputService {
    associatedtype Output: AVCaptureOutput
    var output: Output { get }
    var captureActivity: CaptureActivity { get }
    var capabilities: CaptureCapabilities { get }
    func updateConfiguration(for device: AVCaptureDevice)
    func setVideoRotationAngle(_ angle: CGFloat)
}

extension OutputService {
    func setVideoRotationAngle(_ angle: CGFloat) {
        // Set the rotation angle on the output object's video connection.
        output.connection(with: .video)?.videoRotationAngle = angle
    }
    func updateConfiguration(for device: AVCaptureDevice) {}
}
