//
//  main.c
//  NoSleepCtrl
//
//  Created by Pavel Prokofiev on 2/23/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <NoSleep/GlobalConstants.h>
#include <NoSleep/NoSleepInterfaceWrapper.h>

int verboseLevel = 1;
bool modeAC = false;
bool modeBattery = false;

bool setNewValue = false;
char *newValue;

static void usage() {
    
}

int main (int argc, const char **argv)
{
    int c;
    
    opterr = 0;
    
    while ((c = getopt (argc, (char *const *)argv, "abs:v:")) != -1)
        switch (c)
    {
        case 'h':
            usage();
            return 0x10;
        case 'v':
            if(optarg != NULL) {
                if(sscanf(optarg, "%d", &verboseLevel) != 1 ||
                   verboseLevel < 0 || verboseLevel > 2) {
                    fprintf (stderr, "Verbose level should be one of [0, 1, 2]\n");
                    usage();
                    return 0x11;
                }
                if(verboseLevel == 2) {
                    NoSleepVerbose = true;
                }
            } else
                verboseLevel = 1;
            break;
        case 'a':
            modeAC = true;
            break;
        case 'b':
            modeBattery = true;
            break;
        case 's':
            setNewValue = true;
            newValue = optarg;
            break;
        case '?':
            if (optopt == 's' || optopt == 'v')
                fprintf (stderr, "Option -%c requires an argument.\n", optopt);
            else if (isprint (optopt))
                fprintf (stderr, "Unknown option `-%c'.\n", optopt);
            else
                fprintf (stderr,
                         "Unknown option character `\\x%x'.\n",
                         optopt);
            return 1;
        default:
            abort();
    }

    //for (index = optind; index < argc; index++)
    //    printf ("Non-option argument %s\n", argv[index]);
    
    NoSleepInterfaceWrapper *interface = [[NoSleepInterfaceWrapper alloc] init];
    if(interface == NULL) {
        fprintf(stderr, "NoSleep extension is not loaded.\n");
        return 0x11;
    }
    
    int ret = 0;
    
    if(setNewValue) {
        bool valueAC;
        bool valueBattery;
        if(modeAC == false || modeBattery == false) {
            if(newValue[0] != '0' && newValue[0] != '1') {
                fprintf(stderr, "Error: input format should be [0, 1]\n");
                ret = 0x12;
            }
            valueAC = newValue[0] == '1' ? true : false;
            valueBattery = valueAC;
        } else {
            if((strlen(newValue) != 3) ||
               (newValue[0] != '0' && newValue[0] != '1') ||
               (newValue[1] != ',') ||
               (newValue[2] != '0' && newValue[2] != '1')) {
                fprintf(stderr, "Error: input format should be [0, 1],[0, 1]\n");
                ret = 0x12;
            }
            valueAC = newValue[0] == '1' ? true : false;
            valueBattery = newValue[2] == '1' ? true : false;
        }
        if(ret == 0) {
            if(modeAC == false && modeBattery == false) {
                [interface setState:valueAC forMode:kNoSleepModeCurrent];
            } else {
                if(modeAC == true) {
                    [interface setState:valueAC forMode:kNoSleepModeAC];
                }
                if(modeBattery == true) {
                    [interface setState:valueBattery forMode:kNoSleepModeBattery];
                }
            }
        }
    } else {
        if(modeAC == false && modeBattery == false) {
            bool current = [interface stateForMode:kNoSleepModeCurrent];
            if(verboseLevel != 0) {
                printf("currentMode:%d\n", current);
            } else {
                printf("%d\n", current);
            }
            ret = current?0:1;
        } else {
            if(modeAC == true) {
                bool currentAC = [interface stateForMode:kNoSleepModeAC];
                if(verboseLevel != 0) {
                    printf("acMode:%d", currentAC);
                } else {
                    printf("%d", currentAC);
                }
                ret |= currentAC ? 0 : 2; 
            }
            if(modeAC == true && modeBattery == true) {
                printf(",");
            }
            if(modeBattery == true) {
                bool currentBattery = [interface stateForMode:kNoSleepModeBattery];
                if(verboseLevel != 0) {
                    printf("batteryMode:%d", currentBattery);
                } else {
                    printf("%d", currentBattery);
                }
                ret |= currentBattery ? 0 : 1;
            }
            printf("\n");
        }
    }

    [interface release];
    return ret;
}

