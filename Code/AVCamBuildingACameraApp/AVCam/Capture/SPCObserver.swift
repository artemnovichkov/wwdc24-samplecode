/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that provides an asynchronous stream capture devices that represent the system-preferred camera.
*/
import AVFoundation

/// An object that provides an asynchronous stream capture devices that represent the system-preferred camera.
class SystemPreferredCameraObserver: NSObject {
    
    private let systemPreferredKeyPath = "systemPreferredCamera"
    
    let changes: AsyncStream<AVCaptureDevice?>
    private var continuation: AsyncStream<AVCaptureDevice?>.Continuation?

    override init() {
        let (changes, continuation) = AsyncStream.makeStream(of: AVCaptureDevice?.self)
        self.changes = changes
        self.continuation = continuation
        
        super.init()
        
        /// Key-value observe the `systemPreferredCamera` class property on `AVCaptureDevice`.
        AVCaptureDevice.self.addObserver(self, forKeyPath: systemPreferredKeyPath, options: [.new], context: nil)
    }

    deinit {
        continuation?.finish()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case systemPreferredKeyPath:
            // Update the observer's system-preferred camera value.
            let newDevice = change?[.newKey] as? AVCaptureDevice
            continuation?.yield(newDevice)
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
