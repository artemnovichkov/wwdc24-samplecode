/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An audio engine implementation that contains audio units.
*/
#import "AudioEngine.h"
#import "AudioKernel.h"
#import "OutputAU.hpp"

#define kMaxBlockSize 4096

@implementation AudioEngine
{
    std::unique_ptr<AudioKernel> kernel;
    OutputAU outputAU;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        
        [self loadAudio:[AudioEngine.audioSamples objectAtIndex:0]];
        
#if TARGET_OS_OSX
        // Handle a macOS route change.
#else
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleRouteChange:) name:AVAudioSessionRouteChangeNotification
                                                   object:nil];
#endif
    }
    return self;
}

+(NSArray<NSString *> *)audioSamples
{
    return [[NSBundle mainBundle] pathsForResourcesOfType:@"wav" inDirectory:nil];
}

-(BOOL)loadAudio:(NSString *)filePath
{
    outputAU.stop();
    
    _fileReader = [[AudioFileReader alloc] init:filePath];
    
    auto outputType = outputAU.getSpatialMixerOutputType();
    kernel = std::make_unique<AudioKernel>(outputType, _fileReader.sampleRate, outputAU.getSampleRate(), kMaxBlockSize);
    kernel->setAudioPullBlock(_fileReader.pullAudioBlock);
    
    outputAU.setCallback(kernel.get(), [] (void * __nullable inRefCon,
                                           AudioUnitRenderActionFlags * __nullable ioActionFlags,
                                           const AudioTimeStamp * __nullable inTimeStamp,
                                           UInt32                            inBusNumber,
                                           UInt32                            inNumberFrames,
                                           AudioBufferList * __nullable    ioData) {
        return static_cast<AudioKernel *>(inRefCon)->process(inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData);
    });
    
    outputAU.start();
    return YES;
}

-(void)handleRouteChange:(NSNotification *)notification
{
    if (kernel) {
        kernel->setOutputType(outputAU.getSpatialMixerOutputType());
    }
}

@end
