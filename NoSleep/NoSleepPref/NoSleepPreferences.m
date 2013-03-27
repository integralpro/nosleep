//
//  nosleep_preferences.m
//  nosleep-preferences
//
//  Created by Pavel Prokofiev on 4/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NoSleepPreferences.h"
#import <IOKit/IOMessage.h>
#import <NoSleep/GlobalConstants.h>
#import <NoSleep/Utilities.h>
#import <Sparkle/Sparkle.h>

#define NoSleepPrefHelper "NoSleepPrefHelper"

@implementation NoSleepPreferences

- (void)updater:(SUUpdater *)updater didFinishLoadingAppcast:(SUAppcast *)appcast {
    [self didChangeValueForKey:@"lastUpdateDate"];
}

- (SUUpdater *)updater {
    return [SUUpdater updaterForBundle:[NSBundle bundleWithPath:@NOSLEEP_HELPER_PATH]];
}

- (IBAction)updateNow:(id)sender {
    [self willChangeValueForKey:@"lastUpdateDate"];
    [[self updater] checkForUpdates:sender];
}

- (BOOL)autoUpdate {
    return [[self updater] automaticallyChecksForUpdates];
}

- (void)setAutoUpdate:(BOOL)value {
    [[self updater] setAutomaticallyChecksForUpdates:value];
}

- (NSString *)lastUpdateDate {
    if([[self updater] lastUpdateCheckDate] == nil)
        return @"Never";
    
    return [NSDateFormatter localizedStringFromDate:[[self updater] lastUpdateCheckDate]
                                          dateStyle:NSDateFormatterFullStyle
                                          timeStyle:NSDateFormatterFullStyle];
}

- (BOOL)isBWEnabled {
    Boolean b = false;
    Boolean ret = CFPreferencesGetAppBooleanValue(CFSTR(NOSLEEP_SETTINGS_isBWIconEnabledID), CFSTR(NOSLEEP_ID), &b);
    if(b) {
        return ret;
    }
    return NO;
}

- (void)setIsBWEnabled:(BOOL)value {    
    CFPreferencesSetAppValue(CFSTR(NOSLEEP_SETTINGS_isBWIconEnabledID), value?kCFBooleanTrue:kCFBooleanFalse, CFSTR(NOSLEEP_ID));
    CFPreferencesAppSynchronize(CFSTR(NOSLEEP_ID));
    
    NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
    [center postNotificationName: @NOSLEEP_SETTINGS_UPDATE_EVENTNAME
                          object: [NSString stringWithCString:NOSLEEP_ID encoding:NSASCIIStringEncoding]
                        userInfo: nil
              deliverImmediately: YES];
}

- (BOOL)toLockScreen {
    return GetLockScreen();
}

- (void)setToLockScreen:(BOOL)value {
    SetLockScreen(value);
}

- (BOOL)useDoubleClick {
    Boolean b = false;
    Boolean ret = CFPreferencesGetAppBooleanValue(CFSTR(NOSLEEP_SETTINGS_useDoubleClick), CFSTR(NOSLEEP_ID), &b);
    if(b) {
        return ret;
    }
    return NO;
}

- (void)setUseDoubleClick:(BOOL)value {
    CFPreferencesSetAppValue(CFSTR(NOSLEEP_SETTINGS_useDoubleClick), value?kCFBooleanTrue:kCFBooleanFalse, CFSTR(NOSLEEP_ID));
    CFPreferencesAppSynchronize(CFSTR(NOSLEEP_ID));
}

/*
- (BOOL)validateToLockScreen:(BOOL)ioValue error:(NSError * __autoreleasing *)outError {
    BOOL ret;
    
    //char *tmp = getenv("TMPDIR");
    //setenv("TMPDIR", "/tmp/", 1);
    
    NSString *nsValue = ioValue ? @"1" : @"0";
    OSStatus runTaskRes = [authService runTaskForPath:[self authorizedHelperPath]
                                        withArguments:[NSArray arrayWithObjects:@"--set", @NOSLEEP_SETTINGS_toLockScreenID, @"--value", nsValue, nil] output:nil];
    if(runTaskRes != errAuthorizationSuccess) {
        if (outError != NULL) {
            NSString *errorString = @"Your request is not authorized.";
            NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString };
            NSError *error = [[NSError alloc] initWithDomain:@"Authorization"
                                                        code:-1
                                                    userInfo:userInfoDict];
            *outError = error;
        }
        return ret = NO;
    }
    ret = YES;
    
    //setenv("TMPDIR", tmp, 1);
    return ret;
}
*/

- (id)initWithBundle:(NSBundle *)bundle
{
    // Initialize the location of our preferences
    if ((self = [super initWithBundle:bundle]) != nil) {
        m_noSleepInterface = nil;
        
        //authService = [[AuthorizationService alloc] init];
    }
    
    return self;
}

- (void)notificationReceived:(uint32_t)messageType :(void *)messageArgument
{
    [self updateEnableState];
}

- (void)updateEnableState
{
    stateAC = [m_noSleepInterface stateForMode:kNoSleepModeAC];
    stateBattery = [m_noSleepInterface stateForMode:kNoSleepModeBattery];
    [m_checkBoxEnableAC setState:stateAC];
    [m_checkBoxEnableBattery setState:stateBattery];
}

- (void)willSelect
{
    if(m_noSleepInterface == nil) {
         m_noSleepInterface = [[NoSleepInterfaceWrapper alloc] init];   
    }
    
    if([[NSFileManager defaultManager] fileExistsAtPath:@NOSLEEP_HELPER_PATH]) {
        [m_checkBoxShowIcon setEnabled:YES];
        [m_checkBoxShowIcon setState:registerLoginItem(kLICheck)];
        
        [m_checkBoxShowIcon setToolTip:@""];
    } else {
        [m_checkBoxShowIcon setEnabled:NO];
        [m_checkBoxShowIcon setState:NO];
        
        [m_checkBoxShowIcon setToolTip:@"("@NOSLEEP_HELPER_PATH@" not found)"];
    }
    
    if(!m_noSleepInterface) {
        [m_checkBoxEnableAC setEnabled:NO];
        [m_checkBoxEnableAC setState:NO];
        [m_checkBoxEnableBattery setEnabled:NO];
        [m_checkBoxEnableBattery setState:NO];
    } else {
        [m_checkBoxEnableAC setEnabled:YES];
        [m_checkBoxEnableBattery setEnabled:YES];
        [m_noSleepInterface setNotificationDelegate:self];
        [self updateEnableState];
    }
}

- (void)didSelect {
    if(!m_noSleepInterface) {
        SHOW_UI_ALERT_KEXT_NOT_LOADED();           
    }
    
    [[self updater] setDelegate:self];
}

- (void)didUnselect {
    if(!m_noSleepInterface) {
        [m_noSleepInterface release];
        m_noSleepInterface = nil;
    }
    
    [[self updater] setDelegate:nil];
}

- (IBAction)checkboxEnableACClicked:(id)sender {
    BOOL newState = [m_checkBoxEnableAC state];
    if(newState != stateAC) {
        [m_noSleepInterface setState:newState forMode:kNoSleepModeAC];
        stateAC = newState;
    }
}

- (IBAction)checkboxEnableBatteryClicked:(id)sender {
    BOOL newState = [m_checkBoxEnableBattery state];
    if(newState != stateBattery) {
        [m_noSleepInterface setState:newState forMode:kNoSleepModeBattery];
        stateBattery = newState;
    }
}

- (void)checkboxShowIconClicked:(id)sender {
    BOOL showIconState = [m_checkBoxShowIcon state];
    if(showIconState) {
        registerLoginItem(kLIRegister);
    } else {
        registerLoginItem(kLIUnregister);
    }
}

- (NSString *)authorizedHelperPath {
    return [[self bundle] pathForAuxiliaryExecutable:@NoSleepPrefHelper];
}

@end
