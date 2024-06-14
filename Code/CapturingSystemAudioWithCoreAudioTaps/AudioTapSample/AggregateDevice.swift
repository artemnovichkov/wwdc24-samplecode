/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that models aggregate device objects, registers audio property listeners, and maintains lists of subdevices and subtaps.
*/

import CoreAudio

class AggregateDevice: AudioDevice {
    var name: String = ""
    @Published var deviceList = Set<String>()
    @Published var tapList = Set<String>()
    @Published var isPrivate = false
    @Published var autoStart = false
    @Published var autoStop = false // Stop IO automatically if all tapped processes stop.
    var isRecording = false
    
    var deviceListAddress = getPropertyAddress(selector: kAudioAggregateDevicePropertyFullSubDeviceList)
    var tapListAddress = getPropertyAddress(selector: kAudioAggregateDevicePropertyTapList)
    var compositionAddress = getPropertyAddress(selector: kAudioAggregateDevicePropertyComposition)
    var propertiesChangedToken: AudioObjectPropertyListenerBlock?
    
    override init(id: AudioObjectID) {
        super.init(id: id)
        
        // Get the name of the aggregate device.
        var propertyAddress = getPropertyAddress(selector: kAudioObjectPropertyName)
        var propertySize = UInt32(MemoryLayout<CFString>.stride)
        var name: CFString = "" as CFString
        _ = withUnsafeMutablePointer(to: &name) { name in
            AudioObjectGetPropertyData(id, &propertyAddress, 0, nil, &propertySize, name)
        }
        self.name = name as String
        
        // Fill out the device and tap lists.
        self.updateDeviceList()
        self.updateTapList()
        
        registerListeners()
    }
    
    deinit {
        unregisterListeners()
    }
    
    func registerListeners() {
        let propertiesChanged: AudioObjectPropertyListenerBlock = { inNumberAddresses, inAddresses in
            for index in 0..<inNumberAddresses {
                let address = inAddresses[Int(index)]
                switch address.mSelector {
                case kAudioAggregateDevicePropertyFullSubDeviceList:
                    self.updateDeviceList()
                case kAudioAggregateDevicePropertyTapList:
                    self.updateTapList()
                case kAudioAggregateDevicePropertyComposition:
                    self.updateConfig()
                default: break
                }
            }
        }
        
        AudioObjectAddPropertyListenerBlock(id, &deviceListAddress, DispatchQueue.main, propertiesChanged)
        AudioObjectAddPropertyListenerBlock(id, &tapListAddress, DispatchQueue.main, propertiesChanged)
        AudioObjectAddPropertyListenerBlock(id, &compositionAddress, DispatchQueue.main, propertiesChanged)
        propertiesChangedToken = propertiesChanged
    }
    
    func unregisterListeners() {
        if let token = propertiesChangedToken {
            AudioObjectRemovePropertyListenerBlock(id, &deviceListAddress, DispatchQueue.main, token)
            AudioObjectRemovePropertyListenerBlock(id, &tapListAddress, DispatchQueue.main, token)
            AudioObjectRemovePropertyListenerBlock(id, &compositionAddress, DispatchQueue.main, token)
            propertiesChangedToken = nil
        }
    }
    
    func updateDeviceList() {
        // Get the device list of the aggregate device.
        self.deviceList = Set<String>()
        var propertySize: UInt32 = 0
        AudioObjectGetPropertyDataSize(self.id, &deviceListAddress, 0, nil, &propertySize)
        var list: CFArray? = nil
        _ = withUnsafeMutablePointer(to: &list) { list in
            AudioObjectGetPropertyData(self.id, &deviceListAddress, 0, nil, &propertySize, list)
        }
        for uid in list as? [CFString] ?? [] {
            self.deviceList.insert(uid as String)
        }
    }
    
    func updateTapList() {
        // Get the tap list of the aggregate device.
        self.tapList = Set<String>()
        var propertySize: UInt32 = 0
        AudioObjectGetPropertyDataSize(self.id, &tapListAddress, 0, nil, &propertySize)
        var list: CFArray? = nil
        _ = withUnsafeMutablePointer(to: &list) { list in
            AudioObjectGetPropertyData(self.id, &tapListAddress, 0, nil, &propertySize, list)
        }
        for uid in list as? [CFString] ?? [] {
            self.tapList.insert(uid as String)
        }
    }
    
    func updateConfig() {
        // Get the aggregate device composition dictionary.
        var propertySize: UInt32 = 0
        var propertyAddress = getPropertyAddress(selector: kAudioAggregateDevicePropertyComposition)
        AudioObjectGetPropertyDataSize(self.id, &propertyAddress, 0, nil, &propertySize)
        var composition: CFDictionary? = nil
        _ = withUnsafeMutablePointer(to: &composition) { composition in
            AudioObjectGetPropertyData(self.id, &propertyAddress, 0, nil, &propertySize, composition)
        }
        
        if let compositionDict = composition as? [String: AnyObject] {
            self.isPrivate = compositionDict[kAudioAggregateDeviceIsPrivateKey] as? Bool ?? self.isPrivate
            self.autoStart = compositionDict[kAudioAggregateDeviceTapAutoStartKey] as? Bool ?? self.autoStart
        }
    }
    
    func setPrivate(priv: Bool) {
        // Get the aggregate device composition dictionary.
        var propertySize: UInt32 = 0
        var propertyAddress = getPropertyAddress(selector: kAudioAggregateDevicePropertyComposition)
        AudioObjectGetPropertyDataSize(self.id, &propertyAddress, 0, nil, &propertySize)
        var composition: CFDictionary? = nil
        _ = withUnsafeMutablePointer(to: &composition) { composition in
            AudioObjectGetPropertyData(self.id, &propertyAddress, 0, nil, &propertySize, composition)
        }
        
        if var compositionDict = composition as? [String: AnyObject] {
            compositionDict[kAudioAggregateDeviceIsPrivateKey] = priv as NSNumber
            // Set the composition back on the aggregate device.
            composition = compositionDict as CFDictionary
            _ = withUnsafeMutablePointer(to: &composition) { composition in
                AudioObjectSetPropertyData(self.id, &propertyAddress, 0, nil, propertySize, composition)
            }
        }
    }
    
    func setAutoStart(autostart: Bool) {
        // Get the aggregate device composition dictionary.
        var propertySize: UInt32 = 0
        var propertyAddress = getPropertyAddress(selector: kAudioAggregateDevicePropertyComposition)
        AudioObjectGetPropertyDataSize(self.id, &propertyAddress, 0, nil, &propertySize)
        var composition: CFDictionary? = nil
        _ = withUnsafeMutablePointer(to: &composition) { composition in
            AudioObjectGetPropertyData(self.id, &propertyAddress, 0, nil, &propertySize, composition)
        }
        
        if var compositionDict = composition as? [String: AnyObject] {
            compositionDict[kAudioAggregateDeviceTapAutoStartKey] = autostart as NSNumber
            // Set the composition back on the aggregate device.
            composition = compositionDict as CFDictionary
            _ = withUnsafeMutablePointer(to: &composition) { composition in
                AudioObjectSetPropertyData(self.id, &propertyAddress, 0, nil, propertySize, composition)
            }
        }
    }
    
    func addSubDevice(uid: String) {
        addRemove(uid: uid, action: .add, type: .device)
    }
    
    func removeSubDevice(uid: String) {
        addRemove(uid: uid, action: .remove, type: .device)
    }
    
    func addSubTap(uid: String) {
        addRemove(uid: uid, action: .add, type: .tap)
    }
    
    func removeSubTap(uid: String) {
        addRemove(uid: uid, action: .remove, type: .tap)
    }
    
    private enum ModifyAction: Int {
        case add = 0
        case remove = 1
    }
    
    private enum ListType: Int {
        case device = 0
        case tap = 1
    }
    
    /// Add or remove a subdevice or subtap from the aggregate device.
    /// - Tag: AddRemove
    private func addRemove(uid: String, action: ModifyAction, type: ListType) {
        var propertyAddress: AudioObjectPropertyAddress
        if type == .device {
            // Use the aggregate subdevice list address.
            propertyAddress = getPropertyAddress(selector: kAudioAggregateDevicePropertyFullSubDeviceList)
        } else {
            // Use the aggregate device tap list address.
            propertyAddress = getPropertyAddress(selector: kAudioAggregateDevicePropertyTapList)
        }
        
        var propertySize: UInt32 = 0
        AudioObjectGetPropertyDataSize(self.id, &propertyAddress, 0, nil, &propertySize)
        var list: CFArray? = nil
        _ = withUnsafeMutablePointer(to: &list) { list in
            AudioObjectGetPropertyData(self.id, &propertyAddress, 0, nil, &propertySize, list)
        }
        
        if var listAsArray = list as? [CFString] {
            if action == .add {
                // Add the new object ID if it's not already in the list.
                if !listAsArray.contains(uid as CFString) {
                    listAsArray.append(uid as CFString)
                    propertySize += UInt32(MemoryLayout<CFString>.stride)
                }
            } else {
                // Remove the object ID if it's in the list.
                if let index = listAsArray.firstIndex(of: uid as CFString) {
                    listAsArray.remove(at: index)
                }
            }
            
            // Set the list back on the aggregate device.
            list = listAsArray as CFArray
            _ = withUnsafeMutablePointer(to: &list) { list in
                AudioObjectSetPropertyData(self.id, &propertyAddress, 0, nil, propertySize, list)
            }
        }
    }
}
