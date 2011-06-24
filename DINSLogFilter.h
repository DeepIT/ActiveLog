// COMMON FILE: Common

// (c) 2010-2011, Deep IT, Uncle MiF

/*
	Customizes NSLog behavior for DEBUG session (-DDEBUG flag, or -DFORCE_LOGS)
	Activates only enabled mudules' logs or zones while debugging

	Include ColorLog after DIALog header to enable integration

	#define FORCE_SILENT_DEBUG
	to turn off Debug logs

	Add -DDONT_CHECK_FORMAT to C-Flags to disable format-related warnings while ColorLog integration
	but be aware abd double check security before!

	Install: simple add to the .pch file or to any .m files directly
	Make sure that the pch file (if used) is configured as GCC_PREFIX_HEADER
	
	Usage: NSLog(fmt,...), NSLogDebug(fmt,...), NSLogZone(zone,fmt,...), NSLogZoneDebug(zone,fmt,...)
	
	Be aware: internals use SIGUSR1 & SIGUSR2 as "once locks"
*/

#import <Foundation/Foundation.h>

#define NSPF(fmt,...) @"%s " fmt, __PRETTY_FUNCTION__, ##__VA_ARGS__
#define NSPFS(fmt,...) @"%s %p " fmt, __PRETTY_FUNCTION__, self, ##__VA_ARGS__

#define NSLogDebugMethod NSLogDebug(NSPF())
#define NSLogDebugMethodSelf NSLogDebug(NSPFS())
#define NSLogZoneDebugMethod(zone) NSLogZoneDebug(zone, NSPF())
#define NSLogZoneDebugMethodSelf(zone) NSLogZoneDebug(zone, NSPFS())

#define DINSLogFilter

#if (defined (DEBUG) || defined (FORCE_LOGS)) && ! defined FORCE_SILENT_DEBUG

#define NSLog(fmt, ...) do { if ([_DINSLogFilter isModuleLoggingEnabled:__FILE__ masterMode:YES]) { [_DINSLogFilter log: (fmt), ##__VA_ARGS__ ]; } } while(0)
#define NSLogZone(zone,fmt, ...) do { if ([_DINSLogFilter isModuleLoggingEnabled:__FILE__ masterMode:YES] || [_DINSLogFilter isZoneLoggingEnabled:__FILE__ zoneName:#zone]) { [_DINSLogFilter log: (fmt), ##__VA_ARGS__ ]; } } while(0)

#define NSLogDebug(fmt, ...) NSLog( fmt, ##__VA_ARGS__ )
#define NSLogZoneDebug(zone,fmt, ...) NSLogZone( zone, fmt, ##__VA_ARGS__ )

#else

#define NSLog(fmt, ...) do { [_DINSLogFilter log: (fmt), ##__VA_ARGS__ ]; } while(0)
#define NSLogZone(zone,fmt, ...) do { [_DINSLogFilter log: (fmt), ##__VA_ARGS__ ]; } while(0)

#define NSLogDebug(...) {}
#define NSLogZoneDebug(...) {}

#endif

@interface _DINSLogFilter : NSObject
{
}

+(BOOL)isModuleLoggingEnabled:(const char*)moduleZone masterMode:(BOOL)masterMode;
+(BOOL)isZoneLoggingEnabled:(const char*)module zoneName:(const char*)zone;

+(NSSet*)modulesList;
+(NSDictionary*)detectedModulesList;

+(void)enableModule:(NSString*)module;
+(void)disableModule:(NSString*)module;

+(void)setPersistent:(BOOL)state;
+(BOOL)persistentState;

+(void)log:(NSString*)fmt,...
#ifndef DONT_CHECK_FORMAT
__attribute__((format(__NSString__, 1, 2)));
#else
;
#endif

@end
