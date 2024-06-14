/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A wrapper around the spatial mixer audio unit.
*/
#import "AUSMRenderer.h"

#define USE_MEDIA_PLAYBACK_FACTORY_PRESET 1

AUSMRenderer::AUSMRenderer()
{
    AudioComponentDescription auDescription = {kAudioUnitType_Mixer,
                                               kAudioUnitSubType_SpatialMixer,
                                               kAudioUnitManufacturer_Apple,
                                               0,
                                               0};
    AudioComponent comp = AudioComponentFindNext(NULL, &auDescription);
    assert(comp);
    
    OSStatus err = AudioComponentInstanceNew(comp, &mAU);
    assert(err == noErr);
}

AUSMRenderer::~AUSMRenderer()
{
    if (mAU) {
        AudioComponentInstanceDispose(mAU);
    }
}

AudioUnit _Nonnull & AUSMRenderer::getAU()
{
    return mAU;
}

OSStatus AUSMRenderer::setStreamFormatAndACL(float inSampleRate,
                                             AudioChannelLayoutTag inLayoutTag,
                                             AudioUnitScope inScope,
                                             AudioUnitElement inElement)
{
    OSStatus err = noErr;
    
    AVAudioChannelLayout* layout = [AVAudioChannelLayout layoutWithLayoutTag:inLayoutTag];
    AVAudioFormat *format = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                             sampleRate:inSampleRate
                                                            interleaved:NO
                                                          channelLayout:layout];
    
    // Configure the stream format.
    const AudioStreamBasicDescription* asbd = [format streamDescription];
    err = AudioUnitSetProperty(mAU,
                               kAudioUnitProperty_StreamFormat,
                               inScope,
                               inElement,
                               asbd,
                               sizeof(AudioStreamBasicDescription));
    if(err) {
        return err;
    }
    
    // Configure the channel layout.
    const AudioChannelLayout* outLayout = [layout layout];
    err = AudioUnitSetProperty(mAU,
                               kAudioUnitProperty_AudioChannelLayout,
                               inScope,
                               inElement,
                               outLayout,
                               sizeof(AudioChannelLayout));
    
    return err;
}

// Set the output type to determine what spatialization algorithm to use for rendering.
OSStatus AUSMRenderer::setOutputType(AUSpatialMixerOutputType outputType)
{
    OSStatus err = AudioUnitSetProperty(mAU,
                                        kAudioUnitProperty_SpatialMixerOutputType,
                                        kAudioUnitScope_Global,
                                        0,
                                        &outputType,
                                        sizeof(outputType));
    return err;
}

OSStatus AUSMRenderer::setupInputCallback()
{
    AURenderCallbackStruct renderCallback{ [] (void *                            inRefCon,
                                               AudioUnitRenderActionFlags *    ioActionFlags,
                                               const AudioTimeStamp *            inTimeStamp,
                                               UInt32                            inBusNumber,
                                               UInt32                            inNumberFrames,
                                               AudioBufferList * __nullable    ioData) {
        auto rendering = static_cast<AUSMRenderer *>(inRefCon);
        
        // Clear the buffer.
        for (uint32_t i = 0; i<ioData->mNumberBuffers; i++) {
            memset((float *)ioData->mBuffers[i].mData, 0, inNumberFrames * sizeof(float));
        }
        
        // Pull audio from the spatial mixer render callback. The number of input
        // samples to pull is unknown prior to this point.
        rendering->mInputBlock(ioData, inNumberFrames);
        (*ioActionFlags) = kAudioOfflineUnitRenderAction_Complete;
        return (int)noErr;
    }, this };
    UInt32 propsize = sizeof(renderCallback);
    
    auto status = AudioUnitSetProperty(getAU(),
                                       kAudioUnitProperty_SetRenderCallback,
                                       kAudioUnitScope_Input,
                                       0,
                                       &renderCallback,
                                       propsize);
    return status;
}

void AUSMRenderer::setup(AUSpatialMixerOutputType outputType, float inInputSampleRate, float inOutputSampleRate, uint32_t inMaxFrameSize)
{
    OSStatus err = noErr;
    
    // Set the number of input elements (buses).
    UInt32 numInputs = 1;
    err = AudioUnitSetProperty(getAU(), kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &numInputs, sizeof(numInputs));
    assert(err == noErr);
    
    // Set up the output stream format and channel layout for stereo.
    err = setStreamFormatAndACL(inOutputSampleRate, kAudioChannelLayoutTag_Stereo, kAudioUnitScope_Output, 0);
    assert(err == noErr);
    
    // Set up the input elements (buses). The sample app only uses one active bus.
    for (uint32_t elem = 0; elem < numInputs; elem++) {
        switch (elem) {
            case 0:
            {
                // Setup the input stream format and channel layout for ATMOS 7.1.4
                err = setStreamFormatAndACL(inInputSampleRate,
                                            kAudioChannelLayoutTag_Atmos_7_1_4,
                                            kAudioUnitScope_Input,
                                            elem);
                assert(err == noErr);
                
                // Set the rendering algorithm.
                UInt32 renderingAlgorithm = kSpatializationAlgorithm_UseOutputType;
                err = AudioUnitSetProperty(mAU,
                                           kAudioUnitProperty_SpatializationAlgorithm,
                                           kAudioUnitScope_Input,
                                           elem,
                                           &renderingAlgorithm,
                                           sizeof(renderingAlgorithm));
                assert(err == noErr);
                
                // Set the source mode.
                UInt32 sourceMode = kSpatialMixerSourceMode_AmbienceBed;
                err = AudioUnitSetProperty(mAU, kAudioUnitProperty_SpatialMixerSourceMode, kAudioUnitScope_Input, elem, &sourceMode, sizeof(sourceMode));
                assert(err == noErr);
            }
                break;
            default:
                // The sample app only supports a single element.
                assert(false);
        }
    }
    
    // Set up the output type to adapt the rendering depending on the physical output.
    // The unit renders binaural for headphones, Apple-proprietary for built-in
    // speakers, or multichannel for external speakers.
    err = setOutputType(outputType);
    assert(err == noErr);
    
    if (outputType == kSpatialMixerOutputType_Headphones) {

#if !TARGET_OS_SIMULATOR && (TARGET_OS_OSX || TARGET_OS_IOS || TARGET_OS_TV)
        
#if TARGET_OS_IOS
        if (@available(iOS 18.0, *))
#elif TARGET_OS_TV
        if (@available(tvOS 18.0, *))
#endif
        {
            // For devices that support it, enable head-tracking.
            // Apps that use low-latency head-tracking in iOS/tvOS need to set
            // the audio session category to ambient or run in Game Mode.
            // Head tracking requires the entitlement com.apple.developer.coremotion.head-pose.
            UInt32 ht = 1;
            err = AudioUnitSetProperty(mAU,
                                       kAudioUnitProperty_SpatialMixerEnableHeadTracking,
                                       kAudioUnitScope_Global,
                                       0,
                                       &ht,
                                       sizeof(UInt32));
            assert(err == noErr);
            
            // For devices that support it, enable personalized head-related transfer function (HRTF).
            // HRTF requires the entitlement com.apple.developer.spatial-audio.profile-access.
            //
            // This is an opportunistic API, so if personalized HRTF isn't available, the
            // system falls back to generic HRTF. A host can query active HRTF genre (personalized vs generic)
            // after the AU is initialized by using kAudioUnitProperty_SpatialMixerAnyInputIsUsingPersonalizedHRTF.
            UInt32 hrtf = kSpatialMixerPersonalizedHRTFMode_Auto;
            err = AudioUnitSetProperty(mAU,
                                       kAudioUnitProperty_SpatialMixerPersonalizedHRTFMode,
                                       kAudioUnitScope_Global,
                                       0,
                                       &hrtf,
                                       sizeof(UInt32));
            assert(err == noErr);
        }
        
#endif // !TARGET_OS_SIMULATOR && (TARGET_OS_OSX || TARGET_OS_IOS || TARGET_OS_TV)
        
    }
    
#if USE_MEDIA_PLAYBACK_FACTORY_PRESET
    
#if TARGET_OS_IOS
    if (@available(iOS 18.0, *))
#elif TARGET_OS_TV
    if (@available(tvOS 18.0, *))
#endif
    {
        // Set a factory preset to use with media playback on an Apple device.
        // This can override previously set properties. Check the available
        // presets by using `auval` command. For example, `auval -v aumx 3dem appl`
        // may list the following presets:
        //
        // ID:   0    Name: Built-In Speaker Media Playback
        // ID:   1    Name: Headphone Media Playback Default
        // ID:   2    Name: Headphone Media Playback Movie
        
        // Load the preset with the identifier 1.
        AUPreset preset {1, NULL };
        err = AudioUnitSetProperty(mAU, kAudioUnitProperty_PresentPreset, kAudioUnitScope_Global, 0, &preset, sizeof(AUPreset));
    }
    
#else
    
    // Enable a reverb effect.
    UInt32 enableReverb = 1;
    err = AudioUnitSetProperty(getAU(), kAudioUnitProperty_UsesInternalReverb, kAudioUnitScope_Global, 0, &enableReverb, sizeof(enableReverb));
    assert(err == noErr);
    
    // Select the reverb room type to use if no factory preset is set.
    UInt32 roomType = kReverbRoomType_MediumHall;
    err = AudioUnitSetProperty(getAU(), kAudioUnitProperty_ReverbRoomType, kAudioUnitScope_Global, 0, &roomType, sizeof(roomType));
    assert(err == noErr);
    
#endif // USE_MEDIA_PLAYBACK_FACTORY_PRESET
    
    // Set the maximum frames.
    err = AudioUnitSetProperty(mAU, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &inMaxFrameSize , sizeof(inMaxFrameSize));
    assert(err == noErr);
    
    // Set up the render callback.
    err = setupInputCallback();
    assert(err == noErr);
    
    // Initialize the audio unit.
    err = AudioUnitInitialize(mAU);
    assert(err == noErr);
}

void AUSMRenderer::setAudioPullBlock(PullAudioBlock _Nullable block)
{
    mInputBlock = block;
}

void AUSMRenderer::process(AudioBufferList* __nullable outputABL, const AudioTimeStamp* __nullable inTimeStamp, float inNumberFrames)
{
    // Process the audio unit spatial mixer.
    AudioUnitRenderActionFlags  actionFlags = {};
    auto err = AudioUnitRender(mAU, &actionFlags, inTimeStamp, 0, inNumberFrames, outputABL);
    assert(err == noErr);
}
