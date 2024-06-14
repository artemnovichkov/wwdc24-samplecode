/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that loads a small audio file into memory.
*/
#import "CoreAudioHelpers.h"

#import <Foundation/Foundation.h>
#import <AVFAudio/AVFAudio.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioFileReader : NSObject

- (instancetype)init:(NSString *)filePath;

@property (nonatomic, readonly) double sampleRate;
@property (nonatomic, copy) PullAudioBlock pullAudioBlock;

@end

NS_ASSUME_NONNULL_END
