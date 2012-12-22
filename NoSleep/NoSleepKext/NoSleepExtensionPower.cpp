//
//  NoSleepExtensionPower.cpp
//  NoSleepKext
//
//  Created by Pavel Prokofiev on 2/17/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#include <NoSleepExtension.h>

#include <IOKit/IOLib.h>
#include <IOKit/assert.h>

#include <IOKit/pwr_mgt/IOPM.h>
#include <IOKit/pwr_mgt/IOPMPowerSource.h>

#define super IOService

static IOPMPowerState myPowerStates[] = {
    {1, kIOPMPowerOn, kIOPMPowerOn, kIOPMPowerOn, 0, 0, 0, 0, 0, 0, 0, 0}
};

IOReturn NoSleepExtension::_powerSourceStateChanged(void * target, void * refCon,
                                     UInt32 messageType, IOService * provider,
                                     void * messageArgument, vm_size_t argSize )
{
    return ((NoSleepExtension *)target)->powerSourceStateChanged(messageType, provider,
                                                                 messageArgument,
                                                                 argSize);
}

bool NoSleepExtension::_powerSourcePublished(void * target, void * refCon,
                                             IOService * newService,
                                             IONotifier * notifier)
{
    return ((NoSleepExtension *)target)->powerSourcePublished(newService, notifier);
}

bool NoSleepExtension::powerSourcePublished(IOService *newService, IONotifier *notifier)
{
#ifdef DEBUG
    IOLog("%s[%p]::%s(%p, %p)\n", getName(), this, __FUNCTION__, newService, notifier);
#endif
    pPowerSource = (IOPMPowerSource *)newService;
    
    this->powerStateNotifier = 
        pPowerSource->registerInterest(gIOGeneralInterest,
                                     NoSleepExtension::_powerSourceStateChanged, this);
    notifier->remove();
    updateSleepPowerState();
    return true;
}

IOReturn NoSleepExtension::powerSourceStateChanged(UInt32 messageType, IOService * provider,
                                               void * messageArgument, vm_size_t argSize )
{
#ifdef DEBUG
    IOLog("%s[%p]::%s(%ld, %p, %p, %p)\n", getName(), this, __FUNCTION__,
          (long)messageType, provider, messageArgument, (void*)argSize);
#endif
    
    if (messageType == kIOPMMessageBatteryStatusHasChanged) {
        updateSleepPowerState();
    }
    return kIOReturnSuccess;
}

void NoSleepExtension::updateSleepPowerState()
{
    // Check if update is needed
    if(!isSleepStateInitialized ||
       (pPowerSource != NULL && isOnAC != pPowerSource->externalChargeCapable())) {
        forceClientMessage = true;
        isOnAC = pPowerSource->externalChargeCapable();
        setSleepSuppressionState(getCurrentSleepSuppressionState(), kNoSleepModeCurrent);
    }
}

void NoSleepExtension::startPM(IOService *provider)
{
#ifdef DEBUG
    IOLog("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__, provider);
#endif
    PMinit();
    provider->joinPMtree(this);
    registerPowerDriver(this, myPowerStates, 1);

    if (OSDictionary *tmpDict = serviceMatching("IOPMPowerSource"))
    {
        addMatchingNotification(gIOFirstPublishNotification, tmpDict,
                                &NoSleepExtension::_powerSourcePublished,
                                this, this);
        tmpDict->release();
    }
}

void NoSleepExtension::stopPM()
{
#ifdef DEBUG
    IOLog("%s[%p]::%s()\n", getName(), this, __FUNCTION__);
#endif
    if(powerStateNotifier){
        powerStateNotifier->remove();
        powerStateNotifier = NULL;
    }
    
    PMstop();
}

void NoSleepExtension::systemWillShutdown( IOOptionBits specifier )
{
#ifdef DEBUG
    IOLog("%s[%p]::%s(%ld)\n", getName(), this, __FUNCTION__,
		  (long)specifier);
#endif
    saveState();
    return super::systemWillShutdown(specifier);
}
