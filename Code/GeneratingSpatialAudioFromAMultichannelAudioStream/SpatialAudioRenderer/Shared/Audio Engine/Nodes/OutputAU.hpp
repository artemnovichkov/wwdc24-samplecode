/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that wraps a system I/O audio unit.
*/
#ifndef OutputAU_hpp
#define OutputAU_hpp

#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>

#include <cstdio>
#include <optional>

class OutputAU
{

public:
    OutputAU();
    OutputAU(const OutputAU&) = delete;
    OutputAU& operator=(const OutputAU&) = delete;
    ~OutputAU();
    
    void init();
    AUSpatialMixerOutputType getSpatialMixerOutputType();
    
    void setCallback(void * context, AURenderCallback callback);
    double getSampleRate();
    
    bool start();
    bool stop();
    
private:    
    AudioComponentInstance mAU{nullptr};
#if TARGET_OS_OSX
    AudioDeviceID mOutputDeviceID{};
#endif
};
#endif /* OutputAU_hpp */
