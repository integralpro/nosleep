//
//  PowerEvent.cpp
//  NoSleepKext
//
//  Created by Pavel Prokofiev on 2/17/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#include <NoSleepExtension.h>

#include <IOKit/IOLib.h>
#include <IOKit/assert.h>

#include <IOKit/pwr_mgt/IOPM.h>

#define super IOService

static IOPMPowerState myPowerStates[] = {
    {1, kIOPMPowerOn, kIOPMPowerOn, kIOPMPowerOn, 0, 0, 0, 0, 0, 0, 0, 0}
};

void NoSleepExtension::StartPM(IOService *provider)
{
#ifdef DEBUG
    IOLog("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__, provider);
#endif
    PMinit();
    provider->joinPMtree(this);
    registerPowerDriver(this, myPowerStates, 1);
}

void NoSleepExtension::StopPM()
{
#ifdef DEBUG
    IOLog("%s[%p]::%s()\n", getName(), this, __FUNCTION__);
#endif
    PMstop();
}

void NoSleepExtension::systemWillShutdown( IOOptionBits specifier )
{
#ifdef DEBUG
    IOLog("%s[%p]::%s(%d)\n", getName(), this, __FUNCTION__,
		  specifier);
#endif
    SaveState();
    return super::systemWillShutdown(specifier);
}
