/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Objective-C/Swift bridging header that defines CreatingMIDIDriverSampleAppUserClient, which
     implements the communication between the MIDI driver and the custom user client.
*/

#import <IOKit/IOKitLib.h>
#import <Foundation/Foundation.h>

@interface CreatingMIDIDriverSampleAppUserClient : NSObject

- (NSString*)openConnection;
- (NSString*)addPort;
- (NSString*)removePort;
- (NSString*)toggleOffline;

@end
