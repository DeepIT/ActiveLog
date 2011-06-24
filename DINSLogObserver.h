// COMMON FILE: Common

//
//  DINSLogObserver.h
//  MDict
//
//  Created by Uncle MiF on 9/10/10.
//  Copyright 2010 Deep IT. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DINSLogFilter+Remote.h"

@protocol DINSLogObserverProtocol <NSObject>

-(BOOL)processAnnounce:(NSDictionary*)info;

@end

@interface DINSLogObserver : NSObject

+(void)setDelegate:(id)delegate;

+(void)setEnabled:(BOOL)flag;
+(BOOL)isEnabled;

+(void)registerObserverWithModules:(NSSet*)modulesList;
+(void)unregisterObserver;

+(void)announce:(NSNotification*)aNotification;
+(void)sendAnnounce:(id)announceObject forName:(NSString*)announceName;
+(void)sendCommand:(NSString*)command forTarget:(NSString*)target withOptions:(NSDictionary*)options;

+(NSSet*)modulesList;// enabled
+(NSDictionary*)detectedModulesList;// detected

@end
