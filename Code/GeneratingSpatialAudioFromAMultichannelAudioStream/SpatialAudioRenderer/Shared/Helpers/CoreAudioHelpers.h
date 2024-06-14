/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Core audio helper functions.
*/
#ifndef CoreAudioHelpers_h
#define CoreAudioHelpers_h

#import <AudioToolbox/AudioToolbox.h>

typedef void (^PullAudioBlock)(AudioBufferList * __nullable, size_t bufferSize);

#endif /* CoreAudioHelpers_h */
