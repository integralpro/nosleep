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

@implementation NoSleepPreferences

typedef enum {
    kLICheck    = 0,
    kLIRegister,
    kLIUnregister,
} LoginItemAction;

- (BOOL)loginItem:(LoginItemAction)action {
    UInt32 seedValue;
    
    LSSharedFileListRef loginItemsRefs = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    NSArray *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItemsRefs, &seedValue);  
    for (id item in loginItemsArray) {    
        LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
        CFURLRef path;
        if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*)&path, NULL) == noErr) {
            if ([[(NSURL *)path path] isEqualToString:@NOSLEEP_HELPER_PATH]) {
                // if exists
                if(action == kLIUnregister) {
                    LSSharedFileListItemRemove(loginItemsRefs, itemRef);
                }
                
                return YES;
            }
            CFRelease(path);
        }
    }
    
    if(action == kLIRegister) {
        //CFURLRef url1 = (CFURLRef)[[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:NOSLEEP_HELPER_IDENTIFIER];
        //NSURL *url11 = (NSURL*)url1;
        NSURL *url = [[NSURL alloc] initFileURLWithPath:@"/Library/Application Support/nosleep/NoSleepHelper.app"];
        
        LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItemsRefs, kLSSharedFileListItemLast,
                                                                     NULL, NULL, (CFURLRef)url, NULL, NULL);
        
        if (item) {
            CFRelease(item);
        }
    }
    
    return NO;
}

- (id)initWithBundle:(NSBundle *)bundle
{
    // Initialize the location of our preferences
    if ((self = [super initWithBundle:bundle]) != nil) {
        m_noSleepInterface = nil;
    }
    
    return self;
}

- (void)setEnable:(BOOL)isEnable
{
    [m_checkBoxEnable setEnabled:isEnable];
    [m_checkBoxShowIcon setEnabled:isEnable];
}

- (void)notificationReceived:(uint32_t)messageType :(void *)messageArgument
{
    switch (messageType) {
        case kNoSleepCommandDisabled:
            state = NO;
            break;
        case kNoSleepCommandEnabled:
            state = YES;
            break;
        default:
            break;
    }
    [m_checkBoxEnable setState:state];
}

- (void)updateEnableState
{
    state = [m_noSleepInterface state];
    [m_checkBoxEnable setState:state];
}

- (void)willSelect
{
    if(m_noSleepInterface == nil) {
         m_noSleepInterface = [[NoSleepInterfaceWrapper alloc] init];   
    }
    
    NSString *ns = NOSLEEP_HELPER_IDENTIFIER;
    if([[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:ns] == nil) {
        [m_checkBoxShowIcon setEnabled:NO];
        [m_checkBoxShowIcon setState:NO];
    } else {
        [m_checkBoxShowIcon setEnabled:YES];
        [m_checkBoxShowIcon setState:[self loginItem:kLICheck]];
    }
    
    if(!m_noSleepInterface) {
        [self setEnable:NO];         
    } else {
        [self setEnable:YES];
        [m_noSleepInterface setNotificationDelegate:self];
        [self updateEnableState];
    }
}

- (void)didSelect {
    if(!m_noSleepInterface) {
        SHOW_UI_ALERT_KEXT_NOT_LOADED();           
    }
}

- (void)didUnselect {
    if(!m_noSleepInterface) {
        [m_noSleepInterface release];
    }
}

- (IBAction)checkboxEnableClicked:(id)sender {
    BOOL newState = [m_checkBoxEnable state];
    if(newState != state) {
        [m_noSleepInterface setState:newState];
        state = newState;
    }
}

/*
#define kAgentActionLoad "load"
#define kAgentActionUnload "unload"
static void performAgentAction(const char *action)
{
    if (fork() == 0) {
        execlp("launchctl", action, "", NULL);
    }
}
*/

- (void)checkboxShowIconClicked:(id)sender {
    BOOL showIconState = [m_checkBoxShowIcon state];
    if(showIconState) {
        [self loginItem:kLIRegister];
    } else {
        [self loginItem:kLIUnregister];
    }
}

@end
