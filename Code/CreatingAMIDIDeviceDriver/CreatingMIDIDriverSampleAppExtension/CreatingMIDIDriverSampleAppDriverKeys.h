/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Constants and identifiers that the user client and the driver use.
*/

#ifndef CreatingMIDIDriverSampleAppDriverKeys_h
#define CreatingMIDIDriverSampleAppDriverKeys_h

#define kCreatingMIDIDriverSampleAppDriverClassName "CreatingMIDIDriverSampleAppDriver"
#define kCreatingMIDIDriverSampleAppDriverDeviceUID "CreatingMIDIDriverSampleAppDevice-UID"
#define kCreatingMIDIDriverSampleAppDriverSerialNumberKey "SerialNumber"
#define kCreatingMIDIDriverSampleAppDriverSerialNumber "123456789"

enum CreatingMIDIDriverSampleAppDriverExternalMethod
{
	CreatingMIDIDriverSampleAppDriverExternalMethod_Open,
	CreatingMIDIDriverSampleAppDriverExternalMethod_Close,
	CreatingMIDIDriverSampleAppDriverExternalMethod_AddPort,
	CreatingMIDIDriverSampleAppDriverExternalMethod_RemovePort,
	CreatingMIDIDriverSampleAppDriverExternalMethod_ToggleOffline,
};

#endif /* CreatingMIDIDriverSampleAppDriverKeys_h */
