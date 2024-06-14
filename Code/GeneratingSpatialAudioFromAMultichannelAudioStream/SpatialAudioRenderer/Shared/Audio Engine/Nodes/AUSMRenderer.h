/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A wrapper around the spatial mixer audio unit.
*/
#ifndef AUSMRenderer_hpp
#define AUSMRenderer_hpp

#include "CoreAudioHelpers.h"

#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#include <cstdio>
#include <optional>

class AUSMRenderer
{

public:
    AUSMRenderer();
    AUSMRenderer(const AUSMRenderer& other) = delete;
    AUSMRenderer& operator=(const AUSMRenderer& other) = delete;
    ~AUSMRenderer();

    AudioUnit _Nonnull & getAU();
    
    // A function to set up the channel layout and stream format.
    OSStatus setStreamFormatAndACL(float inSampleRate, AudioChannelLayoutTag inLayoutTag, AudioUnitScope inScope, AudioUnitElement inElement);

    // A function to set the output type and determine the spatialization algorithm to use for rendering.
    OSStatus setOutputType(AUSpatialMixerOutputType outputType);
    OSStatus setupInputCallback();
    void setup(AUSpatialMixerOutputType outputType, float inInputSampleRate, float inOutputSampleRate, uint32_t inMaxFrameSize);

    void setAudioPullBlock(PullAudioBlock _Nullable block);
    void process(AudioBufferList* __nullable outputABL, const AudioTimeStamp* __nullable inTimeStamp, float inNumberFrames);

private:
    AudioUnit _Nonnull mAU;
    PullAudioBlock __nullable mInputBlock;
};

#endif /* AUSMRenderer */
