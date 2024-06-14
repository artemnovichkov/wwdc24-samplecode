/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that provides functions for running IO on an audio device, recording audio input to a file, and looping back audio data from input to output streams.
*/

#include "AudioRecorder.h"
#include <vector>

constexpr AudioObjectPropertyAddress PropertyAddress(AudioObjectPropertySelector selector,
                                                     AudioObjectPropertyScope scope = kAudioObjectPropertyScopeGlobal,
                                                     AudioObjectPropertyElement element = kAudioObjectPropertyElementMain) noexcept {
    return {selector, scope, element};
}

enum class StreamDirection : UInt32 {
    output,
    input
};

static OSStatus deviceChangedListener(AudioObjectID, UInt32, const AudioObjectPropertyAddress*, void* inClientData) noexcept;

static OSStatus ioproc(AudioObjectID,
                       const AudioTimeStamp*,
                       const AudioBufferList* inInputData,
                       const AudioTimeStamp*,
                       AudioBufferList* outOutputData,
                       const AudioTimeStamp*,
                       void* inClientData) noexcept;

@interface AudioRecorder ()

@property (readwrite, nonatomic) std::shared_ptr<std::vector<AudioStreamBasicDescription>> inputStreamList;
@property (readwrite, nonatomic) std::shared_ptr<std::vector<AudioStreamBasicDescription>> outputStreamList;
@property (strong, readwrite, nonatomic) NSURL* recordingURL;
@property (readwrite, nonatomic) std::shared_ptr<std::vector<ExtAudioFileRef>> fileList;
@property (readwrite, nonatomic) AudioDeviceIOProcID IOProcID;

@end

@implementation AudioRecorder

@synthesize deviceID = _deviceID;
@synthesize inputStreamList = _inputStreamList;
@synthesize outputStreamList = _outputStreamList;
@synthesize recordingEnabled = _recordingEnabled;
@synthesize loopbackEnabled = _loopbackEnabled;
@synthesize recordingURL = _recordingURL;
@synthesize fileList = _fileList;
@synthesize IOProcID = _IOProcID;

-(id) init {
    self = [super init];
    if (self == nullptr) {
        return nullptr;
    }
    
    _deviceID = kAudioObjectUnknown;
    _inputStreamList = std::make_shared<std::vector<AudioStreamBasicDescription>>();
    _outputStreamList = std::make_shared<std::vector<AudioStreamBasicDescription>>();
    _fileList = std::make_shared<std::vector<ExtAudioFileRef>>();
    _recordingEnabled = false;
    
    return self;
}

-(void) setDeviceID: (AudioObjectID)deviceID {
    if (_deviceID == deviceID) {
        return;
    }
    [self adaptToDevice: deviceID];
}

-(bool) recordingEnabled {
    return _recordingEnabled;
}

-(void) setRecordingEnabled: (bool)enabled {
    if (_recordingEnabled == enabled) {
        return;
    }
    _recordingEnabled = enabled;
    if (enabled) {
        if (_loopbackEnabled) {
            [self stopIO];
        }
        if (![self startRecording]) {
            _recordingEnabled = false;
        }
    }
    else {
        if (_loopbackEnabled) {
            [self cleanUpRecordingFiles];
        }
        else {
            [self stopIO];
        }
    }
}

-(bool) loopbackEnabled {
    return _loopbackEnabled;
}

-(void) setLoopbackEnabled: (bool)enabled {
    if (_loopbackEnabled == enabled) {
        return;
    }
    _loopbackEnabled = enabled;
    if (_recordingEnabled) {
        return;
    }
    if (enabled) {
        if (![self startIO]) {
            _loopbackEnabled = false;
        }
    }
    else {
        [self stopIO];
    }
}

-(BOOL) adaptToDevice: (AudioObjectID)deviceID {
    [self stopIO];
    [self unregisterListeners];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    _deviceID = deviceID;
#pragma clang diagnostic pop
    
    [self catalogDeviceStreams];
    [self registerListeners];
    
    BOOL answer = true;
    if (answer && (self.deviceID != kAudioObjectUnknown)) {
        if (self.recordingEnabled) {
            answer = [self startRecording];
        }
        else if (self.loopbackEnabled) {
            answer = [self startIO];
        }
    }
    return answer;
}

-(void) catalogDeviceStreams {
    self.inputStreamList->clear();
    self.outputStreamList->clear();

    if (self.deviceID == kAudioObjectUnknown) {
        return;
    }

    // Get the stream list from the device.
    UInt32 size = 0;
    AudioObjectPropertyAddress address = PropertyAddress(kAudioDevicePropertyStreams);
    OSStatus error = AudioObjectGetPropertyDataSize(self.deviceID, &address, 0, nullptr, &size);
    auto streamCount = size / sizeof(AudioObjectID);
    if (error != kAudioHardwareNoError || streamCount == 0) {
        return;
    }
    std::vector<AudioObjectID> streamList(streamCount);
    error = AudioObjectGetPropertyData(self.deviceID, &address, 0, nullptr, &size, streamList.data());
    if (error != kAudioHardwareNoError) {
        return;
    }
    
    streamList.resize(size / sizeof(AudioObjectID));
    for (auto streamID : streamList) {
        // Get the format of each stream.
        address = PropertyAddress(kAudioStreamPropertyVirtualFormat);
        AudioStreamBasicDescription format;
        size = sizeof(AudioStreamBasicDescription);
        memset(&format, 0, size);
        error = AudioObjectGetPropertyData(streamID, &address, 0, nullptr, &size, &format);
        if (error == kAudioHardwareNoError) {
            address = PropertyAddress(kAudioStreamPropertyDirection);
            StreamDirection direction = StreamDirection::output;
            size = sizeof(UInt32);
            AudioObjectGetPropertyData(streamID, &address, 0, nullptr, &size, &direction);
            if (direction == StreamDirection::output) {
                self.outputStreamList->push_back(format);
            }
            else {
                self.inputStreamList->push_back(format);
            }
        }
    }
}

-(bool) startRecording {
    if (![self makeRecordingFiles]) {
        return false;
    }
    if (![self startIO]) {
        [self cleanUpRecordingFiles];
        return false;
    }
    return true;
}

-(bool) startIO {
    NSLog(@"Starting IO");
    AudioDeviceIOProcID ioProcID = nullptr;
    auto error = AudioDeviceCreateIOProcID(self.deviceID, ioproc, (__bridge void*)self, &ioProcID);
    if (error != kAudioHardwareNoError) {
        return false;
    }
    self.IOProcID = ioProcID;
    
    error = AudioDeviceStart(self.deviceID, self.IOProcID);
    if (error != kAudioHardwareNoError) {
        AudioDeviceDestroyIOProcID(self.deviceID, self.IOProcID);
        self.IOProcID = nullptr;
        return false;
    }
    return true;
}

-(void) stopIO {
    NSLog(@"Stopping IO");
    AudioDeviceStop(self.deviceID, self.IOProcID);
    AudioDeviceDestroyIOProcID(self.deviceID, self.IOProcID);
    self.IOProcID = nullptr;
    [self cleanUpRecordingFiles];
}

-(void) registerListeners {
    if (self.deviceID != 0) {
        auto address = PropertyAddress(kAudioDevicePropertyDeviceIsAlive);
        AudioObjectAddPropertyListener(self.deviceID, &address, deviceChangedListener, (__bridge void*)self);
        address = PropertyAddress(kAudioAggregateDevicePropertyFullSubDeviceList);
        AudioObjectAddPropertyListener(self.deviceID, &address, deviceChangedListener, (__bridge void*)self);
        address = PropertyAddress(kAudioAggregateDevicePropertyTapList);
        AudioObjectAddPropertyListener(self.deviceID, &address, deviceChangedListener, (__bridge void*)self);
    }
}

-(void) unregisterListeners {
    if (self.deviceID != 0) {
        auto address = PropertyAddress(kAudioDevicePropertyDeviceIsAlive);
        AudioObjectRemovePropertyListener(self.deviceID, &address, deviceChangedListener, (__bridge void*)self);
        address = PropertyAddress(kAudioAggregateDevicePropertyFullSubDeviceList);
        AudioObjectRemovePropertyListener(self.deviceID, &address, deviceChangedListener, (__bridge void*)self);
        address = PropertyAddress(kAudioAggregateDevicePropertyTapList);
        AudioObjectRemovePropertyListener(self.deviceID, &address, deviceChangedListener, (__bridge void*)self);
    }
}

-(bool) makeRecordingFiles {
    // Return if there are no input streams to record from.
    if (self.inputStreamList->size() == 0) {
        return false;
    }
    
    // Store recording files in the user `Music` directory.
    auto* musicURL = [NSFileManager.defaultManager URLForDirectory: NSMusicDirectory
                                                          inDomain: NSUserDomainMask
                                                 appropriateForURL: nullptr
                                                            create: YES 
                                                             error: nullptr];
    auto* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    auto dateString = NSDate.now.description;
    dateString = [dateString stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    dateString = [dateString stringByReplacingOccurrencesOfString:@":" withString:@"-"];
    dateString = [dateString stringByReplacingOccurrencesOfString:@"+" withString:@""];
    
    auto streamFormats = self.inputStreamList;
    auto files = self.fileList;
    for (unsigned index = 0; index < streamFormats->size(); ++index) {
        auto* path = [NSString stringWithFormat: @"%s/AudioTapSample/Rec-%@-Stream_%d.caf", musicURL.fileSystemRepresentation, dateString, index];
        if (access([path UTF8String], R_OK | W_OK) != 0) {
            // If unable to access the `Music` directory, use `TMPDIR` instead.
            auto tmp = getenv("TMPDIR");
            path = [NSString stringWithFormat: @"%sRec-%@-Stream_%d.caf", tmp, dateString, index];
        }

        auto* url = [NSURL fileURLWithPath: path];
        self.recordingURL = url;
        auto format = streamFormats->at(index);
        ExtAudioFileRef file = nullptr;
        auto error = ExtAudioFileCreateWithURL((__bridge CFURLRef)url, kAudioFileCAFType, &format, nullptr, kAudioFileFlags_EraseFile, &file);
        if (error != 0) {
            [self cleanUpRecordingFiles];
            return false;
        }
        files->push_back(file);
    }
    return true;
}

-(void) cleanUpRecordingFiles {
    auto list = self.fileList;
    for (auto file : *list) {
        ExtAudioFileDispose(file);
    }
    list->clear();
}

@end

static OSStatus deviceChangedListener(AudioObjectID, UInt32 inNumberAddresses, const AudioObjectPropertyAddress* inAddresses, void* inClientData) noexcept {
    auto* engine = (__bridge AudioRecorder*)inClientData;
    if (engine != nullptr) {
        for (unsigned index = 0; index < inNumberAddresses; ++index) {
            auto address = inAddresses[index];
            switch (address.mSelector) {
                case kAudioDevicePropertyDeviceIsAlive:
                    [engine adaptToDevice: kAudioObjectUnknown];
                case kAudioAggregateDevicePropertyFullSubDeviceList:
                case kAudioAggregateDevicePropertyTapList:
                    [engine adaptToDevice: engine.deviceID];
            }
        }
    }
    return kAudioHardwareNoError;
}

static OSStatus ioproc(AudioObjectID,
                       const AudioTimeStamp*,
                       const AudioBufferList* inInputData,
                       const AudioTimeStamp*,
                       AudioBufferList* outOutputData,
                       const AudioTimeStamp*,
                       void* inClientData) noexcept {
    // Get the `AudioRecorder` object from `inClientData`.
    auto* recorder = (__bridge AudioRecorder*)inClientData;
    auto fileList = recorder.fileList;
    
    UInt32 numberInputBuffers = 0;
    UInt32 numberFramesToRecord = 0;
    if (inInputData != nullptr && inInputData->mNumberBuffers > 0) {
        numberInputBuffers = inInputData->mNumberBuffers;
        numberFramesToRecord = inInputData->mBuffers[0].mDataByteSize / (inInputData->mBuffers[0].mNumberChannels * sizeof(Float32));
    }
    UInt32 numberOutputBuffers = 0;
    UInt32 numberFramesToOutput = 0;
    if (outOutputData != nullptr && outOutputData->mNumberBuffers > 0) {
        numberOutputBuffers = outOutputData->mNumberBuffers;
        numberFramesToOutput = outOutputData->mBuffers[0].mDataByteSize / (outOutputData->mBuffers[0].mNumberChannels * sizeof(Float32));
    }
    
    for (size_t index = 0; index < numberInputBuffers; ++index) {
        AudioBuffer buffer = inInputData->mBuffers[index];
        if (recorder.recordingEnabled == true && index < fileList->size()) {
            // Write the input buffer data to the recording file.
            AudioBufferList writeData;
            writeData.mNumberBuffers = 1;
            writeData.mBuffers[0] = buffer;
            ExtAudioFileWriteAsync(fileList->at(index), numberFramesToRecord, &writeData);
        }
        if (recorder.loopbackEnabled == true && index < numberOutputBuffers) {
            // Write the input buffer data to the output buffer.
            // This will only work correctly if the formats of the output streams in the device match the formats of the input streams.
            memcpy(outOutputData->mBuffers[index].mData, buffer.mData, buffer.mDataByteSize);
        }
    }
    
    return kAudioHardwareNoError;
}
