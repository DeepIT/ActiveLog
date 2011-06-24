//
//  ALWindowController.m
//  ActiveLog
//
//  Created by Uncle MiF on 9/10/10.
//  Copyright 2010 Deep IT. All rights reserved.
//

#import "ALWindowController.h"
#import "DINSLogFilter+Remote.h"
#import "DINSLogObserver.h"
#import "DIContextualMenu.h"

@implementation ALWindowController

@synthesize registeredApps, enabledZones, persistentCheck, addZonePanel, zoneNameField;

-(void)awakeFromNib
{
	rApps = [NSMutableArray new];
	eAppZones = [NSMutableDictionary new];
	detectedModules = [NSMutableDictionary new];
	[self.window setFrameAutosaveName:@"ALMainWindow"];
	[self.window setTitle:[[self.window title] stringByAppendingFormat:@" (%i)",getpid()]];
	[self refresh:self];
}

-(IBAction)refresh:(id)sender
{
	NSLogDebugMethod;
	[self willChangeValueForKey:@"eZones"];
	[eZones autorelease], eZones = nil;
	[self didChangeValueForKey:@"eZones"];
	[enabledZones reloadData];
	[self setEZoneSelected:NO];

	[eAppZones removeAllObjects];
	[rApps removeAllObjects];
	[self registeredAppsReloadData];

	[DINSLogObserver sendCommand:LOG_MODULE_CMD_REFRESH forTarget:nil withOptions:nil];
}

-(IBAction)persistentChanged:(id)sender
{
	NSLogDebugMethod;
	NSInteger row = [registeredApps selectedRow];
	if (row != -1)
	{
		NSString * task = [rApps objectAtIndex:row];
		NSNumber * persistent = [NSNumber numberWithBool:[persistentCheck state]];
		id info = [eAppZones objectForKey:task];
		[info setObject:persistent forKey:LOG_MODULE_PERSISTENT_STATE];
		[DINSLogObserver sendCommand:LOG_MODULE_CMD_PERSISTENT 
																					forTarget:[info objectForKey:LOG_MODULE_PID]
																			withOptions:[NSDictionary dictionaryWithObject:persistent forKey:LOG_MODULE_PERSISTENT_STATE]];
	}
}

-(void)addKnownZone:(id)sender
{
	[zoneNameField setStringValue:@""];
	[addZonePanel makeKeyAndOrderFront:self];
}

-(void)addDetectedZone:(id)sender
{
	[zoneNameField setStringValue:[sender title]];
	[self addZoneFinalize:self];
}

-(NSArray*)orderedObjects:(NSArray*)strArr
{
	if (!strArr)
		return strArr;
	return [strArr sortedArrayUsingSelector:@selector(compare:)];
}

-(IBAction)addZone:(id)sender
{
	NSLogDebug(NSPF(@"detectedModules: %@",detectedModules));
	if (!eZones)
		return;
	if (sender)
		return [self performSelector:_cmd withObject:nil afterDelay:0.0];
	
	NSInteger selectedRow = [registeredApps selectedRow];
	if (selectedRow == -1)
		return;
	
	NSString * task = [rApps objectAtIndex:selectedRow];
	if (!task)
		return;
	
	NSMenuItem * detectedZonesItem = [DIContextualMenu itemWithTitle:@"Known Zone" action:@selector(addKnownZone:) keyEquivalent:@""];

	DIContextualMenu* contextualMenu = 
	[DIContextualMenu contextualMenuWithDelegate:self andItems:
		[NSArray arrayWithObjects:
			detectedZonesItem,
			nil
			]
		];	
	
	DIContextualMenu * detectedZones = [DIContextualMenu contextualMenuWithDelegate:self];
	
	NSArray * modules = [self orderedObjects:[[detectedModules objectForKey:task] allKeys]];
	for (NSString* module in modules)
	{
		if ([eZones containsObject:module])
			continue;
		
		NSMenuItem * moduleItem = [DIContextualMenu itemWithTitle:module action:@selector(addDetectedZone:) keyEquivalent:@""];
		[detectedZones addItem:moduleItem];

		NSArray * zones = [self orderedObjects:[[[detectedModules objectForKey:task] objectForKey:module] allObjects]];
		if (zones)
		{
			DIContextualMenu * deepZones = [DIContextualMenu contextualMenuWithDelegate:self];
			
			for (NSString* zone in zones)
			{
				if ([eZones containsObject:zone])
					continue;
				
				NSMenuItem * zoneItem = [DIContextualMenu itemWithTitle:zone action:@selector(addDetectedZone:) keyEquivalent:@""];
				[deepZones addItem:zoneItem];
			}
			
			if ([deepZones numberOfItems])
				[detectedZones setSubmenu:[deepZones menu] forItem:moduleItem];							
		}
	}
			
	if ([detectedZones numberOfItems])
	{
		[contextualMenu setSubmenu:[detectedZones menu] forItem:detectedZonesItem];
		[contextualMenu showMenuInWindow:self.window];
	}
	else
		[self addKnownZone:self];
}

-(IBAction)addZoneFinalize:(id)sender
{
	NSLogDebugMethod;
	[addZonePanel orderOut:self];
	NSString * zone = [zoneNameField stringValue];
	if (![eZones containsObject:zone])
	{
		NSInteger row = [registeredApps selectedRow];
		if (row != -1)
		{
			NSTask * task = [rApps objectAtIndex:row];
			NSMutableDictionary * info = [eAppZones objectForKey:task];
			NSString * target = [info objectForKey:LOG_MODULE_PID];

			id announceObject = [info objectForKey:LOG_MODULE_ANNOUNCE_OBJECT];
			if ([announceObject isKindOfClass:[NSString class]])
				[info setObject:(announceObject = [NSMutableSet set]) forKey:LOG_MODULE_ANNOUNCE_OBJECT];
			if (![announceObject isKindOfClass:[NSMutableSet class]])
				[info setObject:(announceObject = [[announceObject mutableCopy] autorelease]) forKey:LOG_MODULE_ANNOUNCE_OBJECT];
						
			[announceObject addObject:zone];// module set
			[eZones addObject:zone];
			[enabledZones reloadData];
			
			[DINSLogObserver sendCommand:LOG_MODULE_CMD_ENABLE forTarget:target 
																				withOptions:[NSDictionary dictionaryWithObject:zone forKey:LOG_MODULE_NAME]];
		}
	}
}

-(IBAction)removeZone:(id)sender
{
	NSLogDebugMethod;
	if (!eZones)
		return;
	NSInteger row = [enabledZones selectedRow];
	if (row != -1)
	{
		NSString * zone = [eZones objectAtIndex:row];

		row = [registeredApps selectedRow];
		if (row != -1)
		{
			NSTask * task = [rApps objectAtIndex:row];
			NSMutableDictionary * info = [eAppZones objectForKey:task];
			NSString * target = [info objectForKey:LOG_MODULE_PID];

			[DINSLogObserver sendCommand:LOG_MODULE_CMD_DISABLE forTarget:target 
																				withOptions:[NSDictionary dictionaryWithObject:zone forKey:LOG_MODULE_NAME]];
			
			id announceObject = [info objectForKey:LOG_MODULE_ANNOUNCE_OBJECT];
			if (![announceObject isKindOfClass:[NSMutableSet set]])
				[info setObject:(announceObject = [[announceObject mutableCopy] autorelease]) forKey:LOG_MODULE_ANNOUNCE_OBJECT];
			
			[announceObject removeObject:zone];// module set
			[eZones removeObject:zone];
			[enabledZones reloadData];
			if ([eZones count])
			{
				if (row >= [eZones count])
					row = [eZones count] - 1;
				[enabledZones selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
			}
		}
	}
}

-(NSString*)processKey:(NSDictionary*)info
{
	return [NSString stringWithFormat:@"%@ (%@)",[[info objectForKey:LOG_MODULE_PATH] lastPathComponent],[info objectForKey:LOG_MODULE_PID]];
}

-(void)registeredAppsReloadData
{
	NSLogDebugMethod;
	[registeredApps reloadData];
	NSInteger selectedRow = [registeredApps selectedRow];
	if (selectedRow == -1)
	{
		if ([rApps count])
			[registeredApps selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}
	else
		if (!eZones)
			[self tableViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification object:registeredApps]];
}

-(BOOL)processAnnounce:(NSDictionary*)info
{
	NSLogZoneDebug(ActiveLog,NSPF(@"%@",info));
	
	id announceObject = [info objectForKey:LOG_MODULE_ANNOUNCE_OBJECT];
	if ([[info objectForKey:LOG_MODULE_ANNOUNCE_NAME] isEqualToString:LOG_MODULE_REGISTER])
	{
		NSLogZoneDebug(ActiveLog,NSPF(@"register: %@",announceObject));
		NSString * task = [self processKey:info]; 
		[eAppZones setValue:info forKey:task];
		if (![rApps containsObject:task])
			[rApps addObject:task];
		[detectedModules setObject:[info objectForKey:LOG_MODULE_ZONES] forKey:task];
		[self registeredAppsReloadData];
	}
	else
	if ([[info objectForKey:LOG_MODULE_ANNOUNCE_NAME] isEqualToString:LOG_MODULE_UNREGISTER])
	{
		NSLogZoneDebug(ActiveLog,NSPF(@"unregister: %@",announceObject));
		NSString * task = [self processKey:info];
		if ([registeredApps selectedRow] == -1 || [registeredApps selectedRow] == [rApps indexOfObject:task])
		{
			[self willChangeValueForKey:@"eZones"];
			[eZones autorelease], eZones = nil;
			[self didChangeValueForKey:@"eZones"];
			[enabledZones reloadData];
			[self setEZoneSelected:NO];
		}
		[rApps removeObject:task];
		[eAppZones removeObjectForKey:task];
		[detectedModules removeObjectForKey:task];
		[self registeredAppsReloadData];
	}
	else
	if ([[info objectForKey:LOG_MODULE_ANNOUNCE_NAME] isEqualToString:LOG_MODULE_ZONES])
	{
		NSString * task = [self processKey:info];
		[detectedModules setObject:announceObject forKey:task];
	}
			
	return NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == registeredApps)
		return [rApps count];
	if (aTableView == enabledZones)
		return [eZones count];

	NSLogDebug(NSPF(@"unknown table %@",aTableView));
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (aTableView == registeredApps)
	{
		return [rApps objectAtIndex:rowIndex];
	}
	if (aTableView == enabledZones)
	{
		return [eZones objectAtIndex:rowIndex];
	}
	
	NSLogDebug(NSPF(@"unknown table %@",aTableView));
	return nil;	
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSLogDebugMethod;
	if ([aNotification object] == registeredApps)
	{
		NSInteger row = [registeredApps selectedRow];
		if (row != -1)
		{
			NSString * task = [rApps objectAtIndex:row];
			NSDictionary * info = [eAppZones objectForKey:task];
			id infoObject = [info objectForKey:LOG_MODULE_ANNOUNCE_OBJECT];
			[self willChangeValueForKey:@"eZones"];
			[eZones autorelease];
			eZones = [infoObject isKindOfClass:[NSSet class]] ? 
					[[infoObject allObjects] mutableCopy] : [NSMutableArray new];
			[self didChangeValueForKey:@"eZones"];
			[enabledZones reloadData];
			[self setEZoneSelected:[enabledZones selectedRow] != -1];
			[persistentCheck setState:[[info objectForKey:LOG_MODULE_PERSISTENT_STATE] boolValue]];
		}
	}
	else if ([aNotification object] == enabledZones)
	{
		[self setEZoneSelected:[enabledZones selectedRow] != -1];
	}
}

-(void)setEZoneSelected:(BOOL)flag;// auto KVO
{
	eZoneSelected = flag;
}

-(IBAction)help:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://deepitpro.com/en/articles/ActiveLog/info/"]];
}

@end
