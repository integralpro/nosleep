//
//  PowerEvent.cpp
//  NoSleepKext
//
//  Created by Pavel Prokofiev on 2/17/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#include "NoSleepExtension.h"

#include <IOKit/IOLib.h>
#include <IOKit/assert.h>

#include <IOKit/pwr_mgt/IOPM.h>
#include <IOKit/pwr_mgt/RootDomain.h>
#include <IOKit/IODeviceTreeSupport.h>
#include <IOKit/IOPlatformExpert.h>
#include <IOKit/IOUserClient.h>

#define super IOService
OSDefineMetaClassAndStructors( NoSleepExtension, IOService );

IOReturn NoSleepExtension::_clamshellEventInterestHandler(void * target, void * refCon,
                                                          UInt32 messageType, IOService * provider,
                                                          void * messageArgument, vm_size_t argSize)
{
    return ((NoSleepExtension *)target)->clamshellEventInterestHandler(messageType, provider,
                                                                       messageArgument, argSize);
}

IOReturn NoSleepExtension::clamshellEventInterestHandler(UInt32 messageType, IOService * provider,
                                                         void * messageArgument, vm_size_t argSize)
{
    if(messageType == kIOPMMessageClamshellStateChange)
    {
#ifdef DEBUG
        IOLog("%s[%p]::%s(%u, %p, %p, %lu)\n", getName(), this, __FUNCTION__,
              (unsigned int)messageType, provider, messageArgument, (long unsigned int)argSize);
#endif
        
        clamshellState = (bool)(((uintptr_t)messageArgument) & kClamshellStateBit);
        clamshellShouldSleep = (bool)(((uintptr_t)messageArgument) & kClamshellSleepBit);
        isClamshellStateInitialized = true;
        
        //This should be checked
        if(clamshellShouldSleep && (currentSleepSuppressionMode == kForceClamshellSleepDisabled))
            setSleepSuppressionMode(kForceClamshellSleepDisabled);
    }
    
    return kIOReturnSuccess;
}

bool NoSleepExtension::start( IOService * provider )
{
#ifdef DEBUG
    IOLog("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__,
		  provider);
#endif
    if( !super::start( provider ))
        return( false );
    
    // This should be done ASAP, cause pRootDomain
    // is used later in other methods
    pRootDomain = getPMRootDomain();

    SleepSuppressionMode mode;
    
    OSBoolean *loadedState = kOSBooleanFalse;
    OSReturn ret = ReadNVRAM(&loadedState);
    if(ret == kOSReturnSuccess && loadedState->isTrue()) {
        mode = kForceClamshellSleepDisabled;
    } else {
        mode = kIgnoreClamshellActivity;
    }
    
    setSleepSuppressionMode(mode);
    
    clamshellStateInterestNotifier = 
        pRootDomain->registerInterest(gIOGeneralInterest, NoSleepExtension::_clamshellEventInterestHandler, this);
    
    registerService();
    
    StartPM(provider);
    
    IOLog("%s: successfully started\n", getName());
    
    return( true );
}

bool NoSleepExtension::willTerminate( IOService * provider, IOOptionBits options )
{
#ifdef DEBUG
    IOLog("%s[%p]::%s(%p, %d)\n", getName(), this, __FUNCTION__,
		  provider, options);
#endif
    SaveState();
    return super::willTerminate(provider, options);
}

void NoSleepExtension::stop( IOService * provider )
{
#ifdef DEBUG
    IOLog("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__,
		  provider);
#endif
    
    StopPM();
    
    SaveState();
    
    setSleepSuppressionMode(kIgnoreClamshellActivity);
    clamshellStateInterestNotifier->remove();
    
    IOLog("%s: successfully stopped\n", getName());
    super::stop(provider);
}

bool NoSleepExtension::setSleepSuppressionMode(SleepSuppressionMode mode)
{
#ifdef DEBUG
    IOLog("%s[%p]::%s(%d)\n", getName(), this, __FUNCTION__, mode);
#endif
    
    IOLog("%s: setting state %d\n", getName(), mode);
    
    SleepSuppressionMode oldMode = currentSleepSuppressionMode;
    
    if(oldMode != mode) {
        UInt32 msg = (mode == kForceClamshellSleepDisabled)?kNoSleepCommandEnabled:kNoSleepCommandDisabled; 
        this->messageClients(msg);
    }
    
    currentSleepSuppressionMode = mode;
    
    switch (currentSleepSuppressionMode) {
        case kForceClamshellSleepDisabled:
            pRootDomain->receivePowerNotification(kIOPMDisableClamshell);
            break;
            
        case kIgnoreClamshellActivity:
            pRootDomain->receivePowerNotification(kIOPMEnableClamshell);
            break;
            
        default:
            return false;
    }
    
    return true;
}

void NoSleepExtension::SaveState()
{
#ifdef DEBUG
    IOLog("%s[%p]::%s()\n", getName(), this, __FUNCTION__);
#endif
    
    OSBoolean *savedState;
    OSBoolean *stateToSave;
    OSReturn readResult = ReadNVRAM(&savedState);
    
    if(currentSleepSuppressionMode == kIgnoreClamshellActivity) {
        stateToSave = kOSBooleanFalse;
    } else {
        stateToSave = kOSBooleanTrue;
    }
    
    if((readResult != kOSReturnSuccess) || 
       (!stateToSave->isEqualTo(savedState))) {
        WriteNVRAM(stateToSave);
    }
#ifdef DEBUG
    else {
        IOLog("%s: skip writing, reason: readResult == %s, stateToSave %s savedState\n",
              getName(),
              (readResult == kOSReturnSuccess)?"kOSReturnSuccess":"kOSReturnError",
              stateToSave->isEqualTo(savedState)?"==":"!=");
    }
#endif
}

OSReturn NoSleepExtension::WriteNVRAM(OSBoolean *value)
{
#ifdef DEBUG
    IOLog("%s: writing nvram, value: %s\n", getName(), value->getValue()?"true":"false");
#endif
    
//	IODTPlatformExpert *platform = OSDynamicCast(IODTPlatformExpert, getPlatform());
//    
//    OSReturn ret = kOSReturnError;
//    if (platform)
//	{
//        const OSSymbol *key = OSSymbol::withCStringNoCopy(NOSLEEPSTATE);
//        OSData *savedData;
//        OSData *newData = OSData::withCapacity(1);
//        *((UInt8 *)newData->getBytesNoCopy()) = (value->isTrue() ? 0x01 : 0x00);
//        
//        ret = platform->readNVRAMProperty(this, &key, &savedData);
//        if(ret == kOSReturnSuccess) {
//            
//            if(!savedData->isEqualTo(newData)) {
//                ret = platform->writeNVRAMProperty(this, key, newData);
//            }
//            
//            savedData->release();
//        }
//        
//        newData->release();
//        key->release();
//	}
    
    bool ret;
    IORegistryEntry *entry = IORegistryEntry::fromPath( "/options", gIODTPlane );
    if ( entry )
    {
        char buffer = value->isTrue() ? 0x01 : 0x00;
        OSData *dataToSave = OSData::withBytes(&buffer, 1);
        
        ret = entry->setProperty(IORegistrySleepSuppressionMode, dataToSave);
        
        dataToSave->release();
        entry->release();
#ifdef DEBUG
        IOLog("%s: writing nvram, result: %s\n", getName(), ret?"true":"false");
#endif
    } else {
        return kOSReturnError;
    }
    
    return ret?kOSReturnSuccess:kOSReturnError;
}

OSReturn NoSleepExtension::ReadNVRAM(OSBoolean **value)
{
#ifdef DEBUG
    IOLog("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__, value);
#endif

//    IODTPlatformExpert *platform = OSDynamicCast(IODTPlatformExpert, getPlatform());
//    
//    OSReturn ret = kOSReturnError;
//    if (platform)
//	{
//        const OSSymbol *key = OSSymbol::withCStringNoCopy(NOSLEEPSTATE);
//        OSData *savedData;
//        
//        ret = platform->readNVRAMProperty(this, &key, &savedData);
//        if(ret == kOSReturnSuccess) {
//            
//            if(*((UInt8 *)savedData->getBytesNoCopy()) == 0x00) {
//                *value = kOSBooleanFalse;
//            } else {
//                *value = kOSBooleanTrue;
//            }
//            
//            savedData->release();
//        }
//        key->release();
//	}
    
#ifdef DEBUG
    IOLog("%s: reading nvram\n", getName());
#endif
    
    OSReturn ret = kOSReturnError;
    IORegistryEntry *entry = IORegistryEntry::fromPath( "/options", gIODTPlane );
    if ( entry )
    {
        OSObject *rawValue = entry->getProperty(IORegistrySleepSuppressionMode);
#ifdef DEBUG
        IOLog("%s: rawValueClassName: %s\n", getName(), rawValue->getMetaClass()->getClassName());
#endif
        if(rawValue != NULL) {
            IOLog("%s: before cast\n", getName());
            OSData *data = OSDynamicCast(OSData, rawValue);
            IOLog("%s: after cast\n", getName());
            if(data->getLength() == 1) {
                *value = (((char *)data->getBytesNoCopy())[0] == 1)
                ? kOSBooleanTrue : kOSBooleanFalse;
                
                ret = kOSReturnSuccess;
#ifdef DEBUG
                IOLog("%s: reading nvram, value: %s\n", getName(), (*value)->isTrue()?"true":"false");
#endif
            }
#ifdef DEBUG
            else {
                IOLog("%s: read error: data->Len %s 1\n", getName(),
                      (data->getLength() == 1)?"==":"!=");
            }
#endif

        }
        entry->release();
    }
    
    return ret;
}
