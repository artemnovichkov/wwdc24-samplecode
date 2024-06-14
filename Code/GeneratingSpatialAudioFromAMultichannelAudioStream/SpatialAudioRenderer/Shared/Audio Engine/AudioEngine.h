/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An audio engine that contains audio units.
*/
#import "AudioFileReader.h"

NS_ASSUME_NONNULL_BEGIN

@interface AudioEngine : NSObject

@property (readonly) AudioFileReader * __nullable fileReader;

+(NSArray<NSString *> *)audioSamples;
-(BOOL)loadAudio:(NSString *)filePath;
-(void)handleRouteChange:(NSNotification *)notification;

@end

NS_ASSUME_NONNULL_END
