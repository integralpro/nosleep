//
//  AuthorizeService.m
//  NoSleep
//
//  Created by Pavel Prokofiev on 12/25/12.
//
//

#import "AuthorizationService.h"

@implementation AuthorizationService

- (void)dealloc {
    [self deauthorize];
    [super dealloc];
}

- (OSStatus)authorize {
    OSStatus isAuthorized;
    if (authorizationRef) {
        isAuthorized = [self copyRights];
    } else {
        const AuthorizationRights* kNoRightsSpecified = NULL;
        isAuthorized = AuthorizationCreate(kNoRightsSpecified,
                                           kAuthorizationEmptyEnvironment,
                                           kAuthorizationFlagDefaults,
                                           &authorizationRef);
        
        if (isAuthorized == errAuthorizationSuccess) {
            isAuthorized = [self copyRights];
        }
    }
    return isAuthorized;
}

// deauthorize dumps any existing authorization. Calling authorize afterwards
// will raise the admin password dialog
- (void)deauthorize {
    if (authorizationRef) {
        AuthorizationFree(authorizationRef, kAuthorizationFlagDefaults);
        authorizationRef = 0;
    }
}

- (OSStatus)copyRights {
    NSParameterAssert(authorizationRef);
    
    AuthorizationFlags theFlags = kAuthorizationFlagDefaults
    | kAuthorizationFlagPreAuthorize
    | kAuthorizationFlagExtendRights
    | kAuthorizationFlagInteractionAllowed;
    AuthorizationItem theItems = { kAuthorizationRightExecute, 0, NULL, 0 };
    AuthorizationRights theRights = { 1, &theItems };
    
    OSStatus err = AuthorizationCopyRights(authorizationRef, &theRights,
                                           kAuthorizationEmptyEnvironment,
                                           theFlags, NULL);
    if (err != errAuthorizationSuccess) {
        [self deauthorize];
    }
    
    return err;
}

- (int)runTaskForPath:(NSString *)path
        withArguments:(NSArray *)arguments
               output:(NSData **)output {
    
    int result = 0;
    NSFileHandle *outFile = nil;
    [self setScriptRunning:YES];
    
    // authorized
    if ([self authorize] != errAuthorizationSuccess) {
        return -1;
    }
    FILE *outPipe = NULL;
    NSUInteger numArgs = [arguments count];
    const char **args = malloc(sizeof(char*) * (numArgs + 1));
    if (!args) {
        [self setScriptRunning:NO];
        return -1;
    }
    const char *cPath = [path fileSystemRepresentation];
    for (unsigned int i = 0; i < numArgs; i++) {
        args[i] = [[arguments objectAtIndex:i] fileSystemRepresentation];
    }
    
    args[numArgs] = NULL;
    
    AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
    result = AuthorizationExecuteWithPrivileges(authorizationRef,
                                                cPath, myFlags,
                                                (char *const*) args, &outPipe);
    free(args);
    if (result == 0) {
        int wait_status;
        int pid = 0;
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        do {
            NSDate *waitDate = [NSDate dateWithTimeIntervalSinceNow:0.1];
            [runLoop runUntilDate:waitDate];
            pid = waitpid(-1, &wait_status, WNOHANG);
        } while (pid == 0);
        if (pid == -1 || !WIFEXITED(wait_status)) {
            result = -1;
        } else {
            result = WEXITSTATUS(wait_status);
        }
        if (output) {
            int fd = fileno(outPipe);
            outFile = [[[NSFileHandle alloc] initWithFileDescriptor:fd 
                                             closeOnDealloc:YES] autorelease];
        }
    }
    
    if (outFile && output) {
        *output = [outFile readDataToEndOfFile];
    }      
    [self setScriptRunning:NO];
    return result;
}

@end
