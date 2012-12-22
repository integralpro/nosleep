//
//  Utilities.c
//  NoSleepFramework
//
//  Created by Pavel Prokofiev on 2/24/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#include <NoSleep/GlobalConstants.h>
#include <Foundation/Foundation.h>
#include <Utilities.h>

BOOL registerLoginItem(LoginItemAction action) {
    UInt32 seedValue;
    LSSharedFileListItemRef existingItem = NULL;
    
    NSURL *itemURL = [NSURL fileURLWithPath:@NOSLEEP_HELPER_PATH];
    
    LSSharedFileListRef loginItemsRefs = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if(!loginItemsRefs) {
        return NO;
    }
    
    NSArray *loginItemsArray = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItemsRefs, &seedValue)) autorelease];  
    for (id item in loginItemsArray) {    
        LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
        
        UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
        CFURLRef URL = NULL;
        OSStatus err = LSSharedFileListItemResolve(itemRef, resolutionFlags, &URL, /*outRef*/ NULL);
        if (err == noErr) {
            Boolean foundIt = CFEqual(URL, itemURL);
            CFRelease(URL);
            
            if (foundIt) {
                existingItem = itemRef;
                break;
            }
        }
    }
    
    if(action == kLICheck) {
        return existingItem != NULL;
    } else if (action == kLIRegister && (existingItem == NULL)) {
        LSSharedFileListInsertItemURL(loginItemsRefs, kLSSharedFileListItemBeforeFirst,
                                      NULL, NULL, (CFURLRef)itemURL, NULL, NULL);
        return YES;
    } else if (action == kLIUnregister && (existingItem != NULL)) {
        LSSharedFileListItemRemove(loginItemsRefs, existingItem);
        return YES;
    }
    
    CFRelease(loginItemsRefs);
    
    return NO;
}
