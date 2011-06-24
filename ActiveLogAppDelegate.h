//
//  ActiveLogAppDelegate.h
//  ActiveLog
//
//  Created by Uncle MiF on 9/10/10.
//  Copyright 2010 Deep IT. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ALWindowController.h"

@interface ActiveLogAppDelegate : NSObject
{
	ALWindowController *wc;
}

@property (assign) IBOutlet ALWindowController *wc;

@end
