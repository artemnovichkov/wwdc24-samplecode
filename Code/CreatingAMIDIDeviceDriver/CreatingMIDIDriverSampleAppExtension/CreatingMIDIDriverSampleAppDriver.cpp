/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of CreatingMIDIDriverSampleAppDriver, which sets up and manages
     the communications between user clients and the MIDI device.
*/

#include <os/log.h>
#include <utility>

#include <DriverKit/DriverKit.h>
#include <DriverKit/OSSharedPtr.h>

#include <MIDIDriverKit/MIDIDriverKit.h>

#include "CreatingMIDIDriverSampleAppDriver.h"
#include "CreatingMIDIDriverSampleAppDevice.h"
#include "CreatingMIDIDriverSampleAppDriverKeys.h"

#define	DebugMsg(inFormat, args...)	\
	os_log(OS_LOG_DEFAULT, "%s: " inFormat "\n", __FUNCTION__, ##args)

struct CreatingMIDIDriverSampleAppDriver_IVars
{
	OSSharedPtr<IODispatchQueue> mWorkQueue;
	OSSharedPtr<CreatingMIDIDriverSampleAppDevice> mCreatingMIDIDriverSampleAppDevice;
};

bool CreatingMIDIDriverSampleAppDriver::init()
{
	DebugMsg("+");
	auto answer = super::init();
	if (!answer) {
		return false;
	}
	ivars = IONewZero(CreatingMIDIDriverSampleAppDriver_IVars, 1);
	if (ivars == nullptr) {
		return false;
	}

	return true;
}

void CreatingMIDIDriverSampleAppDriver::free()
{
	DebugMsg("+");
	if (ivars != nullptr) {
		ivars->mWorkQueue.reset();
		ivars->mCreatingMIDIDriverSampleAppDevice.reset();
	}
	IOSafeDeleteNULL(ivars, CreatingMIDIDriverSampleAppDriver_IVars, 1);
	super::free();
}

kern_return_t IMPL(CreatingMIDIDriverSampleAppDriver, Start)
{
	DebugMsg("+");
	bool success = true;

	OSSharedPtr<OSString> deviceName(OSString::withCString("CreatingMIDIDriverSampleAppDevice"), OSNoRetain);
	OSSharedPtr<OSString> modelUID(OSString::withCString("CreatingMIDIDriverSampleAppDevice-Model"), OSNoRetain);
	OSSharedPtr<OSString> manufacturerUID(OSString::withCString("Apple Inc."), OSNoRetain);

	kern_return_t error = Start(provider, SUPERDISPATCH);
	if (error)
	{
		DebugMsg("Failed to start Super");
		goto Failure;
	}

	// Get the service's default dispatch queue from the driver object.
	ivars->mWorkQueue = GetWorkQueue();
	if (ivars->mWorkQueue.get() == nullptr)
	{
		DebugMsg("Failed to get default work queue");
		error = kIOReturnInvalid;
		goto Failure;
	}

	ivars->mCreatingMIDIDriverSampleAppDevice = OSSharedPtr(OSTypeAlloc(CreatingMIDIDriverSampleAppDevice), OSNoRetain);
	if (ivars->mCreatingMIDIDriverSampleAppDevice.get() == nullptr)
	{
		DebugMsg("Failed to allocate CreatingMIDIDriverSampleAppDevice");
		error = kIOReturnNoMemory;
		goto Failure;
	}

	success = ivars->mCreatingMIDIDriverSampleAppDevice->init(this, deviceName.get(), modelUID.get(), manufacturerUID.get());
	if (!success)
	{
		DebugMsg("Failed to init CreatingMIDIDriverSampleAppDevice");
		error = kIOReturnNoMemory;
		goto Failure;
	}

	AddObject(ivars->mCreatingMIDIDriverSampleAppDevice.get());

	// Register the service.
	error = RegisterService();
	if (error)
	{
		DebugMsg("Failed to register service");
		goto Failure;
	}

	return kIOReturnSuccess;

Failure:

	ivars->mCreatingMIDIDriverSampleAppDevice.reset();
	return error;
}

kern_return_t IMPL(CreatingMIDIDriverSampleAppDriver, Stop)
{
	auto ret = Stop(provider, SUPERDISPATCH);
	ivars->mWorkQueue.reset();
	ivars->mCreatingMIDIDriverSampleAppDevice.reset();
	return ret;
}

kern_return_t IMPL(CreatingMIDIDriverSampleAppDriver, NewUserClient)
{
	DebugMsg("type: %u out_user-client: %p", type, userClient);
	kern_return_t error = kIOReturnSuccess;

	//	Have the superclass create the `IOUserMIDIDriverUserClient` object if the type is
	//	kIOUserMIDIDriverUserClientType.
	if (type == kIOUserMIDIDriverUserClientType)
	{
		error = super::NewUserClient(type, userClient, SUPERDISPATCH);
		if (error)
		{
			DebugMsg("Failed to create user client");
			goto Failure;
		}
		if (*userClient == nullptr)
		{
			DebugMsg("Failed to create user client");
			error = kIOReturnNoMemory;
			goto Failure;
		}
	}
	else
	{
		IOService* userClientService = nullptr;
		error = Create(this, "CreatingMIDIDriverSampleAppUserClientProperties", &userClientService);
		if (error != kIOReturnSuccess)
		{
			DebugMsg("failed to create the CreatingMIDIDriverSampleAppDriver user-client");
			goto Failure;

		}
		*userClient = OSDynamicCast(IOUserClient, userClientService);

	}

Failure:
	return error;
}

kern_return_t CreatingMIDIDriverSampleAppDriver::StartIO(OSArray* deviceList)
{
	kern_return_t error = super::StartIO(deviceList);
	if (error != kIOReturnSuccess)
	{
		return error;
	}

	return ivars->mCreatingMIDIDriverSampleAppDevice->StartIO();
}

kern_return_t CreatingMIDIDriverSampleAppDriver::StopIO()
{
	if (ivars->mCreatingMIDIDriverSampleAppDevice.get() != nullptr)
	{
		ivars->mCreatingMIDIDriverSampleAppDevice->StopIO();
		super::StopIO();
	}
	return kIOReturnSuccess;
}


kern_return_t CreatingMIDIDriverSampleAppDriver::HandleAddPort()
{
	__block kern_return_t ret = kIOReturnSuccess;
	ivars->mWorkQueue->DispatchSync(^{
		ret = ivars->mCreatingMIDIDriverSampleAppDevice->AddPort();
	});
	return ret;
}

kern_return_t CreatingMIDIDriverSampleAppDriver::HandleRemovePort()
{
	__block kern_return_t ret = kIOReturnSuccess;
	ivars->mWorkQueue->DispatchSync(^{
		ret = ivars->mCreatingMIDIDriverSampleAppDevice->RemovePort();
	});
	return ret;
}

kern_return_t CreatingMIDIDriverSampleAppDriver::HandleToggleOffline()
{
	__block kern_return_t ret = kIOReturnSuccess;
	ivars->mWorkQueue->DispatchSync(^{
		ret = ivars->mCreatingMIDIDriverSampleAppDevice->ToggleOffline();
	});
	return ret;
}
