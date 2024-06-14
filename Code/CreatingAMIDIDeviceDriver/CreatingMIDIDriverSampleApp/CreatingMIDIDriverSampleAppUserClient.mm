/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of CreatingMIDIDriverSampleAppUserClient, which manages the communication
     between the MIDI driver and the custom user client.
*/

#import "CreatingMIDIDriverSampleAppUserClient.h"
#import "CreatingMIDIDriverSampleAppDriverKeys.h"

@interface CreatingMIDIDriverSampleAppUserClient()
@property io_object_t ioObject;
@property io_connect_t ioConnection;
@end

@implementation CreatingMIDIDriverSampleAppUserClient

- (void)dealloc
{
	if (_ioConnection)
		IOConnectRelease(_ioConnection);
}

// Open a user client instance, which initiates communication with the driver.
- (NSString*)openConnection
{
	if (_ioObject == IO_OBJECT_NULL && _ioConnection == IO_OBJECT_NULL)
	{
		// Get the IOKit main port.
		mach_port_t theMainPort = MACH_PORT_NULL;
		kern_return_t theKernelError = IOMainPort(bootstrap_port, &theMainPort);
		if (theKernelError != kIOReturnSuccess) {
			return @"Failed to get IOMainPort.";
		}

		// Create a matching dictionary for the driver class.
		// Note that classes you publish by a dext need to match by class name
		// (for example, use `IOServiceNameMatching` to construct the
		// matching dictionary, not `IOServiceMatching`).
		CFDictionaryRef theMatchingDictionary = IOServiceNameMatching(kCreatingMIDIDriverSampleAppDriverClassName);
		io_service_t matchedService = IOServiceGetMatchingService(theMainPort, theMatchingDictionary);
		if (matchedService) {
			_ioObject = matchedService;
			theKernelError = IOServiceOpen(_ioObject, mach_task_self(), 0, &_ioConnection);
			if (theKernelError == kIOReturnSuccess) {
				return @"Connection to user client succeeded";
			}
			else {
				_ioObject = IO_OBJECT_NULL;
				_ioConnection = IO_OBJECT_NULL;
				return [NSString stringWithFormat:@"Failed to open user client connection, error:%u.", theKernelError];
			}
		}
		return @"Driver Extension is not running";
	}
	return @"User client is already connected";
}

- (NSString*)addPort
{
	if (_ioConnection == IO_OBJECT_NULL) {
		return @"Can't toggle the data source because the user client isn't connected.";
	}

	// Call the custom user client method to toggle the add-port property on the driver extension.
	// This results in CoreMIDI updating the device property, and listeners (such
	// as Audio MIDI Setup) receive a properties changed notification.
	kern_return_t error =
		IOConnectCallMethod(_ioConnection,
							static_cast<uint64_t>(CreatingMIDIDriverSampleAppDriverExternalMethod_AddPort),
							nullptr, 0, nullptr, 0, nullptr, nullptr, nullptr, 0);

	if (error != kIOReturnSuccess) {
		return [NSString stringWithFormat:@"Failed to add port, error:%u.", error];
	}

	return @"Successfully added a port";
}

- (NSString*)removePort
{
	if (_ioConnection == IO_OBJECT_NULL) {
		return @"Can't toggle the data source because the user client isn't connected.";
	}

	// Call the custom user client method to toggle the remove-port property on the driver extension.
	// This results in CoreMIDI updating the device property, and listeners (such
	// as Audio MIDI Setup) receive a properties changed notification.
	kern_return_t error =
		IOConnectCallMethod(_ioConnection,
							static_cast<uint64_t>(CreatingMIDIDriverSampleAppDriverExternalMethod_RemovePort),
							nullptr, 0, nullptr, 0, nullptr, nullptr, nullptr, 0);
	if (error != kIOReturnSuccess) {
		return [NSString stringWithFormat:@"Failed to remove port, error:%u.", error];
	}

	return @"Successfully removed a port";
}

// Instructs the user client to toggle the device's offline property.
- (NSString*)toggleOffline
{
	if (_ioConnection == IO_OBJECT_NULL) {
		return @"Can't toggle the data source because the user client isn't connected.";
	}

	// Call the custom user client method to toggle the offline property on the driver extension.
	// This results in CoreMIDI updating the device property, and listeners (such
	// as Audio MIDI Setup) receive a properties changed notification.
	kern_return_t error =
		IOConnectCallMethod(_ioConnection,
							static_cast<uint64_t>(CreatingMIDIDriverSampleAppDriverExternalMethod_ToggleOffline),
							nullptr, 0, nullptr, 0, nullptr, nullptr, nullptr, 0);
	if (error != kIOReturnSuccess) {
		return [NSString stringWithFormat:@"Failed to toggle data source, error:%u.", error];
	}

	return @"Successfully toggled the device offline state";
}

@end
