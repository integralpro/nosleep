//
//  NoSleepExtension.cpp
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
        if(clamshellShouldSleep && (getCurrentSleepSuppressionState() == kNoSleepStateEnabled))
            setSleepSuppressionState(kNoSleepStateEnabled, kNoSleepModeCurrent);
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
    
    isSleepStateInitialized = false;
    
    acSleepSuppressionState = kNoSleepStateDisabled;
    batterySleepSuppressionState = kNoSleepStateDisabled;
    
    forceClientMessage = false;
    isOnAC = true;
    pPowerSource = NULL;
    
    // This should be done ASAP, cause pRootDomain
    // is used later in other methods
    pRootDomain = getPMRootDomain();

    UInt8 loadedState;
    OSReturn ret = readNVRAM(&loadedState);
    if(ret == kOSReturnSuccess) {
        unpackSleepState(loadedState,
                         &batterySleepSuppressionState,
                         &acSleepSuppressionState);
    }
    
    /// NoSleep will be activeted after matching with the IOPMPowerSource
    //updateSleepPowerState();
    
    clamshellStateInterestNotifier = 
        pRootDomain->registerInterest(gIOGeneralInterest,
                                      NoSleepExtension::_clamshellEventInterestHandler, this);
    
    registerService();
    
    startPM(provider);
    
    IOLog("%s: successfully started\n", getName());
    
    return( true );
}

bool NoSleepExtension::willTerminate( IOService * provider, IOOptionBits options )
{
#ifdef DEBUG
    IOLog("%s[%p]::%s(%p, %d)\n", getName(), this, __FUNCTION__,
		  provider, options);
#endif
    saveState();
    return super::willTerminate(provider, options);
}

void NoSleepExtension::stop( IOService * provider )
{
#ifdef DEBUG
    IOLog("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__,
		  provider);
#endif
    
    stopPM();
    
    saveState();
    
    setSleepSuppressionState(kNoSleepStateDisabled, kNoSleepModeCurrent);
    clamshellStateInterestNotifier->remove();
    
    IOLog("%s: successfully stopped\n", getName());
    super::stop(provider);
}

NoSleepState NoSleepExtension::sleepSuppressionState(int mode)
{
    switch (mode) {
        default:
        case kNoSleepModeCurrent:
            return getCurrentSleepSuppressionState();
        case kNoSleepModeAC:
            return acSleepSuppressionState;
        case kNoSleepModeBattery:
            return batterySleepSuppressionState;
    }
}

bool NoSleepExtension::setSleepSuppressionState(NoSleepState state, int mode)
{
#ifdef DEBUG
    IOLog("%s[%p]::%s(%d, %d)\n", getName(), this, __FUNCTION__, state, mode);
#endif
    
    if(mode != kNoSleepModeCurrent) {
        if(isOnAC) {
            if(mode == kNoSleepModeBattery) {
                batterySleepSuppressionState = state;
                return true;
            }
        } else {
            if(mode == kNoSleepModeAC) {
                acSleepSuppressionState = state;
                return true;
            }
        }
    }
    
    isSleepStateInitialized = true;
    
    IOLog("%s: setting state: %d, for mode: %d (%s-mode)\n", getName(), state, mode, isOnAC?"ac":"battery");
    
    NoSleepState oldState = getCurrentSleepSuppressionState();
    
    if(forceClientMessage || oldState != state) {
        forceClientMessage = false;
        
        UInt32 msg = (state == kNoSleepStateEnabled)?kNoSleepCommandEnabled:kNoSleepCommandDisabled; 
        this->messageClients(msg);
        
        setCurrentSleepSuppressionState(state);
    }
    
    switch (getCurrentSleepSuppressionState()) {
        case kNoSleepStateEnabled:
            pRootDomain->receivePowerNotification(kIOPMDisableClamshell);
            break;
            
        case kNoSleepStateDisabled:
            pRootDomain->receivePowerNotification(kIOPMEnableClamshell);
            break;
            
        default:
            return false;
    }
    
    return true;
}

void NoSleepExtension::saveState()
{
#ifdef DEBUG
    IOLog("%s[%p]::%s()\n", getName(), this, __FUNCTION__);
#endif
    
    UInt8 savedState;
    UInt8 stateToSave = packSleepState(batterySleepSuppressionState, acSleepSuppressionState);
    
#ifdef DEBUG
    IOLog("%s: value to save: %d\n", getName(), stateToSave);
#endif
    
    OSReturn readResult = readNVRAM(&savedState);
    if((readResult != kOSReturnSuccess) || (stateToSave != savedState)) {
        writeNVRAM(stateToSave);
    }
#ifdef DEBUG
    else {
        IOLog("%s: skip writing, reason: readResult == %s, stateToSave %s savedState\n",
              getName(),
              (readResult == kOSReturnSuccess)?"kOSReturnSuccess":"kOSReturnError",
              stateToSave == savedState?"==":"!=");
    }
#endif
}

UInt8 NoSleepExtension::packSleepState(NoSleepState batterySleepSuppressionState,
                                       NoSleepState acSleepSuppressionState)
{
    return (UInt8)(((batterySleepSuppressionState == kNoSleepStateEnabled)?0x10:0x00) |
                   ((acSleepSuppressionState      == kNoSleepStateEnabled)?0x01:0x00));
}

void NoSleepExtension::unpackSleepState(UInt8 value,
                                        NoSleepState *batterySleepSuppressionState,
                                        NoSleepState *acSleepSuppressionState)
{
    *batterySleepSuppressionState = (value & 0x10) ? kNoSleepStateEnabled : kNoSleepStateDisabled;
    *acSleepSuppressionState      = (value & 0x01) ? kNoSleepStateEnabled : kNoSleepStateDisabled;
}

OSReturn NoSleepExtension::writeNVRAM(UInt8 value)
{
#ifdef DEBUG
    IOLog("%s: writing nvram, value: 0x%02x\n", getName(), value);
#endif
    
    bool ret;
    IORegistryEntry *entry = IORegistryEntry::fromPath( "/options", gIODTPlane );
    if ( entry )
    {
        OSData *dataToSave = OSData::withBytes(&value, 1);
        
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

OSReturn NoSleepExtension::readNVRAM(UInt8 *value)
{
#ifdef DEBUG
    IOLog("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__, value);
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
            OSData *data = OSDynamicCast(OSData, rawValue);
            if(data->getLength() == 1) {
                *value = ((UInt8 *)data->getBytesNoCopy())[0];
                
                ret = kOSReturnSuccess;
#ifdef DEBUG
                IOLog("%s: reading nvram, value: 0x%02x\n", getName(), (*value));
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
