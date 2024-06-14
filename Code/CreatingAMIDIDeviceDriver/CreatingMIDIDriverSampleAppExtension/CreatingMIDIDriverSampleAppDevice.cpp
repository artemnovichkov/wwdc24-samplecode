/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of CreatingMIDIDriverSampleAppDevice, a MIDIDriverKit device that does
     a basic MIDI roundtrip, copying data from the input port to the output port.
*/

#include <MIDIDriverKit/MIDIDriverKit.h>

#include "CreatingMIDIDriverSampleAppDevice.h"
#include "CreatingMIDIDriverSampleAppDriver.h"
#include "CreatingMIDIDriverSampleAppDriverKeys.h"

#include <cstdio>

#define	DebugMsg(inFormat, args...)	\
	os_log(OS_LOG_DEFAULT, "%s: " inFormat "\n", __FUNCTION__, ##args)

static OSSharedPtr<OSString> CreateEntityName(uint32_t index)
{
	char key[64];
	snprintf(key, 32, "Virtual Bus %u", index);
	return OSSharedPtr(OSString::withCString(key), OSNoRetain);
}

struct CreatingMIDIDriverSampleAppDevice_IVars
{
	OSSharedPtr<IOUserMIDIDriver> mDriver;
	OSSharedPtr<IODispatchQueue> mWorkQueue;

	OSSharedPtr<OSArray> mDestinations;
};


// A typical UMP-native device has a single UMP endpoint
// consisting of a UMP-native source and a UMP-native destination.
bool CreatingMIDIDriverSampleAppDevice::init(
		IOUserMIDIDriver* driver, OSString* name,
		OSString* model, OSString* manufacturer)
{
	auto offline = OSSharedPtr(OSNumber::withNumber("0", 32), OSNoRetain);

	auto success = super::init(driver, name, model, manufacturer);
	if (!success) {
		return false;
	}

	ivars = IONewZero(CreatingMIDIDriverSampleAppDevice_IVars, 1);
	if (ivars == nullptr) {
		return false;
	}

	ivars->mDriver = OSSharedPtr(driver, OSRetain);
	ivars->mWorkQueue = GetWorkQueue();

	auto entityName = CreateEntityName(1);
	auto entity = IOUserMIDIEntity::Create(
					driver, this, entityName.get(),
					IOUserMIDIProtocolID::MIDIProtocol_2_0, 1, 1);
	AddEntity(entity.get());

	SetupEntities();

	SetProperty(IOUserMIDIProperty::Offline, offline.get());

	return true;
}

void CreatingMIDIDriverSampleAppDevice::free()
{
	if (ivars != nullptr) {
		ivars->mDriver.reset();
		ivars->mWorkQueue.reset();
	}
	IOSafeDeleteNULL(ivars, CreatingMIDIDriverSampleAppDevice_IVars, 1);
	super::free();
}


kern_return_t CreatingMIDIDriverSampleAppDevice::StartIO()
{
	DebugMsg("StartIO: device %u", GetObjectID());

	__block kern_return_t error = kIOReturnSuccess;

	ivars->mWorkQueue->DispatchSync(^{
		// Tell `IOUserMIDIObject` base class to start I/O for the device.
		error = super::StartIO();
		if (error) {
			DebugMsg("Failed to start I/O, error %d", error);
			super::StopIO();
		}
	});

	if (error == kIOReturnSuccess) {
		auto offline = OSSharedPtr(OSNumber::withNumber(uint64_t{0}, 32), OSNoRetain);
		SetProperty(IOUserMIDIProperty::Offline, offline.get());
	}
		
	return error;
}

kern_return_t CreatingMIDIDriverSampleAppDevice::StopIO()
{
	DebugMsg("StopIO: device %u", GetObjectID());

	__block kern_return_t error;

	ivars->mWorkQueue->DispatchSync(^{
		error = super::StopIO();
	});


	if (error != kIOReturnSuccess) {
		DebugMsg("Failed to stop I/O, error %d", error);
	}

	return error;
}

void CreatingMIDIDriverSampleAppDevice::SetupEntities()
{
	ivars->mDestinations = OSSharedPtr(OSArray::withCapacity(1), OSNoRetain);

	GetEntities()->iterateObjects(^bool(OSObject* object){
		auto entity = OSDynamicCast(IOUserMIDIEntity, object);
		if (entity != nullptr)
		{
			auto source = entity->GetSource(0);
			auto destination = entity->GetDestination(0);
			auto ioBlock = ^kern_return_t(IOUserMIDIUMPWord const* umpWords, size_t numWords) {
				return source->Send(umpWords, numWords);
			};
			destination->SetIOBlock(ioBlock);
		}
		return false;
	});
}

kern_return_t CreatingMIDIDriverSampleAppDevice::PerformDeviceConfigurationChange(
		uint64_t changeAction, OSObject* changeInfo)
{
	DebugMsg("change action %llu", changeAction);
	kern_return_t ret = kIOReturnSuccess;
	switch (changeAction) {
		// Add custom config change handlers.
		case kAddPortConfigChangeAction: {
			if (changeInfo) {
				auto changeInfoString = OSDynamicCast(OSString, changeInfo);
				DebugMsg("%s", changeInfoString->getCStringNoCopy());
			}
			auto entities = GetEntities();
			if (entities.get() != nullptr) {
				auto index = entities->getCount() + 1;
				auto entityName = CreateEntityName(index);
				auto entity = IOUserMIDIEntity::Create(ivars->mDriver.get(),
													   this,
													   entityName.get(),
													   IOUserMIDIProtocolID::MIDIProtocol_2_0,
													   1, 1);
				AddEntity(entity.get());
				SetupEntities();
			}
			break;
		}

		case kRemovePortConfigChangeAction: {
			if (changeInfo) {
				auto changeInfoString = OSDynamicCast(OSString, changeInfo);
				DebugMsg("%s", changeInfoString->getCStringNoCopy());
			}

			auto entities = GetEntities();
			if (entities.get() != nullptr) {
				auto count = entities->getCount();
				if (count > 1) {
					const auto index = count - 1;
					auto object = entities->getObject(index);
					auto entity = OSDynamicCast(IOUserMIDIEntity, object);
					if (entity != nullptr) {
						RemoveEntity(entity);
					}
				} else {
					ret = kIOReturnError;
				}
			}
			break;
		}

		default:
			ret = super::PerformDeviceConfigurationChange(changeAction, changeInfo);
			break;
	}
	return ret;
}

kern_return_t CreatingMIDIDriverSampleAppDevice::AbortDeviceConfigurationChange(
		uint64_t changeAction, OSObject* changeInfo)
{
	// Handle aborted configuration changes as necessary.
	return super::AbortDeviceConfigurationChange(changeAction, changeInfo);
}

kern_return_t CreatingMIDIDriverSampleAppDevice::AddPort()
{
	auto changeInfo = OSSharedPtr(OSString::withCString("Add Port"), OSNoRetain);
	if (GetDeviceIsRunning()) {
		return RequestDeviceConfigurationChange(kAddPortConfigChangeAction, changeInfo.get());
	}
	else {
		return PerformDeviceConfigurationChange(kAddPortConfigChangeAction, changeInfo.get());
	}
}
kern_return_t CreatingMIDIDriverSampleAppDevice::RemovePort()
{
	auto changeInfo = OSSharedPtr(OSString::withCString("Remove Port"), OSNoRetain);
	if (GetDeviceIsRunning()) {
		return RequestDeviceConfigurationChange(kRemovePortConfigChangeAction, changeInfo.get());
	}
	else {
		return PerformDeviceConfigurationChange(kRemovePortConfigChangeAction, changeInfo.get());
	}
}

kern_return_t CreatingMIDIDriverSampleAppDevice::ToggleOffline()
{
	OSSharedPtr<OSObject> object;
	auto ret = CopyProperty(IOUserMIDIProperty::Offline, object.attach());
	if (ret != kIOReturnSuccess || object.get() == nullptr) {
		return ret;
	}

	auto currentOffline = OSDynamicCast(OSNumber, object.get());
	uint64_t offlineValue =
		(currentOffline == nullptr || currentOffline->unsigned32BitValue() != 0) ? 0 : 1;
	auto offline = OSSharedPtr(OSNumber::withNumber(offlineValue, 32), OSNoRetain);
	return SetProperty(IOUserMIDIProperty::Offline, offline.get());
}
