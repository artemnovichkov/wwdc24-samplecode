/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of CreatingMIDIDriverSampleAppDriverUserClient, which sets up and manages the
	 client-side communication to the MIDI driver.
*/

// The local includes.
#include "CreatingMIDIDriverSampleAppDriverUserClient.h"
#include "CreatingMIDIDriverSampleAppDriver.h"
#include "CreatingMIDIDriverSampleAppDriverKeys.h"

// The system includes.
#include <DriverKit/DriverKit.h>
#include <DriverKit/OSSharedPtr.h>
#include <MIDIDriverKit/MIDIDriverKit.h>

#define	DebugMsg(inFormat, args...)	os_log(OS_LOG_DEFAULT, "%s: " inFormat "\n", __FUNCTION__, ##args)

struct CreatingMIDIDriverSampleAppDriverUserClient_IVars
{
	OSSharedPtr<CreatingMIDIDriverSampleAppDriver> mProvider = nullptr;
};

bool CreatingMIDIDriverSampleAppDriverUserClient::init()
{
	if (!super::init()) {
		return false;
	}

	ivars = IONewZero(CreatingMIDIDriverSampleAppDriverUserClient_IVars, 1);
	if (ivars == nullptr) {
		return false;
	}

	return true;
}

void CreatingMIDIDriverSampleAppDriverUserClient::free()
{
	if (ivars != nullptr) {
		ivars->mProvider.reset();
	}
	IOSafeDeleteNULL(ivars, CreatingMIDIDriverSampleAppDriverUserClient_IVars, 1);
	super::free();
}

kern_return_t CreatingMIDIDriverSampleAppDriverUserClient::Start_Impl(IOService* provider)
{
	kern_return_t ret = kIOReturnSuccess;
	if (provider == nullptr) {
		DebugMsg("provider is null!");
		ret = kIOReturnBadArgument;
		goto Failure;
	}

	ret = Start(provider, SUPERDISPATCH);
	if (ret != kIOReturnSuccess) {
		DebugMsg("Failed to start super!");
		goto Failure;
	}

	ivars->mProvider = OSSharedPtr(OSDynamicCast(CreatingMIDIDriverSampleAppDriver, provider), OSRetain);

	return kIOReturnSuccess;

Failure:
	ivars->mProvider.reset();
	return ret;
}

kern_return_t CreatingMIDIDriverSampleAppDriverUserClient::Stop_Impl(IOService* provider)
{
	return Stop(provider, SUPERDISPATCH);
}

kern_return_t	CreatingMIDIDriverSampleAppDriverUserClient::ExternalMethod(
		uint64_t selector, IOUserClientMethodArguments* arguments,
		const IOUserClientMethodDispatch* dispatch, OSObject* target, void* reference)
{
	kern_return_t ret = kIOReturnSuccess;

	if (ivars == nullptr) {
		return kIOReturnNoResources;
	}
	if (ivars->mProvider.get() == nullptr) {
		return kIOReturnNotAttached;
	}

	switch(static_cast<CreatingMIDIDriverSampleAppDriverExternalMethod>(selector)) {
		case CreatingMIDIDriverSampleAppDriverExternalMethod_Open: {
			ret = kIOReturnSuccess;
			break;
		}

		case CreatingMIDIDriverSampleAppDriverExternalMethod_Close: {
			ret = kIOReturnSuccess;
			break;
		}

		case CreatingMIDIDriverSampleAppDriverExternalMethod_AddPort: {
			ret = ivars->mProvider->HandleAddPort();
			break;
		}

		case CreatingMIDIDriverSampleAppDriverExternalMethod_RemovePort: {
			ret = ivars->mProvider->HandleRemovePort();
			break;
		}

		case CreatingMIDIDriverSampleAppDriverExternalMethod_ToggleOffline: {
			ret = ivars->mProvider->HandleToggleOffline();
			break;
		}

		default:
			ret = super::ExternalMethod(selector, arguments, dispatch, target, reference);
	};

	return ret;
}
