/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that models audio process objects and registers a property listener to detect when an audio process is running.
*/

class AudioProcess: Identifiable, Hashable, ObservableObject {
    var id: AudioObjectID
    var pid: Int32 = 0
    var name: String = ""
    var bundleID: String = ""
    @Published var isRunning = false
    
    var isRunningAddress = getPropertyAddress(selector: kAudioProcessPropertyIsRunning)
    var isRunningToken: AudioObjectPropertyListenerBlock?
    
    init(id: AudioObjectID) {
        self.id = id
        
        // Get the bundle ID of the audio process.
        var propertyAddress = getPropertyAddress(selector: kAudioProcessPropertyBundleID)
        var propertySize = UInt32(MemoryLayout<CFString>.stride)
        var bundleID: CFString = "" as CFString
        _ = withUnsafeMutablePointer(to: &bundleID) { bundleID in
            AudioObjectGetPropertyData(id, &propertyAddress, 0, nil, &propertySize, bundleID)
        }
        self.bundleID = bundleID as String
        
        // Get the PID of the audio process.
        propertyAddress = getPropertyAddress(selector: kAudioProcessPropertyPID)
        propertySize = UInt32(MemoryLayout<Int32>.stride)
        var processPID: Int32 = 0
        AudioObjectGetPropertyData(id, &propertyAddress, 0, nil, &propertySize, &processPID)
        self.pid = processPID
        
        self.name = processNameFromPID(pid: self.pid)
        self.updateIsRunning()
        
        registerListeners()
    }
    
    deinit {
        unregisterListeners()
    }
    
    static func == (lhs: AudioProcess, rhs: AudioProcess) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    func registerListeners() {
        let isRunningChanged: AudioObjectPropertyListenerBlock = { inNumberAddresses, inAddresses in
            for index in 0..<inNumberAddresses {
                let address = inAddresses[Int(index)]
                switch address.mSelector {
                case kAudioProcessPropertyIsRunning:
                    self.updateIsRunning()
                default: break
                }
            }
        }
        
        AudioObjectAddPropertyListenerBlock(id, &isRunningAddress, DispatchQueue.main, isRunningChanged)
        isRunningToken = isRunningChanged
    }
    
    func unregisterListeners() {
        if let token = isRunningToken {
            AudioObjectRemovePropertyListenerBlock(id, &isRunningAddress, DispatchQueue.main, token)
            isRunningToken = nil
        }
    }
    
    func updateIsRunning() {
        // Get the `isRunning` property of the process object.
        var propertySize = UInt32(MemoryLayout<UInt32>.stride)
        var running: UInt32 = 0
        AudioObjectGetPropertyData(self.id, &isRunningAddress, 0, nil, &propertySize, &running)
        let oldState = self.isRunning
        self.isRunning = running != 0
        
        // Check whether the process stopped running.
        if oldState == true && self.isRunning == false {
            self.notifyProcessStopped()
        }
    }
    
    func notifyProcessStopped() {
        guard let model = Model.shared else { return }
        model.processStopped()
    }
    
    private func processNameFromPID(pid: Int32) -> String {
        // Try to get the localized process name from the app using `NSWorkspace`.
        for app in NSWorkspace.shared.runningApplications where app.processIdentifier == pid {
            return app.localizedName ?? ""
        }

        // Otherwise use `sysctl` to obtain the process name.
        var result: String = ""
        var info = kinfo_proc()
        var len = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        if (sysctl(&mib, 4, &info, &len, nil, 0) != -1) && len > 0 {
            withUnsafePointer(to: info.kp_proc.p_comm) {
                $0.withMemoryRebound(to: UInt8.self, capacity: len) {
                    result = String(cString: $0)
                }
            }
        }
        return result
    }
}
