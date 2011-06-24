// COMMON FILE: Common

//
//  DINSLogObserver.m
//  MDict
//
//  Created by Uncle MiF on 9/10/10.
//  Copyright 2010 Deep IT. All rights reserved.
//

#ifndef DINSLogRemoteDisabled

#import "DINSLogObserver.h"
#import "DINSLogFilter.h"
#import <crt_externs.h>

// info
#define LOG_MODULE_EXECUTABLE_PID [NSString stringWithFormat:@"%i",getpid()]
#define LOG_MODULE_EXECUTABLE_PATH [NSString stringWithUTF8String:**(_NSGetArgv())]

static id<DINSLogObserverProtocol> _delegate = nil;

static BOOL isEnabled = 
#ifdef DINSLogDisabledOnStart
NO
#else
YES
#endif
;

@implementation DINSLogObserver

+(void)announce:(NSNotification*)aNotification
{
	if (!isEnabled)
		return;
	
	NSAutoreleasePool * arp = [NSAutoreleasePool new];
	
#ifndef DINSLogSelfAnnounce
	if ([[aNotification object] isEqualTo:LOG_MODULE_EXECUTABLE_PID])
	{
		[arp drain];
		return;
	}
#else
#warning DIALog: Self Announce is Enabled
#endif
	
	NSLogZoneDebug(DINSLog,NSPF(@"%@",aNotification));
	
	NSMutableDictionary * info = [[[aNotification userInfo] mutableCopy] autorelease];
	id announceObject;
	if ([info isKindOfClass:[NSDictionary class]] && (announceObject = [info objectForKey:LOG_MODULE_ANNOUNCE_OBJECT]) &&
					[announceObject isKindOfClass:[NSData class]] && (announceObject = [NSUnarchiver unarchiveObjectWithData:announceObject]))
		[info setObject:announceObject forKey:LOG_MODULE_ANNOUNCE_OBJECT];
	else
		announceObject = [info objectForKey:LOG_MODULE_ANNOUNCE_OBJECT];

	id dModules;
	if ([info isKindOfClass:[NSDictionary class]] && (dModules = [info objectForKey:LOG_MODULE_ZONES]) &&
					[dModules isKindOfClass:[NSData class]] && (dModules = [NSUnarchiver unarchiveObjectWithData:dModules]))
		[info setObject:dModules forKey:LOG_MODULE_ZONES];
	
	NSLogZoneDebug(DINSLog,NSPF(@"announceObject (%i) = %@",[announceObject isKindOfClass:[NSDictionary class]],announceObject));

	id target = nil;
	if (
					(([announceObject isKindOfClass:[NSDictionary class]] && (target = [announceObject objectForKey:LOG_MODULE_COMMAND_TARGET]) && [target isEqualTo:LOG_MODULE_EXECUTABLE_PID]) 
						|| !target)
					&&
		(!_delegate || ![_delegate respondsToSelector:@selector(processAnnounce:)] || ![_delegate processAnnounce:info])
					)
	{
		// default reaction
		NSLogZoneDebug(DINSLog,NSPF(@"default reaction: %@",info));
		
		if ([[info objectForKey:LOG_MODULE_ANNOUNCE_NAME] isEqualToString:LOG_MODULE_COMMAND])
		{
			id command = [announceObject objectForKey:LOG_MODULE_COMMAND];
			if ([command isEqualToString:LOG_MODULE_CMD_REFRESH])
			{
				NSLogZoneDebug(DINSLog,NSPF(@"refresh"));
				[self sendAnnounce:[self modulesList] forName:LOG_MODULE_REGISTER];
			}
			
			else
				
			if ([command isEqualToString:LOG_MODULE_CMD_ENABLE])
			{
				NSString * module = [[announceObject objectForKey:LOG_MODULE_COMMAND_OPTIONS] objectForKey:LOG_MODULE_NAME];
				if (module)
				{
					NSLogZoneDebug(DINSLog,NSPF(@"enable %@",module));
					[_DINSLogFilter enableModule:module];
				}
			}			
			else
			if ([command isEqualToString:LOG_MODULE_CMD_DISABLE])
			{
				NSString * module = [[announceObject objectForKey:LOG_MODULE_COMMAND_OPTIONS] objectForKey:LOG_MODULE_NAME];
				if (module)
				{
					NSLogZoneDebug(DINSLog,NSPF(@"disable %@",module));
					[_DINSLogFilter disableModule:module];
				}
			}
			else
			if ([command isEqualToString:LOG_MODULE_CMD_PERSISTENT])
			{
				BOOL state = [[[announceObject objectForKey:LOG_MODULE_COMMAND_OPTIONS] objectForKey:LOG_MODULE_PERSISTENT_STATE] boolValue];
				[_DINSLogFilter setPersistent:state];
			}			
		}
	}
	
	[arp drain];
}

+(void)sendAnnounce:(id)announceObject forName:(NSString*)announceName
{
	if (!isEnabled)
		return;
	
	if (!announceName)
		return;
	
	NSAutoreleasePool * arp = [NSAutoreleasePool new];
	
	if (!announceObject)
		announceObject = @"";

	NSLogZoneDebug(DINSLog,NSPF(@"%@ -> %@",announceName,announceObject));
	
	announceObject = [NSArchiver archivedDataWithRootObject:announceObject];
	
	NSMutableDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:
																															announceName,LOG_MODULE_ANNOUNCE_NAME,
																															announceObject,LOG_MODULE_ANNOUNCE_OBJECT,
																															LOG_MODULE_EXECUTABLE_PID,LOG_MODULE_PID,
																															LOG_MODULE_EXECUTABLE_PATH,LOG_MODULE_PATH,
																															[NSNumber numberWithBool:[_DINSLogFilter persistentState]],LOG_MODULE_PERSISTENT_STATE,
																															[NSArchiver archivedDataWithRootObject:[self detectedModulesList]],LOG_MODULE_ZONES,
																															nil];
	
	NSNotification * nt = [NSNotification notificationWithName:LOG_MODULE_ANNOUNCE_REQUEST object:LOG_MODULE_EXECUTABLE_PID userInfo:info];
	[[NSDistributedNotificationCenter defaultCenter] postNotification:nt];
	
	[arp drain];
}

+(void)sendCommand:(NSString*)command forTarget:(NSString*)target withOptions:(NSDictionary*)options
{
	if (!isEnabled)
		return;
	
	if (!command)
		return;
	NSLogZoneDebug(DINSLog,NSPF(@"%@ ->> ... %@ ... <<- %@",command,target,options));
	NSMutableDictionary * req = [NSMutableDictionary dictionary];
	[req setObject:command forKey:LOG_MODULE_COMMAND];
	if (target)
		[req setObject:target forKey:LOG_MODULE_COMMAND_TARGET];	
	if (options)
		[req setObject:options forKey:LOG_MODULE_COMMAND_OPTIONS];
	
	[self sendAnnounce:req forName:LOG_MODULE_COMMAND];
}

static BOOL isRegistered = NO;

+(void)registerObserverWithModules:(NSSet*)modulesList
{
	if (isRegistered)
		return;
	
	if (!isEnabled)
		return;
	
	NSLogZoneDebug(DINSLog,NSPF(@"%@",modulesList));

	NSAutoreleasePool * arp = [NSAutoreleasePool new];
	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:[DINSLogObserver class] 
																																																					selector:@selector(announce:) 
																																																									name:LOG_MODULE_ANNOUNCE_REQUEST 
																																																							object:nil
																																											suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately
		];
	[DINSLogObserver sendAnnounce:modulesList forName:LOG_MODULE_REGISTER];

	[arp drain];
	
	isRegistered = YES;
}

+(void)unregisterObserver
{
	if (!isRegistered)
		return;
	
	if (!isEnabled)
		return;
	
	NSLogZoneDebugMethod(DINSLog);
	
	NSAutoreleasePool * arp = [NSAutoreleasePool new];

	[[NSDistributedNotificationCenter defaultCenter] removeObserver:[DINSLogObserver class]];
	[DINSLogObserver sendAnnounce:nil forName:LOG_MODULE_UNREGISTER];

	[arp drain];
	
	isRegistered = NO;
}

+(void)setDelegate:(id)delegate
{
	_delegate = delegate;
}

+(NSSet*)modulesList
{
	NSLogZoneDebug(DINSLog,NSPF(@"%@",[_DINSLogFilter modulesList]));
	return [_DINSLogFilter modulesList];
}

+(NSDictionary*)detectedModulesList
{
	return [_DINSLogFilter detectedModulesList];
}

+(void)setEnabled:(BOOL)flag
{
	NSAutoreleasePool * arp = [NSAutoreleasePool new];
	
	BOOL stateChanged = isEnabled != flag;
	if (flag)
		isEnabled = flag;
	if (stateChanged)
	{
		if (flag)
			[self registerObserverWithModules:[_DINSLogFilter modulesList]];
		else
			[self unregisterObserver];
	}
	if (!flag)
		isEnabled = flag;
	
	[arp drain];
}

+(BOOL)isEnabled
{
	return isEnabled;
}

@end

#endif