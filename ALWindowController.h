//
//  ALWindowController.h
//  ActiveLog
//
//  Created by Uncle MiF on 9/10/10.
//  Copyright 2010 Deep IT. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ALWindowController : NSWindowController <NSTableViewDelegate>
{
	NSMutableArray * rApps;
	NSTableView * registeredApps;
	
	NSMutableDictionary * eAppZones;
	NSMutableArray * eZones;// auto, for selected app
	BOOL eZoneSelected;
	NSTableView * enabledZones;
	
	NSButton * persistentCheck;
	
	NSPanel * addZonePanel;
	NSTextField * zoneNameField;
	
	NSMutableDictionary * detectedModules;
}

@property (assign) IBOutlet NSTableView *registeredApps;
@property (assign) IBOutlet NSTableView *enabledZones;
@property (assign) IBOutlet NSButton *persistentCheck;
@property (assign) IBOutlet NSPanel *addZonePanel;
@property (assign) IBOutlet NSTextField *zoneNameField;

-(IBAction)refresh:(id)sender;
-(IBAction)persistentChanged:(id)sender;
-(IBAction)addZone:(id)sender;
-(IBAction)removeZone:(id)sender;
-(IBAction)addZoneFinalize:(id)sender;
-(IBAction)help:(id)sender;

-(void)registeredAppsReloadData;
-(void)setEZoneSelected:(BOOL)flag;

@end
