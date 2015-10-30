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

#import <xpc/xpc.h>

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

NSString *GetLaunchAgentsDitectory() {
    return [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"LaunchAgents"];
}

NSString *GetApplicationLaunchAgentsPlist(NSBundle *application) {
    NSString *appName = [[application infoDictionary] objectForKey:@"CFBundleName"];
    NSString *plistName = [[appName stringByAppendingString:@"-Launchd"] stringByAppendingPathExtension:@"plist"];
    return [GetLaunchAgentsDitectory() stringByAppendingPathComponent:plistName];
}

BOOL IsLaunchdAgentInstalled(NSBundle *application) {
    return [[NSFileManager defaultManager] fileExistsAtPath:GetApplicationLaunchAgentsPlist(application)];
}

void InstallLaunchdAgent(NSBundle *application) {
    if (!IsLaunchdAgentInstalled(application)) {
        NSString *plistPath = [application pathForResource:@"Launchd" ofType:@"plist"];
        NSDictionary *plist = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
        [plist setValue:[application bundleIdentifier] forKey:@"Label"];
        
        NSMutableArray *arguments = [plist objectForKey:@"ProgramArguments"];
        [arguments addObject:[application executablePath]];
        
        [plist writeToFile:GetApplicationLaunchAgentsPlist(application) atomically:YES];
    }
}
