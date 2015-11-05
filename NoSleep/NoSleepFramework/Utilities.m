//
//  Utilities.c
//  NoSleepFramework
//
//  Created by Pavel Prokofiev on 2/24/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <NoSleep/GlobalConstants.h>
#import <Foundation/Foundation.h>
#import <Utilities.h>

#define PROGRAM_ARGUMENTS "ProgramArguments"

BOOL GetLockScreenProperty() {
    Boolean valueExist = false;
    Boolean ret = CFPreferencesGetAppBooleanValue(CFSTR(NOSLEEP_SETTINGS_toLockScreenID), CFSTR(NOSLEEP_ID), &valueExist);
    if(valueExist) {
        return ret;
    }
    return NO;
}

void SetLockScreenProperty(BOOL value) {
    CFBooleanRef booleanValue = value ? kCFBooleanTrue : kCFBooleanFalse;
    CFPreferencesSetAppValue(CFSTR(NOSLEEP_SETTINGS_toLockScreenID), booleanValue, CFSTR(NOSLEEP_ID));
    CFPreferencesAppSynchronize(CFSTR(NOSLEEP_ID));
}

void ShowAlertPanel(NSString *title, NSString *message, NSString *button) {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:button];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
}

static NSString *GetLaunchAgentsDitectory() {
    return [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"LaunchAgents"];
}

static NSString *GetApplicationLaunchAgentsPlist(NSBundle *application) {
    NSString *appName = [[application infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSString *plistName = [appName stringByAppendingPathExtension:@"plist"];
    return [GetLaunchAgentsDitectory() stringByAppendingPathComponent:plistName];
}

BOOL IsLaunchdAgentInstalled(NSBundle *application) {
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:GetApplicationLaunchAgentsPlist(application)];
    if (!exist) {
        return NO;
    }
    
    NSDictionary *plist = [[NSDictionary alloc] initWithContentsOfFile:GetApplicationLaunchAgentsPlist(application)];
    NSArray *array = [plist valueForKey:@PROGRAM_ARGUMENTS];
    if (!array) {
        return NO;
    }
    
    id obj = [array firstObject];
    if (!obj) {
        return NO;
    }
    
    NSString *executablePath = obj;
    if ([executablePath compare:[application executablePath]] != kCFCompareEqualTo) {
        return  NO;
    }
    
    return YES;
}

void InstallLaunchdAgent(NSBundle *application) {
    if (!IsLaunchdAgentInstalled(application)) {
        NSString *plistPath = [application pathForResource:@"Launchd" ofType:@"plist"];
        NSDictionary *plist = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
        [plist setValue:[application bundleIdentifier] forKey:@"Label"];
        
        NSMutableArray *arguments = [[NSMutableArray alloc] initWithObjects: [application executablePath], nil];
        [plist setValue:arguments forKey:@PROGRAM_ARGUMENTS];
        
        [plist writeToFile:GetApplicationLaunchAgentsPlist(application) atomically:YES];
    }
}

void UninstallLaunchdAgent(NSBundle *application) {
    if (IsLaunchdAgentInstalled(application)) {
        [[NSFileManager defaultManager] removeItemAtPath:GetApplicationLaunchAgentsPlist(application) error:nil];
    }
}
