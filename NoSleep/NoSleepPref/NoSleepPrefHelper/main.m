//
//  main.c
//  NoSleepPrefHelper
//
//  Created by Pavel Prokofiev on 12/25/12.
//
//

#import <CoreFoundation/CoreFoundation.h>
#import <NoSleep/GlobalConstants.h>
#import <NoSleep/Utilities.h>
#import <getopt.h>
#import <stdio.h>


void usage() {

}

int main(int argc, const char **argv)
{
    int rc = 0;
    
    static struct option kLongOpts[] = {
        { "set",           required_argument, NULL, 's' },
        { "value",         required_argument, NULL, 'v' },
        {  NULL,           0,                 NULL,  0  },
    };
    
    char *option = NULL;
    char *value = NULL;
    char ch;
    while ((ch = getopt_long(argc, (char * const *)argv, "s:v:", kLongOpts, NULL)) != -1) {
        switch (ch) {
            case 's':
                option = optarg;
                break;
            case 'v':
                value = optarg;
                break;
            default:
                usage();
                goto done;
        }
    }
    
    if(option != NULL && value != NULL) {
        CFStringRef optionRef = CFStringCreateWithCString(kCFAllocatorDefault, option, kCFStringEncodingASCII);
        
        if(CFStringCompare(CFSTR(NOSLEEP_SETTINGS_toLockScreenID), optionRef, 0) == kCFCompareEqualTo) {
            SetLockScreen(value[0] != '0');
        }
        
        CFRelease(optionRef);
    } else {
        usage();
    }
    
done:
    return rc;
}

