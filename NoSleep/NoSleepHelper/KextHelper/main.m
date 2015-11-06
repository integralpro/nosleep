//
//  main.m
//  kextutility
//
//  Created by Pavel Prokofiev on 24/06/15.
//
//

#import "Version.h"
#import "GlobalConstants.h"
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <fts.h>
#import <xpc/xpc.h>
#import <IOKit/kext/KextManager.h>

#if DEBUG
#define DEBUG_LOG(...) NSLog(__VA_ARGS__)
#else
#define DEBUG_LOG(...)
#endif

#define ROOT_UID ((uid_t)0)
#define FMOD (S_ISUID | S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH)
#define KMOD (S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH)
#define KEXTLOAD_PROGRAM "/sbin/kextload"
#define KEXTUNLOAD_PROGRAM "/sbin/kextunload"
#define KEXT_NAME "NoSleep"

typedef enum {
    ACTION_UNEXPECTED,
    ACTION_CONFIGURE,
    ACTION_LOAD,
    ACTION_UNLOAD,
    ACTION_VERSION,
    ACTION_UNINSTALL,
} ACTION_TYPE;

typedef struct {
    ACTION_TYPE type;
    const char *command;
} ACTION_COMMAND;

static ACTION_COMMAND commands[] = {
    {ACTION_CONFIGURE, "configure"},
    {ACTION_LOAD, "load"},
    {ACTION_UNLOAD, "unload"},
    {ACTION_VERSION, "version"},
    {ACTION_UNINSTALL, "uninstall"},
};

static const char *getProcessPath() {
    static char *processPath = NULL;
    
    uint32_t bufferSize = 0;
    _NSGetExecutablePath(NULL, &bufferSize);
    
    if (processPath == NULL) {
        processPath = malloc(bufferSize);
        _NSGetExecutablePath(processPath, &bufferSize);
    }
    
    return processPath;
}

static NSString *getKextPath(NSString *bundlePath) {
    if (bundlePath == NULL) {
        return NULL;
    }
    
    NSString *path = [[[[bundlePath stringByAppendingPathComponent:@"Contents"]
                        stringByAppendingPathComponent:@"Resources"]
                       stringByAppendingPathComponent:@KEXT_NAME]
                      stringByAppendingPathExtension:@"kext"];
    return path;
}

static bool uninstall() {
    const char *path = getProcessPath();
    int ret = unlink(path);
    free((void *)path);
    return ret == 0;
}

static bool amIRoot() {
    return geteuid() == ROOT_UID;
}

static void logMsg(const NSString *msg, int errCode) {
    DEBUG_LOG(@"%@. Code = %d.", msg, errCode);
}

static void notifyNonRoot(int errCode) {
    logMsg(@"Permission denied. Probably utility is not configured", errCode);
}

static ACTION_TYPE getAction(const char *argv) {
    for (int i=0; i<sizeof(commands)/sizeof(ACTION_COMMAND); i++) {
        if (strcmp(argv, commands[i].command) == 0) {
            return commands[i].type;
        }
    }
    return ACTION_UNEXPECTED;
}

static int entcmp(const FTSENT **a, const FTSENT **b) {
    return strcmp((*a)->fts_name, (*b)->fts_name);
}

static bool walkPath(const char *dir, bool (*func)(const char *)) {
    bool ret = true;
    FTS *tree;
    FTSENT *f;
    char *argv[] = { (char *)dir, NULL };
    
    tree = fts_open(argv, FTS_LOGICAL | FTS_NOSTAT, entcmp);
    if (tree == NULL) {
        logMsg(@"fts_open", __LINE__);
    }
    
    while ((f = fts_read(tree))) {
        switch (f->fts_info) {
            case FTS_DNR:
            case FTS_DP:
                continue;
            case FTS_ERR:
                logMsg(@"fts_read - details", f->fts_info);
                ret = false;
                break;
        }
        
        if (!func(f->fts_path)) {
            logMsg([NSString stringWithFormat:@"%s", f->fts_path], __LINE__);
            ret = false;
        }
    }
    
    if (errno != 0) {
        logMsg(@"fts_read", errno);
        ret = false;
    }
    
    if (fts_close(tree) < 0) {
        logMsg(@"fts_close", __LINE__);
        ret = false;
    }
    
    return ret;
}

static bool configureKext(const char *path) {
    if (chown(path, ROOT_UID, ROOT_UID) != 0) {
        return false;
    }
    if (chmod(path, KMOD) != 0) {
        return false;
    }
    return true;
}

static BOOL configure(NSString *kextPath) {
    if (!amIRoot()) {
        notifyNonRoot(__LINE__);
        return NO;
    }
    
    if (!kextPath) {
        return NO;
    }
    
    if (!walkPath([kextPath UTF8String], configureKext)) {
        return NO;
    }
    
    return YES;
}

static BOOL kextLoad(NSString *kextPath) {
    if (!amIRoot()) {
        notifyNonRoot(__LINE__);
        return NO;
    }
    
    if (!configure(kextPath)) {
        return NO;
    }
    
    NSURL *url = [NSURL fileURLWithPath:kextPath];
    
    OSReturn ret = KextManagerLoadKextWithURL((CFURLRef)url, NULL);
    
    return ret == kOSReturnSuccess;
}

static BOOL kextUnload() {
    if (!amIRoot()) {
        notifyNonRoot(__LINE__);
        return NO;
    }
    
    OSReturn ret = KextManagerUnloadKextWithIdentifier((CFStringRef)@NOSLEEP_ID);
    
    return ret == kOSReturnSuccess;
}

static void __XPC_Peer_Event_Handler(xpc_connection_t connection, xpc_object_t event) {
    xpc_type_t type = xpc_get_type(event);
    
    if (type == XPC_TYPE_DICTIONARY) {
        BOOL ret;
        xpc_connection_t remote = xpc_dictionary_get_remote_connection(event);
        const char *command = xpc_dictionary_get_string(event, "command");
        
        const char *path = xpc_dictionary_get_string(event, "NSBundlePath");
        NSString *bundlePath = [NSString stringWithUTF8String:path];
        
        xpc_object_t reply = xpc_dictionary_create_reply(event);
        
        ACTION_TYPE action = getAction(command);
        switch (action) {
            case ACTION_LOAD:
                ret = kextLoad(getKextPath(bundlePath));
                break;
            case ACTION_UNLOAD:
                ret = kextUnload();
                break;
            case ACTION_VERSION:
                xpc_dictionary_set_string(reply, "BuildString", BuildString);
                ret = YES;
                break;
            case ACTION_UNINSTALL:
                ret = uninstall();
                break;
            case ACTION_CONFIGURE:
            case ACTION_UNEXPECTED:
            default:
                ret = NO;
                break;
        }
        
        xpc_dictionary_set_bool(reply, "return", ret);
#if DEBUG
        xpc_dictionary_set_string(reply, "debug", [[event debugDescription] UTF8String]);
#endif
        xpc_connection_send_message(remote, reply);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            xpc_release(reply);
            exit(0);
        });
    }
}

static void __XPC_Connection_Handler(xpc_connection_t connection)  {
    xpc_retain(connection);
    xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
        __XPC_Peer_Event_Handler(connection, event);
    });
    xpc_connection_resume(connection);
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        xpc_connection_t service = xpc_connection_create_mach_service(KextHelper_ID,
                                                                      dispatch_get_main_queue(),
                                                                      XPC_CONNECTION_MACH_SERVICE_LISTENER);

        if (!service) {
            DEBUG_LOG(@"Failed to create service.");
            exit(EXIT_FAILURE);
        }
        
        xpc_connection_set_event_handler(service, ^(xpc_object_t connection) {
            xpc_type_t type = xpc_get_type(connection);
            if (type == XPC_TYPE_ERROR) {
                DEBUG_LOG(@"Error: %@", [connection description]);
                exit(1);
            } else if (type == XPC_TYPE_CONNECTION) {
                DEBUG_LOG(@"Connection");
                __XPC_Connection_Handler(connection);
            } else {
                DEBUG_LOG(@"Unrecognized object: %@", [connection description]);
            }
        });
        
        xpc_connection_resume(service);
        
        DEBUG_LOG(@"NoSleep KextHelper online");
        
        dispatch_main();
    }
    return EXIT_SUCCESS;
}
