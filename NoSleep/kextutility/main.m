//
//  main.m
//  kextutility
//
//  Created by Pavel Prokofiev on 24/06/15.
//
//

#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <fts.h>

#define ROOT_UID ((uid_t)0)
#define FMOD (S_ISUID | S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH)
#define KMOD (S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH)
#define KEXTLOAD_PROGRAM "/sbin/kextload"
#define KEXTUNLOAD_PROGRAM "/sbin/kextunload"
#define KEXT_NAME "NoSleep.kext"

typedef enum {
    ACTION_UNEXPECTED,
    ACTION_CONFIGURE,
    ACTION_LOAD,
    ACTION_UNLOAD,
} ACTION_TYPE;

typedef struct {
    ACTION_TYPE type;
    const char *command;
} ACTION_COMMAND;

static ACTION_COMMAND commands[] = {
    {ACTION_CONFIGURE, "configure"},
    {ACTION_LOAD, "load"},
    {ACTION_UNLOAD, "unload"},
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

static const char *getKextPath() {
    static NSString *path = NULL;
    if (path == NULL) {
        path = [NSString stringWithCString:getProcessPath() encoding:NSASCIIStringEncoding];
        path = [[[[path stringByDeletingLastPathComponent]
                  stringByAppendingPathComponent:@".."]
                 stringByAppendingPathComponent:@"Resources"]
                stringByAppendingPathComponent:@KEXT_NAME];
    }
    return [path cStringUsingEncoding:NSASCIIStringEncoding];
}

static bool amIRoot() {
    return geteuid() == ROOT_UID;
}

static void sudo() {
    setuid(ROOT_UID);
    seteuid(ROOT_UID);
}

static void logMsg(const NSString *msg, int errCode) {
    NSLog(@"%@. Code = %d.", msg, errCode);
}

static void abortUtility(int errCode) {
    logMsg(@"Unexpected usage. Should be used by NoSleep.app only", errCode);
    exit(errCode);
}

static void notifyNonRoot(int errCode) {
    logMsg(@"Permission denied. Probably utility is not configured", errCode);
}

static ACTION_TYPE getAction(int argc, const char * argv[]) {
    if (argc != 2) {
        return ACTION_UNEXPECTED;
    }
    
    for (int i=0; i<sizeof(commands)/sizeof(ACTION_COMMAND); i++) {
        if (strcmp(argv[1], commands[i].command) == 0) {
            return commands[i].type;
        }
    }
        
    return ACTION_UNEXPECTED;
}

static int execKextLoad(bool unload) {
    sudo();
    if (!amIRoot()) {
        notifyNonRoot(__LINE__);
        return 1;
    }
    
    pid_t pid = fork();
    
    if (pid < 0) {
        logMsg(@"Fork", errno);
        return EXIT_FAILURE;
    }
    
    if (pid == 0) {
        char *toolPath;
        if(unload) {
            toolPath = KEXTUNLOAD_PROGRAM;
        } else {
            toolPath = KEXTLOAD_PROGRAM;
        }
        if (execl(toolPath, toolPath, getKextPath(), NULL) < 0) {
            logMsg(@"Execl", errno);
            _exit(EXIT_FAILURE);
        }
    } else {
        int status;
        if (waitpid(pid, &status, 0) < 0) {
            logMsg(@"Waitpid", errno);
            return EXIT_FAILURE;
        };
        
        if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) {
            return EXIT_FAILURE;
        }
    }
    return EXIT_SUCCESS;
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

static int configure() {
    if (!amIRoot()) {
        sudo();
    }
    if (!amIRoot()) {
        notifyNonRoot(__LINE__);
    }
    
    if (chown(getProcessPath(), ROOT_UID, -1) == 0 && chmod(getProcessPath(), FMOD) == 0) {
        if (walkPath(getKextPath(), configureKext)) {
            return 0;
        }
    }

    notifyNonRoot(__LINE__);
    return 1;
}

int main(int argc, const char * argv[]) {
    int retcode = 0;
    @autoreleasepool {
        ACTION_TYPE action = getAction(argc, argv);
        switch (action) {
            case ACTION_LOAD:
                retcode = execKextLoad(false);
                break;
            case ACTION_UNLOAD:
                retcode = execKextLoad(true);
                break;
            case ACTION_CONFIGURE:
                retcode = configure();
                break;
            case ACTION_UNEXPECTED:
            default:
                abortUtility(__LINE__);
                break;
        }
    }
    return retcode;
}
