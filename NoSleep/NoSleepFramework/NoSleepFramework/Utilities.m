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
    
    LSSharedFileListRef loginItemsRefs = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    NSArray *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItemsRefs, &seedValue);  
    for (id item in loginItemsArray) {    
        LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
        NSString *displayName = (NSString *)LSSharedFileListItemCopyDisplayName(itemRef);
        if([[@NOSLEEP_HELPER_PATH lastPathComponent] isEqualToString:displayName]) {
            //CFURLRef path;
            //if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*)&path, NULL) == noErr) {
               // NSString *url = [(NSURL *)path path];
                //if ([url isEqualToString:@NOSLEEP_HELPER_PATH]) {
                    // if exists
                    if(action == kLIUnregister) {
                        LSSharedFileListItemRemove(loginItemsRefs, itemRef);
                    }
                    
                    return YES;
                //}
                //CFRelease(path);
            //}
        }
        [displayName release];
    }
    
    if(action == kLIRegister) {
        //CFURLRef url1 = (CFURLRef)[[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:NOSLEEP_HELPER_IDENTIFIER];
        //NSURL *url11 = (NSURL*)url1;
        NSURL *url = [[NSURL alloc] initFileURLWithPath:@NOSLEEP_HELPER_PATH];
        
        LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItemsRefs, kLSSharedFileListItemLast,
                                                                     NULL, NULL, (CFURLRef)url, NULL, NULL);
        
        if (item) {
            CFRelease(item);
        }
    }
    
    return NO;
}
