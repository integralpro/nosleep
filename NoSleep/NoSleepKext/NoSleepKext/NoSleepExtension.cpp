#include "NoSleepExtension.h"

#include <IOKit/IOLib.h>
#include <IOKit/assert.h>

#include <IOKit/pwr_mgt/IOPM.h>
#include <IOKit/pwr_mgt/RootDomain.h>
#include <IOKit/IODeviceTreeSupport.h>

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

    SleepSuppressionMode mode;
    
    pRootDomain = getPMRootDomain();
    pOptions = IORegistryEntry::fromPath("/options", gIODTPlane);
    if(pOptions != NULL)
    {
        OSObject *ioRegValue = pOptions->getProperty(IORegistrySleepSuppressionMode);
        if(ioRegValue == NULL)
        {
            ioRegValue = kOSBooleanTrue;
        }

        if(ioRegValue == kOSBooleanTrue)
        {
            mode = kForceClamshellSleepDisabled;
        } else
        {
            mode = kIgnoreClamshellActivity;
        }
    }
    else
    {
        mode = kForceClamshellSleepDisabled;
    }
    
    setSleepSuppressionMode(mode);
    
    clamshellStateInterestNotifier = 
        pRootDomain->registerInterest(gIOGeneralInterest, NoSleepExtension::_clamshellEventInterestHandler, this);
    
    registerService();
    
    IOLog("%s: successfully started\n", getName());
    
    return( true );
}

bool NoSleepExtension::willTerminate( IOService * provider, IOOptionBits options )
{
    return super::willTerminate(provider, options);
}

void NoSleepExtension::stop( IOService * provider )
{
#ifdef DEBUG
    IOLog("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__,
		  provider);
#endif

    if(pOptions != NULL)
    {
        IOLog("Setting\n");
        bool ioRegValue;
        if(currentSleepSuppressionMode == kForceClamshellSleepDisabled)
        {
            ioRegValue = true;
        }
        else
        {
            ioRegValue = false;
        }
        pOptions->setProperty(IORegistrySleepSuppressionMode, ioRegValue);
        pOptions->release();
    }
    
    setSleepSuppressionMode(kIgnoreClamshellActivity);
    clamshellStateInterestNotifier->remove();
    
    IOLog("%s: successfully stopped\n", getName());
    
    super::stop(provider);
}

bool NoSleepExtension::setSleepSuppressionMode(SleepSuppressionMode mode)
{
#ifdef DEBUG
    IOLog("%s[%p]::%s(%d)\n", getName(), this, __FUNCTION__,
		  mode);
#else
    IOLog("%s: setting state %d\n", getName(), mode);
#endif
    
    if(currentSleepSuppressionMode != mode) {
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


