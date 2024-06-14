/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A kernel that manages the real-time aspects of the audio engine.
*/
#ifndef AudioKernel_h
#define AudioKernel_h

#import "CoreAudioHelpers.h"
#import "AUSMRenderer.h"
#import "AllocatedAudioBufferList.h"

#import <AudioToolbox/AudioToolbox.h>

#include <vector>
#include <string>
#include <mutex>

class AudioKernel {
    
public:
    
    AudioKernel(AUSpatialMixerOutputType outputType, double inSampleRate, double ioSampleRate, uint32_t maxBufferSize): mOutputBuffer(2, maxBufferSize)
    {
        mAUSM.setup(outputType, inSampleRate, ioSampleRate, maxBufferSize);
    }
    
    void setAudioPullBlock(PullAudioBlock _Nullable block)
    {
        mAUSM.setAudioPullBlock(block);
    }
    
    void setOutputType(AUSpatialMixerOutputType outputType)
    {
        mAUSM.setOutputType(outputType);
    }
    
    // MARK: - Process
    
    OSStatus process(void * __nullable inRefCon,
                     AudioUnitRenderActionFlags * __nullable ioActionFlags,
                     const AudioTimeStamp * __nullable inTimeStamp,
                     UInt32                            inBusNumber,
                     UInt32                            inNumberFrames,
                     AudioBufferList * __nullable    ioData)
    {
        
        // Set the byte size with the output audio buffer list.
        for (UInt32 i = 0; i < mOutputBuffer.get()->mNumberBuffers; i++) {
            mOutputBuffer.get()->mBuffers[i].mDataByteSize = inNumberFrames * sizeof(float);
        }
        
        // Process the input frames with the audio unit spatial mixer.
        mAUSM.process(mOutputBuffer.get(), inTimeStamp, inNumberFrames);
        
        // Copy the temporary buffer to the output.
        for (UInt32 i = 0; i < mOutputBuffer.get()->mNumberBuffers; i++) {
            memcpy(ioData->mBuffers[i].mData, mOutputBuffer.get()->mBuffers[i].mData, inNumberFrames * sizeof(float));
        }
        return noErr;
    }
    
private:
    AllocatedAudioBufferList mOutputBuffer;
    AUSMRenderer mAUSM;
    
};

#endif /* AudioKernel_h */
