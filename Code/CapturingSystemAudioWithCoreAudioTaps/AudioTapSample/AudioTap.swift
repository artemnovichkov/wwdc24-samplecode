/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that models audio tap objects, registers audio property listeners, and publishes a variable that holds the tap's configuration.
*/

// Structure that models a `CATapDescription` object.
struct TapConfig: Hashable {
    var name: String = "Sample audio tap"
    var processes = Set<AudioObjectID>()
    var isPrivate = false
    var mute: TapMute = .unmuted
    var mixdown = TapMixdown.stereo
    var exclusive = false
    var device: String?
    var streamIndex: UInt? = 0
}

class AudioTap: Identifiable, Hashable, ObservableObject {
    var id: AudioObjectID
    var uid: String = ""
    var format: String = ""
    @Published var config = TapConfig()
    
    var descriptionAddress = getPropertyAddress(selector: kAudioTapPropertyDescription)
    var descriptionChangedToken: AudioObjectPropertyListenerBlock?
    
    /// Initialize an `AudioTap` by storing the tap's unique identifier and description, and registering audio property listeners.
    /// - Tag: AudioTap
    init(id: AudioObjectID) {
        self.id = id
        
        // Get the UID of the audio tap.
        var propertyAddress = getPropertyAddress(selector: kAudioTapPropertyUID)
        var propertySize = UInt32(MemoryLayout<CFString>.stride)
        var tapUID: CFString = "" as CFString
        _ = withUnsafeMutablePointer(to: &tapUID) { tapUID in
            AudioObjectGetPropertyData(id, &propertyAddress, 0, nil, &propertySize, tapUID)
        }
        self.uid = tapUID as String
        
        // Get the format of the audio tap.
        propertyAddress = getPropertyAddress(selector: kAudioTapPropertyFormat)
        propertySize = UInt32(MemoryLayout<AudioStreamBasicDescription>.stride)
        var streamDescription = AudioStreamBasicDescription()
        AudioObjectGetPropertyData(id, &propertyAddress, 0, nil, &propertySize, &streamDescription)
        let channelCount = streamDescription.mChannelsPerFrame
        let sampleRate = Int(streamDescription.mSampleRate)
        self.format = "\(channelCount) channels at \(sampleRate)Hz"
        
        self.updateTapConfig()
        
        registerListeners()
    }
    
    deinit {
        unregisterListeners()
    }
    
    static func == (lhs: AudioTap, rhs: AudioTap) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    func registerListeners() {
        let descriptionChanged: AudioObjectPropertyListenerBlock = { _, _ in
            self.updateTapConfig()
        }
        
        AudioObjectAddPropertyListenerBlock(id, &descriptionAddress, DispatchQueue.main, descriptionChanged)
        descriptionChangedToken = descriptionChanged
    }
    
    func unregisterListeners() {
        if let token = descriptionChangedToken {
            AudioObjectRemovePropertyListenerBlock(id, &descriptionAddress, DispatchQueue.main, token)
            descriptionChangedToken = nil
        }
    }
    
    func updateTapConfig() {
        // Get the description of the audio tap.
        var propertyAddress = getPropertyAddress(selector: kAudioTapPropertyDescription)
        var propertySize = UInt32(MemoryLayout<CATapDescription>.stride)
        var description = CATapDescription()
        _ = withUnsafeMutablePointer(to: &description) { description in
            AudioObjectGetPropertyData(id, &propertyAddress, 0, nil, &propertySize, description)
        }
        
        // Fill out the tap config from the description.
        self.config.name = description.name
        self.config.processes = Set(description.processes)
        self.config.isPrivate = description.isPrivate
        self.config.mute = TapMute(rawValue: description.muteBehavior.rawValue) ?? self.config.mute
        self.config.mixdown = description.isMixdown ? (description.isMono ? .mono : .stereo) : .deviceFormat
        self.config.exclusive = description.isExclusive
        self.config.device = description.deviceUID
        self.config.streamIndex = description.stream ?? self.config.streamIndex
    }
    
    func setTapDescription() {
        // Get the description of the audio tap.
        var propertyAddress = getPropertyAddress(selector: kAudioTapPropertyDescription)
        var propertySize = UInt32(MemoryLayout<CATapDescription>.stride)
        var description: CATapDescription = CATapDescription()
        _ = withUnsafeMutablePointer(to: &description) { description in
            AudioObjectGetPropertyData(self.id, &propertyAddress, 0, nil, &propertySize, description)
        }
        
        // Fill out the description properties with the saved tap config.
        description.name = self.config.name
        description.processes = Array(self.config.processes)
        description.isPrivate = self.config.isPrivate
        description.muteBehavior = CATapMuteBehavior(rawValue: self.config.mute.rawValue) ?? description.muteBehavior
        description.isMixdown = self.config.mixdown == .mono || self.config.mixdown == .stereo
        description.isMono = self.config.mixdown == .mono
        description.isExclusive = self.config.exclusive
        description.deviceUID = self.config.device
        description.stream = self.config.streamIndex

        // Set the modified description on the tap object.
        _ = withUnsafeMutablePointer(to: &description) { description in
            AudioObjectSetPropertyData(self.id, &propertyAddress, 0, nil, propertySize, description)
        }
    }
}
