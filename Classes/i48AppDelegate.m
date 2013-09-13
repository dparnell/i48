//
//  i48AppDelegate.m
//  i48
//
//  Created by Daniel Parnell on 14/04/09.
//  Copyright Automagic Software Pty Ltd 2009. All rights reserved.
//

#import "i48AppDelegate.h"
#import "RootViewController.h"

@implementation i48AppDelegate


@synthesize window;
@synthesize rootViewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
    [[NSUserDefaults standardUserDefaults] 
		registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys: 
							[NSNumber numberWithBool: YES], @"limit_speed",
							[NSNumber numberWithBool: NO], @"key_click",
							@"MainView", @"skin",
							 nil
						   ]
	 ];
		
	CGRect  rect = [[UIScreen mainScreen] bounds];
    [window setFrame:rect];
    [window setRootViewController: rootViewController];
    
    [window makeKeyAndVisible];
}



@end
