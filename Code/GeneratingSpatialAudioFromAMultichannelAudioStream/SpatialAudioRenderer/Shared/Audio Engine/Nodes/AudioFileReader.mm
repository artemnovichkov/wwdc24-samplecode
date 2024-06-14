/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that implements loading a small audio file into memory.
*/
#import "AudioFileReader.h"

inline void copyBufferList(AudioBufferList * __nullable dstBufferList,
						   const AudioBufferList * __nullable srcBufferList,
						   UInt32 inNumberFrames,
						   size_t offset)
{
	if (srcBufferList->mNumberBuffers != dstBufferList->mNumberBuffers) return;

	const AudioBuffer* src = srcBufferList->mBuffers;
	AudioBuffer* dst = dstBufferList->mBuffers;
	
	const auto requiredByteSz = sizeof(float) * inNumberFrames;
	for (UInt32 i = 0; i < srcBufferList->mNumberBuffers; ++i) {
		if (src[i].mDataByteSize < requiredByteSz && dst[i].mDataByteSize < requiredByteSz) continue;

		memcpy(dst[i].mData, static_cast<const float *>(src[i].mData) + offset, sizeof(float) * inNumberFrames);
	}
}

struct RealtimeInfo {
    NSInteger fileLength{0};
    NSInteger currentPos{0};
    double sampleRate {0.0};
    AVAudioPCMBuffer* buffer {nil};
    const AudioBufferList* bufferList {nullptr};
};

@implementation AudioFileReader {
    RealtimeInfo realtimeInfo;
}

- (instancetype)init:(NSString *)fileUrl
{
    self = [super init];
    if (self) {
        [self loadFile:fileUrl];
        
        auto rtInfo = &realtimeInfo;
        _pullAudioBlock = ^(AudioBufferList * __nullable dstBufferList, size_t bufferSize) {
            copyBufferList(dstBufferList, rtInfo->bufferList, (UInt32)bufferSize, rtInfo->currentPos);
            (rtInfo->currentPos) += bufferSize;
            if (rtInfo->currentPos >= rtInfo->fileLength) {
                rtInfo->currentPos = 0;
            }
        };
    }
    return self;
}

-(BOOL)loadFile:(NSString *)filePath
{
    NSError * error = nil;
    AVAudioFile * _audioFile  = [[AVAudioFile new] initForReading:[NSURL fileURLWithPath:filePath] error:&error];
    if (error != nil) {
        return NO;
    }
	
	NSAssert(_audioFile.processingFormat.channelCount == 12, @"[Error] This sample requires 7.1.4, 12 channel audio..");
    realtimeInfo.fileLength = _audioFile.length;
    realtimeInfo.sampleRate = _audioFile.processingFormat.sampleRate;
    realtimeInfo.buffer = [[AVAudioPCMBuffer new] initWithPCMFormat:_audioFile.processingFormat
                                                      frameCapacity:(AVAudioFrameCount)_audioFile.length];
    realtimeInfo.bufferList = realtimeInfo.buffer.audioBufferList;
    
    [_audioFile readIntoBuffer:realtimeInfo.buffer
                    frameCount:AVAudioFrameCount(_audioFile.length)
                         error:&error];
    return error == nil;
}

-(double)sampleRate
{
    return realtimeInfo.sampleRate;
}

@end
