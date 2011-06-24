// COMMON FILE: Common

//
//  DIContextualMenu.m
//  MDict
//
//  Created by Uncle MiF on 6/28/10.
//  Copyright 2010 Deep IT. All rights reserved.
//

#import "DIContextualMenu.h"
#import <Carbon/Carbon.h>

@implementation DIContextualMenu

-(void)dealloc
{
	[menu release];
	[super dealloc];
}

+(id)contextualMenuWithDelegate:(id)aDelegate
{
	return [[[[self class] alloc] initMenuWithDelegate:aDelegate andItems:nil] autorelease];
}

+(id)contextualMenuWithDelegate:(id)aDelegate andItems:(NSArray*)items
{
	return [[[[self class] alloc] initMenuWithDelegate:aDelegate andItems:items] autorelease];
}

-(id)init
{
	self = [super init];
	if (self)
	{
		menu = [NSMenu new];
	}
	return self;
}

-(void)addItems:(NSArray*)items
{
	if (!items)
		return;
	for (NSMenuItem * item in items)
		[self addItem:item];
}

-(void)addItem:(NSMenuItem*)item
{
	[menu addItem:item];
}

-(id)initMenuWithDelegate:(id)aDelegate andItems:(NSArray*)items
{
	self = [self init];
	if (self)
	{
		[menu setDelegate:aDelegate];
		[self addItems:items];
	}
	return self;
}

-(void)setSubmenu:(NSMenu*)aMenu forItem:(NSMenuItem*)anItem
{
	[menu setSubmenu:aMenu forItem:anItem];
}

-(void)showMenuInWindow:(NSWindow*)window
{
	NSPoint mouseLocation = [window mouseLocationOutsideOfEventStream];
	NSEvent *event = [NSEvent mouseEventWithType:NSRightMouseDown
																																					location:mouseLocation
																																modifierFlags:0
																																				timestamp:GetCurrentEventTime()
																																	windowNumber:[window windowNumber]
																																						context:[NSGraphicsContext currentContext]
																																		eventNumber:1
																																			clickCount:1
																																					pressure:0.0];
	[NSMenu popUpContextMenu:menu withEvent:event forView:[window contentView]];	
}

+(id)itemWithTitle:(NSString *)itemName action:(SEL)anAction keyEquivalent:(NSString *)charCode
{
	return [[[NSMenuItem alloc] initWithTitle:itemName action:anAction keyEquivalent:charCode] autorelease];
}

-(NSMenu*)menu
{
	return [[menu retain] autorelease];
}

-(NSInteger)numberOfItems
{
	return [menu numberOfItems];
}

@end
