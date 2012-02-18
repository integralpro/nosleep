//
//  NoSleepClientClass.cpp
//  nosleep
//
//  Created by Pavel Prokofiev on 4/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include "NoSleepClientClass.h"

#include <IOKit/IOLib.h>
#include <IOKit/assert.h>

#define super IOUserClient
OSDefineMetaClassAndStructors( NoSleepClientClass, IOUserClient );

bool NoSleepClientClass::initWithTask( task_t owningTask, void * securityID,
                                      UInt32 type,  OSDictionary * properties )
{
#ifdef DEBUG
    IOLog("NoSleepClientClass::initWithTask(type %u)\n", (unsigned int)type);
#endif
    
    return super::initWithTask( owningTask, securityID, type, properties);
}

bool NoSleepClientClass::start( IOService * provider )
{
#ifdef DEBUG
    IOLog("NoSleepClientClass::start\n");
#endif
    
    if( !super::start( provider ))
        return( false );
    
    /*
     * Our provider is the NoSleepClientClass object.
     */
    assert( OSDynamicCast( NoSleepExtension, provider ));
    m_noSleepExtension = (NoSleepExtension *) provider;
    
    return true;
}


/*
 * Kill ourselves off if the client closes its connection or the client dies.
 */

IOReturn NoSleepClientClass::clientClose( void )
{
    if( !isInactive())
        terminate();
    
    return( kIOReturnSuccess );
}

/* 
 * stop will be called during the termination process, and should free all resources
 * associated with this client.
 */
void NoSleepClientClass::stop( IOService * provider )
{
#ifdef DEBUG
    IOLog("NoSleepClientClass::stop\n");
#endif
    
    super::stop( provider );
}

/*
 * Lookup the external methods - supply a description of the parameters 
 * available to be called 
 */

const IOExternalMethodDispatch NoSleepClientClass::sMethods[] = {
	{   // getSleepSuppressionMode
		(IOExternalMethodAction) &NoSleepClientClass::getSleepSuppressionMode,
		1,																		// One scalar input values.
		0,																		// No struct input value.
		1,																		// One scalar output value.
		0																		// No struct output value.
	},
	{   // setSleepSuppressionMode
		(IOExternalMethodAction) &NoSleepClientClass::setSleepSuppressionMode,
		2,																		// Two scalar input values.
		0,																		// No struct input value.
		0,																		// One scalar output value.
		0																		// No struct output value.
	},
};

IOReturn NoSleepClientClass::externalMethod(uint32_t selector, IOExternalMethodArguments* arguments,
                                            IOExternalMethodDispatch* dispatch, OSObject* target, void* reference)

{
#ifdef DEBUG
	IOLog("%s[%p]::%s(%d, %p, %p, %p, %p)\n", getName(), this, __FUNCTION__,
		  selector, arguments, dispatch, target, reference);
#endif
    
    if (selector < (uint32_t) kNumberOfMethods) {
        dispatch = (IOExternalMethodDispatch *) &sMethods[selector];
        
        if (!target) {
            target = m_noSleepExtension;
		}
    }
    
	return super::externalMethod(selector, arguments, dispatch, target, reference);
}


IOReturn NoSleepClientClass::getSleepSuppressionMode(NoSleepExtension* target,
                                                     void* reference,
                                                     IOExternalMethodArguments* arguments)
{
#ifdef DEBUG
    IOLog("NoSleepClientClass::getSleepSuppressionState\n");
#endif
    arguments->scalarOutput[0] = 
        (target->sleepSuppressionState((int)arguments->scalarInput[0]) == kNoSleepStateDisabled) ? 0 : 1;
    return kIOReturnSuccess;
}

IOReturn NoSleepClientClass::setSleepSuppressionMode(NoSleepExtension* target,
                                                     void* reference,
                                                     IOExternalMethodArguments* arguments)

{
    bool ret;
#ifdef DEBUG
    IOLog("NoSleepClientClass::setSleepSuppressionState\n");
#endif
    ret = target->setSleepSuppressionState(
        ((arguments->scalarInput[0] == 0) ? kNoSleepStateDisabled : kNoSleepStateEnabled),
        (int)arguments->scalarInput[1]);       
    return (ret == true) ? kIOReturnSuccess : kIOReturnError;
}
