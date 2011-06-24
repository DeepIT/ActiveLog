//
//  ActiveLogAppDelegate.m
//  ActiveLog
//
//  Created by Uncle MiF on 9/10/10.
//  Copyright 2010 Deep IT. All rights reserved.
//

#import "ActiveLogAppDelegate.h"
#import "DINSLogObserver.h"

@implementation ActiveLogAppDelegate

@synthesize wc;

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSLogDebugMethod;
	[DINSLogObserver setDelegate:wc];
}

-(void)applicationWillTerminate:(NSNotification *)notification
{
	NSLogDebugMethod;
	[DINSLogObserver setDelegate:nil];
}

-(BOOL)applicationOpenUntitledFile:(NSApplication *)sender
{
	[[wc window] makeKeyAndOrderFront:self];
	return YES;
}

@end
