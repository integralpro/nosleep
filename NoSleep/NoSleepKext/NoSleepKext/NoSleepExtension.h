//
//  NoSleepExtension.h
//  nosleep
//
//  Created by Pavel Prokofiev on 4/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#include <IOKit/IOService.h>
#include <NoSleep/GlobalConstants.h>

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
    static IOReturn _powerSourceStateChanged(void * target, void * refCon,
                                             UInt32 messageType, IOService * provider,
                                             void * messageArgument, vm_size_t argSize);
    static bool _powerSourcePublished(void * target, void * refCon,
                                      IOService * newService,
                                      IONotifier * notifier);
protected:
    virtual IOReturn clamshellEventInterestHandler(UInt32 messageType,
                                                   IOService * provider, void * messageArgument, vm_size_t argSize);
    virtual IOReturn powerSourceStateChanged(UInt32 messageType, IOService * provider,
                                              void * messageArgument, vm_size_t argSize);
    virtual bool powerSourcePublished(IOService * newService, IONotifier * notifier);
    
    static UInt8 packSleepState(SleepSuppressionMode batterySleepSuppressionMode,
                                SleepSuppressionMode acSleepSuppressionMode);
    static void unpackSleepState(UInt8 value,
                                 SleepSuppressionMode *batterySleepSuppressionMode,
                                 SleepSuppressionMode *acSleepSuppressionMode);
    
    OSReturn writeNVRAM(UInt8 value);
    OSReturn readNVRAM(UInt8 *value);
    
    void saveState();
    
private:
    IONotifier *powerStateNotifier;
    
    IOPMrootDomain *pRootDomain;
    //IORegistryEntry *pOptions;
    IONotifier *clamshellStateInterestNotifier;
    
    bool isClamshellStateInitialized:1;
    bool clamshellState:1;
    bool clamshellShouldSleep:1;
    
    bool forceClientMessage;
    bool isOnAC;
    SleepSuppressionMode batterySleepSuppressionMode;
    SleepSuppressionMode acSleepSuppressionMode;
    inline void setCurrentSleepSuppressionMode(SleepSuppressionMode mode) {
        if(isOnAC) {
            acSleepSuppressionMode = mode;
        } else {
            batterySleepSuppressionMode = mode;
        }
    }
    inline SleepSuppressionMode getCurrentSleepSuppressionMode() {
        if(isOnAC) {
            return acSleepSuppressionMode;
        } else {
            return batterySleepSuppressionMode;
        }
    }
    
    // Power events
    void startPM(IOService *provider);
    void stopPM();
    void updateSleepPowerStateState();
    
public:
    virtual bool start( IOService * provider );
    virtual void stop( IOService * provider );
    virtual bool willTerminate( IOService * provider, IOOptionBits options );
    virtual void systemWillShutdown( IOOptionBits specifier );
    
    // Interface methods
    bool setSleepSuppressionMode(SleepSuppressionMode mode);
    inline SleepSuppressionMode sleepSuppressionMode() { return getCurrentSleepSuppressionMode(); }
};
