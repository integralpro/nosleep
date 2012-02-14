//
//  NoSleepClientClass.h
//  nosleep
//
//  Created by Pavel Prokofiev on 4/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include <IOKit/IOUserClient.h>
#include "NoSleepExtension.h"

#define kNumberOfMethods 2

class NoSleepClientClass : public IOUserClient {
    OSDeclareDefaultStructors( NoSleepClientClass );
    
private:
    NoSleepExtension *m_noSleepExtension;
    static const IOExternalMethodDispatch sMethods[kNumberOfMethods];
    
public:
    virtual bool start( IOService * provider );
    virtual void stop( IOService * provider );
    
    /* IOUserClient overrides */
    virtual bool initWithTask( task_t owningTask, void * securityID,
                              UInt32 type,  OSDictionary * properties );
    virtual IOReturn clientClose( void );
    
protected:
    virtual IOReturn externalMethod(uint32_t selector, IOExternalMethodArguments* arguments,
                                    IOExternalMethodDispatch* dispatch, OSObject* target, void* reference);
    /* External methods */
    static IOReturn getSleepSuppressionMode(NoSleepExtension* target, void* reference, IOExternalMethodArguments* arguments);
    static IOReturn setSleepSuppressionMode(NoSleepExtension* target, void* reference, IOExternalMethodArguments* arguments);
};
