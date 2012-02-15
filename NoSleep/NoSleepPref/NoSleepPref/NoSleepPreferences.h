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
    BOOL state;
    
    IBOutlet NSButton *m_checkBoxEnable;
    IBOutlet NSButton *m_checkBoxShowIcon;
}

- (IBAction)checkboxEnableClicked:(id)sender;
- (IBAction)checkboxShowIconClicked:(id)sender;

@end
