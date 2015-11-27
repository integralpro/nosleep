//
//  AppDelegate.m
//  PayPalButton
//
//  Created by Pavel Prokofiev on 11/26/15.
//  Copyright © 2015 Pavel Prokofiev. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSString *url = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"PayPalUrl"];
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

@end
