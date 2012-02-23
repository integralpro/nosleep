//
//  NoSleepExtension.h
//  nosleep
//
//  Created by Pavel Prokofiev on 4/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#include <IOKit/IOService.h>
#include <NoSleep/GlobalConstants.h>

#define KCmdFromState(x) (((x) == kNoSleepStateEnabled)?kNoSleepCommandEnabled:kNoSleepCommandDisabled)

class IOPMrootDomain;
class IOPMPowerSource;

enum NoSleepState
{
    kNoSleepStateDisabled           = 0,
    kNoSleepStateEnabled            = 1,
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
    
    static UInt8 packSleepState(NoSleepState batterySleepSuppressionMode,
                                NoSleepState acSleepSuppressionMode);
    static void unpackSleepState(UInt8 value,
                                 NoSleepState *batterySleepSuppressionMode,
                                 NoSleepState *acSleepSuppressionMode);
    
    OSReturn writeNVRAM(UInt8 value);
    OSReturn readNVRAM(UInt8 *value);
    
    void saveState();
    
private:
    IONotifier *powerStateNotifier;
    IOPMPowerSource *pPowerSource;
    
    IOPMrootDomain *pRootDomain;
    IONotifier *clamshellStateInterestNotifier;
    
    bool isSleepStateInitialized;
    
    bool isClamshellStateInitialized:1;
    bool clamshellState:1;
    bool clamshellShouldSleep:1;
    
    bool forceClientMessage;
    bool isOnAC;
    NoSleepState batterySleepSuppressionState;
    NoSleepState acSleepSuppressionState;
    inline void setCurrentSleepSuppressionState(NoSleepState state) {
        if(isOnAC) {
            acSleepSuppressionState = state;
        } else {
            batterySleepSuppressionState = state;
        }
    }
    inline NoSleepState getCurrentSleepSuppressionState() {
        if(isOnAC) {
            return acSleepSuppressionState;
        } else {
            return batterySleepSuppressionState;
        }
    }
    
    // Power events
    void startPM(IOService *provider);
    void stopPM();
    void updateSleepPowerState();
    
public:
    virtual bool start( IOService * provider );
    virtual void stop( IOService * provider );
    virtual bool willTerminate( IOService * provider, IOOptionBits options );
    virtual void systemWillShutdown( IOOptionBits specifier );
    
    // Interface methods
    bool setSleepSuppressionState(NoSleepState state, int mode);
    NoSleepState sleepSuppressionState(int mode);
};
