//
//  nosleep_preferences.h
//  nosleep-preferences
//
//  Created by Pavel Prokofiev on 4/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <NoSleep/NoSleepInterfaceWrapper.h>

@interface NoSleepPreferences : NSPreferencePane <NoSleepNotificationDelegate> {
@private
    NoSleepInterfaceWrapper *m_noSleepInterface;
    BOOL stateAC;
    BOOL stateBattery;
    
    IBOutlet NSButton *m_checkBoxEnableAC;
    IBOutlet NSButton *m_checkBoxEnableBattery;
    IBOutlet NSButton *m_checkBoxShowIcon;
    
    IBOutlet NSTextField *m_lastUpdateDate;
}

- (void)updateEnableState;

- (IBAction)checkboxEnableACClicked:(id)sender;
- (IBAction)checkboxEnableBatteryClicked:(id)sender;
- (IBAction)checkboxShowIconClicked:(id)sender;

- (IBAction)updateNow:(id)sender;
- (BOOL)autoUpdate;
- (void)setAutoUpdate:(BOOL)value;
- (NSString *)lastUpdateDate;

@end
