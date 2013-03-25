//
//  Log.h
//  NoSleep
//
//  Created by Pavel Prokofiev on 3/25/13.
//
//

#ifndef NoSleep_Log_h
#define NoSleep_Log_h

#define USE_SYSLOG

#if defined(USE_SYSLOG)
#import <syslog.h>
#else
#define openlog()
#define closelog()
#define syslog()
#endif

#define log(x) printf("%s\n", (x)); syslog(LOG_INFO, (x))

#endif
