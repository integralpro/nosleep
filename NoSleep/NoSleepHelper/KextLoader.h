//
//  KextLoader.h
//  NoSleep
//
//  Created by Pavel Prokofiev on 25/06/15.
//
//

#import <Foundation/Foundation.h>

#define KEXTUTILITY_NAME "KextUtility"

@interface KextLoader : NSObject

+ (BOOL)loadKext;
+ (BOOL)unloadKext;

@end
