/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that implements wrapping a system I/O audio unit.
*/
#include "OutputAU.hpp"

#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>
#if TARGET_OS_OSX
#import <IOKit/audio/IOAudioTypes.h>
#endif

#include <stdexcept>
#include <string>

OutputAU::OutputAU()
{
	AudioComponentDescription description;
	description.componentType = kAudioUnitType_Output;
#if TARGET_OS_IPHONE
	description.componentSubType = kAudioUnitSubType_RemoteIO;
#elif TARGET_OS_OSX
	description.componentSubType = kAudioUnitSubType_HALOutput;
#endif
	description.componentManufacturer = kAudioUnitManufacturer_Apple;
	description.componentFlags = 0;
	description.componentFlagsMask = 0;
	
	auto comp = AudioComponentFindNext(nil, &description);
	if (!comp) {
		return;
	}
	
	auto error = AudioComponentInstanceNew(comp, &mAU);
	if (error != noErr) {
		throw std::runtime_error("Failed to create an instance of HALOutput or RemoteIO [OSStatus: " + std::to_string(error) + "]");
	}
	init();
}

OutputAU::~OutputAU()
{
	if (mAU) {
		AudioComponentInstanceDispose(mAU);
	}
}

void OutputAU::init()
{
	// Initialize the audio unit interface to begin configuring it.
	auto status = AudioUnitInitialize(mAU);
	if (status != noErr) {
		throw std::runtime_error("Failed to initialize the audio unit [OSStatus: " + std::to_string(status) + "]");
	}
	
#if TARGET_OS_OSX
	constexpr AudioUnitElement outputElement{0};
	constexpr AudioUnitElement inputElement{1};
	uint32_t enableIO = 0;
	
	status =  AudioUnitSetProperty(mAU, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, inputElement, &enableIO, sizeof(enableIO));
	if (status != noErr) {
		throw std::runtime_error("Failed to disable the input on AUHAL [OSStatus: " + std::to_string(status) + "]");
	}
	
	enableIO = 1;
	status = AudioUnitSetProperty(mAU, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, outputElement, &enableIO, sizeof(enableIO));
	if (status != noErr) {
		throw std::runtime_error("Failed to enable the output on AUHAL [OSStatus: " + std::to_string(status) + "]");
	}
	
	uint32_t size = sizeof(AudioDeviceID);
	AudioObjectPropertyAddress theAddress{kAudioHardwarePropertyDefaultOutputDevice, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain};
	
	status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &theAddress, outputElement, nil, &size, &mOutputDeviceID);
	if (status != noErr) {
		throw std::runtime_error("Failed to get the default output device [OSStatus: " + std::to_string(status) + "]");
	}
	
	//Set the current device to the default output device.
	//This should be done only after I/O is enabled on the output audio unit.
	status = AudioUnitSetProperty(mAU, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, outputElement, &mOutputDeviceID, size);
	if (status != noErr) {
		throw std::runtime_error("Failed to set the default output device [OSStatus: " + std::to_string(status) + "]");
	}
	
	uint32_t bufferTypeSize = 0;
	
	AudioObjectPropertyAddress bufferFrameSizeAddress{kAudioDevicePropertyBufferFrameSize, kAudioDevicePropertyScopeOutput, kAudioObjectPropertyScopeGlobal};
	status = AudioObjectGetPropertyData(mOutputDeviceID, &bufferFrameSizeAddress, 0, nil, &bufferTypeSize, &bufferTypeSize);
	if (status != noErr) {
		throw std::runtime_error("Failed to get the device buffer size [OSStatus: " + std::to_string(status) + "]");
	}
#endif
}

AUSpatialMixerOutputType OutputAU::getSpatialMixerOutputType()
{
#if TARGET_OS_OSX
	// Check if headphones are plugged in.
	UInt32 dataSource{};
	UInt32 size = sizeof(dataSource);
	
	AudioObjectPropertyAddress addTransType{kAudioDevicePropertyTransportType};
	OSStatus status = AudioObjectGetPropertyData(mOutputDeviceID, &addTransType, 0, nullptr, &size, &dataSource);
	
	if (status != noErr) {
		throw std::runtime_error("Failed to get the transport type [OSStatus: " + std::to_string(status) + "]");
	} else if (dataSource == kAudioDeviceTransportTypeBluetooth) {
		dataSource = kIOAudioOutputPortSubTypeHeadphones;
	} else {
		AudioObjectPropertyAddress theAddress{kAudioDevicePropertyDataSource, kAudioDevicePropertyScopeOutput, kAudioObjectPropertyElementMain};
		
		status = AudioObjectGetPropertyData(mOutputDeviceID, &theAddress, 0, nullptr, &size, &dataSource);
		if (status != noErr) {
			throw std::runtime_error("Failed to get the default output device [OSStatus: " + std::to_string(status) + "]");
		}
	}
	
	switch (dataSource) {
		case kIOAudioOutputPortSubTypeInternalSpeaker:
			return kSpatialMixerOutputType_BuiltInSpeakers;
			break;
			
		case kIOAudioOutputPortSubTypeHeadphones:
			return kSpatialMixerOutputType_Headphones;
			break;
			
		case kIOAudioOutputPortSubTypeExternalSpeaker:
			return kSpatialMixerOutputType_ExternalSpeakers;
			break;
			
		default:
			return kSpatialMixerOutputType_Headphones;
			break;
	}
#else
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	
	if ([audioSession.currentRoute.outputs count] != 1) {
		return kSpatialMixerOutputType_ExternalSpeakers;
	} else {
		NSString* pType = audioSession.currentRoute.outputs.firstObject.portType;
		if ([pType isEqualToString:AVAudioSessionPortHeadphones] || [pType isEqualToString:AVAudioSessionPortBluetoothA2DP] || [pType isEqualToString:AVAudioSessionPortBluetoothLE] || [pType isEqualToString:AVAudioSessionPortBluetoothHFP]) {
			return kSpatialMixerOutputType_Headphones;
		} else if ([pType isEqualToString:AVAudioSessionPortBuiltInSpeaker]) {
			return kSpatialMixerOutputType_BuiltInSpeakers;
		} else {
			return kSpatialMixerOutputType_ExternalSpeakers;
		}
	}
#endif
}

void OutputAU::setCallback(void * context, AURenderCallback callback)
{
	AURenderCallbackStruct renderCallback{ callback, context };
	UInt32 propsize = sizeof(renderCallback);
	
	auto status = AudioUnitSetProperty(mAU,
									   kAudioUnitProperty_SetRenderCallback,
									   kAudioUnitScope_Output,
									   0,
									   &renderCallback,
									   propsize);
	if (status != noErr) {
		throw std::runtime_error("Failed to set the render callback [OSStatus: " + std::to_string(status) + "]");
	}
}

double OutputAU::getSampleRate()
{
#if TARGET_OS_OSX
	AudioStreamBasicDescription asbd = {};
	uint32_t streamFormatSize = sizeof(AudioStreamBasicDescription);
	AudioObjectPropertyAddress streamFormatAddress{kAudioDevicePropertyStreamFormat, kAudioDevicePropertyScopeOutput, kAudioObjectPropertyElementMain};
	
	const auto status = AudioObjectGetPropertyData(mOutputDeviceID,
												   &streamFormatAddress,
												   0,
												   nil,
												   &streamFormatSize,
												   &asbd);
	if (status != noErr) {
		return -1;
	}
	return asbd.mSampleRate;
#else
	Float64 outSampleRate = 0.0;
	UInt32 size = sizeof(Float64);
	const auto status = AudioUnitGetProperty(mAU,
											 kAudioUnitProperty_SampleRate,
											 kAudioUnitScope_Output,
											 0,
											 &outSampleRate,
											 &size);
	if (status != noErr) {
		return -1;
	}
	return outSampleRate;
#endif
}

// MARK: - Transport

bool OutputAU::start()
{
	return AudioOutputUnitStart(mAU) == noErr;
}

bool OutputAU::stop()
{
	return AudioOutputUnitStop(mAU) == noErr;
}
