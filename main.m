//
//  main.m
//  ActiveLog
//
//  Created by Uncle MiF on 9/10/10.
//  Copyright 2010 Deep IT. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	//*
	NSAutoreleasePool * arp = [NSAutoreleasePool new];
	
	fprintf(stderr,"DIALog is loaded: %i\n",[[NSBundle bundleWithPath:
		[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Frameworks/DIALog.framework"]]
			load]);

	[arp drain];
	/* */
		
	return NSApplicationMain(argc,  (const char **) argv);
}
