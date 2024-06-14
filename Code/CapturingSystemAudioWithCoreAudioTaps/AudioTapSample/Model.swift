/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model that maintains the state of the content view, registers audio property listeners, and interacts with the audio recorder.
*/

import Foundation
import CoreAudio

class Model: ObservableObject {
    // All audio processes on the system.
    @Published var audioProcessList = [AudioProcess]()
    // The audio process the user selects in the UI.
    @Published var processSelection: AudioObjectID = 0
    
    // All visible audio taps on the system.
    @Published var audioTapList = [AudioTap]()
    // The audio tap the user selects in the UI.
    @Published var tapSelection: AudioObjectID = 0
    // The configuration of the tap the user creates in the UI.
    @Published var tapConfiguration = TapConfig()
    
    // All physical audio devices on the system.
    @Published var realDeviceList = [AudioDevice]()
    // All aggregate devices on the system.
    @Published var aggregateDeviceList = [AggregateDevice]()
    // The aggregate device the user selects in the UI.
    @Published var aggregateDeviceSelection: AudioObjectID = 0 {
        didSet {
            recorder.deviceID = aggregateDeviceSelection
        }
    }
    
    @Published var recordingActive = false
    @Published var loopbackActive = false
    let recorder = AudioRecorder()
    
    var processListAddress = getPropertyAddress(selector: kAudioHardwarePropertyProcessObjectList)
    var tapListAddress = getPropertyAddress(selector: kAudioHardwarePropertyTapList)
    var deviceListAddress = getPropertyAddress(selector: kAudioHardwarePropertyDevices)
    
    static var shared: Model?
    var listsChangedToken: AudioObjectPropertyListenerBlock?
    
    init() {
        Self.shared = self
        
        loadProcessList()
        loadTapList()
        loadDeviceList()
        registerListeners()
    }
    
    deinit {
        unregisterListeners()
    }
    
    func registerListeners() {
        let listsChanged: AudioObjectPropertyListenerBlock = { inNumberAddresses, inAddresses in
            // Get the shared instance of the model.
            guard let model = Model.shared else { return }
            for index in 0..<inNumberAddresses {
                let address = inAddresses[Int(index)]
                switch address.mSelector {
                case kAudioHardwarePropertyProcessObjectList:
                    model.loadProcessList()
                case kAudioHardwarePropertyTapList:
                    model.loadTapList()
                case kAudioHardwarePropertyDevices:
                    model.loadDeviceList()
                default: break
                }
            }
        }
        
        // Register a listener for the process list property on the system object.
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &processListAddress,
            DispatchQueue.main,
            listsChanged)

        // Register a listener for the tap list property on the system object.
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &tapListAddress,
            DispatchQueue.main,
            listsChanged)
        
        // Register a listener for the device list property on the system object.
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &deviceListAddress,
            DispatchQueue.main,
            listsChanged)
        
        listsChangedToken = listsChanged
    }
    
    func unregisterListeners() {
        if let token = listsChangedToken {
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &processListAddress,
                DispatchQueue.main,
                token)
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &tapListAddress,
                DispatchQueue.main,
                token)
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &deviceListAddress,
                DispatchQueue.main,
                token)
            listsChangedToken = nil
        }
    }
}

// MARK: - Audio process objects

extension Model {
    // Retrieve list of audio processes from the HAL system.
    func loadProcessList() {
        // Clear the process list.
        audioProcessList = [AudioProcess]()

        var propertySize: UInt32 = 0
        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &processListAddress, 0, nil, &propertySize)
        let processCount = Int(propertySize) / MemoryLayout<AudioObjectID>.stride
        var list: [AudioObjectID] = [AudioObjectID](repeating: 0, count: processCount)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &processListAddress, 0, nil, &propertySize, &list)
        
        for index in 0..<list.count {
            audioProcessList.append(AudioProcess(id: list[index]))
        }
    }
    
    func processStopped() {
        // Get the selected aggregate device to use for audio IO.
        if let device = aggregateDeviceList.first(where: { $0.id == aggregateDeviceSelection }) {
            if device.autoStop {
                // The aggregate device wants to stop IO automatically when all tapped processes stop.
                // Iterate through the taps in the aggregate device.
                for tapUID in device.tapList {
                    if let tap = audioTapList.first(where: { $0.uid == tapUID }) {
                        // Iterate through the processes in the tap.
                        for processID in tap.config.processes {
                            if let process = audioProcessList.first(where: { $0.id == processID }) {
                                // If any process is still running, don't stop IO.
                                if process.isRunning {
                                    return
                                }
                            }
                        }
                    }
                }
                
                // The tap list contains no running processes, so stop IO.
                stopRecording()
                stopLoopback()
            }
        }
    }
}

// MARK: - Audio taps

extension Model {
    // Retrieve list of audio taps from the HAL system.
    func loadTapList() {
        // Clear the tap list.
        audioTapList = [AudioTap]()
        
        var propertySize: UInt32 = 0
        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &tapListAddress, 0, nil, &propertySize)
        let tapCount = Int(propertySize) / MemoryLayout<AudioObjectID>.stride
        var list: [AudioObjectID] = [AudioObjectID](repeating: 0, count: tapCount)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &tapListAddress, 0, nil, &propertySize, &list)
        
        for id in list {
            audioTapList.append(AudioTap(id: id))
        }
    }
    
    /// Create a new process tap based on the provided tap description.
    /// - Tag: CreateTap
    func createTap() {
        // Create a tap description.
        let description = CATapDescription()
        
        // Fill out the description properties with the tap configuration from the UI.
        description.name = tapConfiguration.name
        description.processes = Array(tapConfiguration.processes)
        description.isPrivate = tapConfiguration.isPrivate
        description.muteBehavior = CATapMuteBehavior(rawValue: tapConfiguration.mute.rawValue) ?? description.muteBehavior
        description.isMixdown = tapConfiguration.mixdown == .mono || tapConfiguration.mixdown == .stereo
        description.isMono = tapConfiguration.mixdown == .mono
        description.isExclusive = tapConfiguration.exclusive
        description.deviceUID = tapConfiguration.device
        description.stream = tapConfiguration.streamIndex
        
        // Ask the HAL to create a new tap and put the resulting `AudioObjectID` in `tapID`.
        var tapID = AudioObjectID(kAudioObjectUnknown)
        AudioHardwareCreateProcessTap(description, &tapID)
    }
    
    func destroyTap(id: AudioObjectID) {
        if id != 0 {
            // Destroy the tap object.
            AudioHardwareDestroyProcessTap(id)
        }
    }
}

// MARK: - Audio devices

extension Model {
    // Retrieve list of aggregate devices from the HAL system.
    func loadDeviceList() {
        // Clear the physical device list.
        realDeviceList = [AudioDevice]()
        // Clear the aggregate device list.
        aggregateDeviceList = [AggregateDevice]()
        
        var propertySize: UInt32 = 0
        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &deviceListAddress, 0, nil, &propertySize)
        let deviceCount = Int(propertySize) / MemoryLayout<AudioObjectID>.stride
        var list: [AudioObjectID] = [AudioObjectID](repeating: 0, count: deviceCount)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &deviceListAddress, 0, nil, &propertySize, &list)
        
        for id in list {
            // Get the transport type of the device to check whether it's an aggregate.
            var propertyAddress = getPropertyAddress(selector: kAudioDevicePropertyTransportType)
            propertySize = UInt32(MemoryLayout<UInt32>.stride)
            var transportType: UInt32 = 0
            AudioObjectGetPropertyData(id, &propertyAddress, 0, nil, &propertySize, &transportType)
            
            if transportType == kAudioDeviceTransportTypeAggregate {
                aggregateDeviceList.append(AggregateDevice(id: id))
            } else {
                realDeviceList.append(AudioDevice(id: id))
            }
        }
    }
    
    /// Create a new aggregate device with a unique identifier.
    /// - Tag: CreateAggregateDevice
    func createAggregateDevice() {
        let description = [kAudioAggregateDeviceNameKey: "Sample Aggregate Audio Device", kAudioAggregateDeviceUIDKey: UUID().uuidString]
        var id: AudioObjectID = 0
        AudioHardwareCreateAggregateDevice(description as CFDictionary, &id)
    }
    
    func destroyAggregateDevice(id: AudioObjectID) {
        if id != 0 {
            AudioHardwareDestroyAggregateDevice(id)
        }
    }
}

// MARK: - Audio IO

extension Model {
    // Start the audio recorder.
    func startRecording() {
        recorder.recordingEnabled = true
        recordingActive = recorder.recordingEnabled
    }
    
    // Stop the audio recorder.
    func stopRecording() {
        recorder.recordingEnabled = false
        recordingActive = recorder.recordingEnabled
    }
    
    // Open the directory that stores audio recording files in Finder.
    func openDirectory() {
        if let url = recorder.recordingURL {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
    
    // Start audio loopback.
    func startLoopback() {
        recorder.loopbackEnabled = true
        loopbackActive = recorder.loopbackEnabled
    }
    
    // Stop audio loopback.
    func stopLoopback() {
        recorder.loopbackEnabled = false
        loopbackActive = recorder.loopbackEnabled
    }
}

// MARK: - Utility

public func getPropertyAddress(selector: AudioObjectPropertySelector,
                               scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
                               element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain) -> AudioObjectPropertyAddress {
    return AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
}

public enum TapMute: Int, CaseIterable {
    case unmuted = 0
    case muted = 1
    case mutedWhenTapped = 2
}

public enum TapMixdown: Int, CaseIterable {
    case mono = 0
    case stereo = 1
    case deviceFormat = 2
}
