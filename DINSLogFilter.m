// COMMON FILE: Common

// (c) 2010, Deep IT, Uncle MiF

#import <Foundation/Foundation.h>

#import "DINSLogFilter.h"

#ifndef DINSLogRemoteDisabled
#import "DINSLogObserver.h"
#endif

// env data
#ifndef LOG_MODULE_VAR
#define LOG_MODULE_VAR "LogModules"
#endif

#ifndef LOG_MODULE_SEPARATOR
#define LOG_MODULE_SEPARATOR @"/"
#endif

#ifndef LOG_MODULE_DEFAULT_ON
#define LOG_MODULE_DEFAULT_ON NO
#endif

//#define DINS_DEBUG
#ifdef DINS_DEBUG
#warning DINSLog: Internal Debug Mode is Enabled
#endif

static BOOL initIsDone = NO;
static NSMutableSet * enabledModules = nil;
static NSMutableDictionary * detectedModules = nil;
static BOOL persistent = NO;

#define DINS_PREF_PERSISTENT @"DINSLogPersistent"
#define DINS_PREF_MODULES @"DINSLogEnabledModules"

static BOOL DINSLogInternalInit(void)
{
	if (enabledModules)
		return YES;
	
	if (initIsDone)
		return NO;
	
	initIsDone = YES;

	NSAutoreleasePool * arp = [NSAutoreleasePool new];

#ifndef DINSLogRemoteDisabled
	NSArray * pm = nil;
	persistent = [[NSUserDefaults standardUserDefaults] boolForKey:DINS_PREF_PERSISTENT];
	if (persistent)
		pm = [[NSUserDefaults standardUserDefaults] objectForKey:DINS_PREF_MODULES];
#endif
	
	char* envModules = getenv(LOG_MODULE_VAR);
	if (envModules)
	{
		enabledModules = [[NSMutableSet setWithArray:[[NSString stringWithUTF8String:envModules] componentsSeparatedByString:LOG_MODULE_SEPARATOR]] retain];
	}
	
#ifndef DINSLogRemoteDisabled
	if (pm)
	{
		if (!enabledModules)
			enabledModules = [[NSMutableSet setWithArray:pm] retain];
		else
			[enabledModules addObjectsFromArray:pm]; 
	}
#endif
			
	[arp drain];
	
	return enabledModules ? YES : NO;
}

#ifndef DINSLogRemoteDisabled		
static void DINSLogInitialize(int unused)  __attribute__((constructor));
void DINSLogInitialize(int unused)
{
	DINSLogInternalInit();	
	if (signal(SIGUSR1, DINSLogInitialize) == SIG_DFL)
	{
		NSLogZoneDebug(DINSLog,NSPF(@"%@",enabledModules));
		[DINSLogObserver registerObserverWithModules:enabledModules];
	}
}

static void DINSLogDeInitialize(int unused) __attribute__((destructor));
void DINSLogDeInitialize(int unused)
{
	if (signal(SIGUSR2, DINSLogDeInitialize) == SIG_DFL)
	{
		[DINSLogObserver unregisterObserver];
	}
}

static void DINSLogRegisterZone(const char* module, const char* zone)
{
	if (![DINSLogObserver isEnabled])
		return;

	NSAutoreleasePool * arp = [NSAutoreleasePool new];
		
	if (!detectedModules)
	{
		@synchronized(@"detectedModules")
		{
			if (!detectedModules)
				detectedModules = [NSMutableDictionary new];
		}
	}
	
	NSString * lastPathComponent = [[[NSString stringWithUTF8String:module] lastPathComponent] stringByDeletingPathExtension];
	if (lastPathComponent)
	{
		@synchronized(detectedModules)
		{
			BOOL changed = NO;
			NSMutableSet * zones = nil;
			if (!(zones = [detectedModules objectForKey:lastPathComponent]))
			{
				[detectedModules setObject:(zones = [NSMutableSet set]) forKey:lastPathComponent];
				changed = YES;
			}
			if (zone)
			{
				NSString * newZone = [NSString stringWithUTF8String:zone];
				if (![zones containsObject:newZone])
				{
					changed = YES;
					[zones addObject:newZone];
				}
			}
			
			if (changed)
			{
#ifndef DINSLogRemoteDisabled
				[DINSLogObserver sendAnnounce:detectedModules forName:LOG_MODULE_ZONES];
#endif
			}
		}
	}
	
	[arp drain];
}
					
static void DINSLogRegisterModule(const char* module)
{
	DINSLogRegisterZone(module, NULL);
}
#endif


@implementation _DINSLogFilter

+(BOOL)isModuleLoggingEnabled:(const char*)moduleZone masterMode:(BOOL)masterMode
{
#ifdef DINS_DEBUG
	fprintf(stderr,"\033[0;37m%s: %s (%i)\033[0m\n",__PRETTY_FUNCTION__,moduleZone,masterMode);
#endif
	
	BOOL res = LOG_MODULE_DEFAULT_ON;
	
	if (!moduleZone)
		return res;
	
#ifdef DINSLogRemoteDisabled
	if (!DINSLogInternalInit())
		return res;
#endif
		
	NSAutoreleasePool * arp = [NSAutoreleasePool new];
	
#ifndef DINSLogRemoteDisabled
	if (masterMode)
	{
		DINSLogRegisterModule(moduleZone);
	}
	
	if (!DINSLogInternalInit())
	{
		[arp drain];
		return res;
	}	
#endif		
	
	if ([enabledModules containsObject:@"*"])
		res = YES;
	else
	{
		NSString * lastPathComponent = [[[NSString stringWithUTF8String:moduleZone] lastPathComponent] stringByDeletingPathExtension];
		res = (lastPathComponent && [enabledModules containsObject:lastPathComponent]);
	}
	
	[arp drain];
	
	return res;
}

+(BOOL)isZoneLoggingEnabled:(const char*)module zoneName:(const char*)zone
{
	if (!module || !zone)
		return LOG_MODULE_DEFAULT_ON;
	
#ifndef DINSLogRemoteDisabled
	DINSLogRegisterZone(module,zone);
#endif	
	return [_DINSLogFilter isModuleLoggingEnabled:zone masterMode:NO];	
}

+(NSSet*)modulesList
{
	NSSet * res = [[enabledModules retain] autorelease];
	if (!res)
		res = [NSSet set];
	return res;	
}

+(NSDictionary*)detectedModulesList
{
	NSDictionary * res = [[detectedModules retain] autorelease];
	if (!res)
		res = [NSDictionary dictionary];
	return res;	
}

+(void)enableModule:(NSString*)module
{
	if (!enabledModules)
	{
		@synchronized(@"enabledModules")
		{
			if (!enabledModules)
				enabledModules = [NSMutableSet new];
		}
	}
	@synchronized(@"enabledModules")
	{
		[enabledModules addObject:module];
#ifndef DINSLogRemoteDisabled
		[[NSUserDefaults standardUserDefaults] setObject:[enabledModules allObjects] forKey:DINS_PREF_MODULES];
		[[NSUserDefaults standardUserDefaults] synchronize];
#endif
	}	
}

+(void)disableModule:(NSString*)module
{
	if (enabledModules)
	{
		@synchronized(@"enabledModules")
		{
			[enabledModules removeObject:module];
#ifndef DINSLogRemoteDisabled
			[[NSUserDefaults standardUserDefaults] setObject:[enabledModules allObjects] forKey:DINS_PREF_MODULES];
			[[NSUserDefaults standardUserDefaults] synchronize];
#endif
		}
	}	
}

+(void)setPersistent:(BOOL)state
{
#ifndef DINSLogRemoteDisabled
	if (persistent == state)
		return;
	persistent = state;
	[[NSUserDefaults standardUserDefaults] setBool:persistent forKey:DINS_PREF_PERSISTENT];
	if (!persistent)
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:DINS_PREF_PERSISTENT];
	else
		[[NSUserDefaults standardUserDefaults] setObject:[enabledModules allObjects] forKey:DINS_PREF_MODULES];
	[[NSUserDefaults standardUserDefaults] synchronize];
#endif	
}

+(BOOL)persistentState
{
	return persistent;
}

+(void)log:(NSString*)fmt,...
{
	va_list ap;
	va_start(ap, fmt);
	NSLogv(fmt, ap);
	va_end(ap);
}

@end