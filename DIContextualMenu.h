// COMMON FILE: Common

//
//  DIContextualMenu.h
//  MDict
//
//  Created by Uncle MiF on 6/28/10.
//  Copyright 2010 Deep IT. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DIContextualMenu : NSObject
{
	NSMenu * menu;
}

+(id)contextualMenuWithDelegate:(id)aDelegate andItems:(NSArray*)items;
+(id)contextualMenuWithDelegate:(id)aDelegate;
+(id)itemWithTitle:(NSString *)itemName action:(SEL)anAction keyEquivalent:(NSString *)charCode;

-(id)initMenuWithDelegate:(id)aDelegate andItems:(NSArray*)items;

-(void)addItems:(NSArray*)items;
-(void)addItem:(NSMenuItem*)item;

-(void)setSubmenu:(NSMenu*)aMenu forItem:(NSMenuItem*)anItem;

-(void)showMenuInWindow:(NSWindow*)window;

-(NSMenu*)menu;
-(NSInteger)numberOfItems;

@end
