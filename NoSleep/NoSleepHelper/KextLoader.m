//
//  KextLoader.m
//  NoSleep
//
//  Created by Pavel Prokofiev on 25/06/15.
//
//

#import "Version.h"
#import "GlobalConstants.h"
#import "KextLoader.h"
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>
#import <dispatch/queue.h>
#import <xpc/xpc.h>

@implementation KextLoader

+ (BOOL)blessHelperWithLabel:(NSString *)label error:(NSError **)error {
    BOOL result = NO;
    AuthorizationRef authRef = NULL;
    
    AuthorizationItem authItem		= { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
    AuthorizationRights authRights	= { 1, &authItem };
    AuthorizationFlags flags		=
        kAuthorizationFlagDefaults				|
        kAuthorizationFlagInteractionAllowed	|
        kAuthorizationFlagPreAuthorize			|
        kAuthorizationFlagExtendRights;

    OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
    if (status == errAuthorizationSuccess) {
        result = SMJobBless(kSMDomainSystemLaunchd, (CFStringRef)label, authRef, (CFErrorRef *)error);
    } else {
        NSLog(@"Failed to create AuthorizationRef. Error code: %ld", (long)status);
    }
    
    return result;
}

static BOOL configure() {
    NSError *error = nil;
    if (![KextLoader blessHelperWithLabel:@KextHelper_ID error:&error]) {
        NSLog(@"Failed to install KextHelper. Error code: %ld", [error code]);
        return NO;
    }
    return YES;
}

+ (BOOL)sendKextHelperCommand:(NSString *)command {
    return [KextLoader sendKextHelperCommand:command response:nil];
}

+ (BOOL)sendKextHelperCommand:(NSString *)command response:(xpc_object_t *)responsePtr {
    __block BOOL isError = NO;
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    xpc_connection_t connection = xpc_connection_create_mach_service(KextHelper_ID , DISPATCH_TARGET_QUEUE_DEFAULT, XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);
    
    if (!connection) {
        NSLog(@"Failed to create XPC connection.");
        return NO;
    }

    xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
        NSLog(@"Error");
        xpc_type_t type = xpc_get_type(event);
        if (type == XPC_TYPE_ERROR) {
            isError = YES;
#if DEBUG
            if (event == XPC_ERROR_CONNECTION_INTERRUPTED) {
                NSLog(@"XPC connection interupted.");
            }
            else if (event == XPC_ERROR_CONNECTION_INVALID) {
                NSLog(@"XPC connection invalid, releasing.");
            }
            else {
                NSLog(@"Unexpected XPC connection error.");
            }
#endif
        }
    });

    xpc_connection_resume(connection);
    
    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_string(message, "command", [command UTF8String]);
    xpc_dictionary_set_string(message, "NSBundlePath", [[[NSBundle mainBundle] bundlePath] UTF8String]);

    if (isError) {
        return NO;
    }
    
    __block xpc_object_t response = nil;
    xpc_connection_send_message_with_reply(connection, message, DISPATCH_TARGET_QUEUE_DEFAULT, ^(xpc_object_t object) {
        if (xpc_get_type(object) == XPC_TYPE_ERROR) {
            isError = YES;
        }
        
        if (!isError) {
            response = xpc_copy(object);
#if DEBUG
            //NSLog(@"Recv: %@", [response debugDescription]);
#endif
        }
        dispatch_semaphore_signal(sema);
    });
    
    dispatch_time_t time = dispatch_time(0, 2 * NSEC_PER_SEC);
    isError = (dispatch_semaphore_wait(sema, time) != 0);
    dispatch_release(sema);

    isError = isError || response == nil;
    
    if (!isError) {
        isError = !xpc_dictionary_get_bool(response, "return");
        
        if (responsePtr) {
            *responsePtr = response;
        }
    }
    
    xpc_release(message);
    xpc_release(connection);
    
    return !isError;
}

static BOOL checkVersion() {
    xpc_object_t response = nil;
    BOOL succeeded = [KextLoader sendKextHelperCommand:@"version" response:&response];
    
    if (succeeded && (xpc_get_type(response) == XPC_TYPE_DICTIONARY)) {
        const char *bs = xpc_dictionary_get_string(response, "BuildString");
        succeeded = bs && (strcmp(bs, BuildString) == 0);
//#if DEBUG
        if (!succeeded) {
            NSLog(@"Exprected version: %s, installed: %s", BuildString, bs);
        }
//#endif
        xpc_release(response);
    } else {
        succeeded = NO;
    }
    
    return succeeded;
}

+ (BOOL)loadKext {
    if (!checkVersion()) {
        if (!configure() || !checkVersion()) {
            return NO;
        }
    }
    
    return [KextLoader sendKextHelperCommand:@"load"];
}

+ (BOOL)unloadKext {
    return [KextLoader sendKextHelperCommand:@"unload"];
}

@end
