//
//  NoSleepExtension.h
//  nosleep
//
//  Created by Pavel Prokofiev on 4/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#include <IOKit/IOService.h>
#import <NoSleep/GlobalConstants.h>

class IOPMrootDomain;

enum SleepSuppressionMode
{
    kIgnoreClamshellActivity        = 0,
    kForceClamshellSleepDisabled    = 1,
};

class NoSleepExtension : public IOService
{
    OSDeclareDefaultStructors( NoSleepExtension );
    
private:
    static IOReturn _clamshellEventInterestHandler( void * target, void * refCon,
                                                  UInt32 messageType, IOService * provider,
                                                  void * messageArgument, vm_size_t argSize );
protected:
    virtual IOReturn clamshellEventInterestHandler(UInt32 messageType,
                                                   IOService * provider, void * messageArgument, vm_size_t argSize);
    
private:
    IOPMrootDomain *pRootDomain;
    IORegistryEntry *pOptions;
    IONotifier *clamshellStateInterestNotifier;
    
    bool isClamshellStateInitialized:1;
    bool clamshellState:1;
    bool clamshellShouldSleep:1;
    
    SleepSuppressionMode currentSleepSuppressionMode;
    
public:
    virtual bool start( IOService * provider );
    virtual void stop( IOService * provider );
    virtual bool willTerminate( IOService * provider, IOOptionBits options );
    
    bool setSleepSuppressionMode(SleepSuppressionMode mode);
    inline SleepSuppressionMode sleepSuppressionMode() { return currentSleepSuppressionMode; }
};