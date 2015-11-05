//
//  PreferencesController.m
//  NoSleep
//
//  Created by Pavel Prokofiev on 11/4/15.
//
//

#import "PreferencesController.h"
#import <PreferencePanes/PreferencePanes.h>

@interface PreferencesController ()

@end

@implementation PreferencesController

- (void)windowDidLoad {
    NSString *pathToPrefPaneBundle = [[NSBundle mainBundle]
                                      pathForResource: @"NoSleep" ofType: @"prefPane"];
    NSBundle *prefBundle = [NSBundle bundleWithPath: pathToPrefPaneBundle];
    Class prefPaneClass = [prefBundle principalClass];
    preferencePane = [[prefPaneClass alloc] initWithBundle:prefBundle];
    [preferencePane loadMainView];
    
    [self.window setDelegate:self];
    [super windowDidLoad];
}

+ (nonnull PreferencesController *)create {
    return [[PreferencesController alloc] initWithWindowNibName:@"PreferencesController"];
}

- (void)close {
    [self.window setDelegate:nil];
    [super close];
}

- (IBAction)showWindow:(id)sender {
    [self.window center];
    [super showWindow:sender];
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
    if (!_mainView) {
        [preferencePane willSelect];
        _mainView = [preferencePane mainView];
        [self.window setContentSize:_mainView.frame.size];
        [self.window setContentView:_mainView];
        [preferencePane didSelect];
    }
}

- (BOOL)windowShouldClose:(id)sender {
    if ([preferencePane shouldUnselect] != NSTerminateCancel) {
        return YES;
    } else {
        return NO;
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    [preferencePane willUnselect];
    [preferencePane didUnselect];
    _mainView = nil;
}

@end
