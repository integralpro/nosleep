//
//  AuthorizeService.h
//  NoSleep
//
//  Created by Pavel Prokofiev on 12/25/12.
//
//

#import <Foundation/Foundation.h>

@interface AuthorizationService : NSObject {
@private
    AuthorizationRef authorizationRef;
}

@property (assign) BOOL scriptRunning;

- (OSStatus)authorize;
- (OSStatus)runTaskForPath:(NSString *)path
             withArguments:(NSArray *)arguments
                    output:(NSData **)output;

@end
