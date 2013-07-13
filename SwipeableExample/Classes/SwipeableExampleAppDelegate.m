//
//  SwipeableExampleAppDelegate.m
//  SwipeableExample
//
//  Created by Tom Irving on 16/06/2010.
//  Copyright Tom Irving 2010. All rights reserved.
//

#import "SwipeableExampleAppDelegate.h"
#import "RootViewController.h"

@implementation SwipeableExampleAppDelegate

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	RootViewController * viewController = [[RootViewController alloc] initWithStyle:UITableViewStylePlain];
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
	
	[window setRootViewController:navigationController];
	
    [window makeKeyAndVisible];
	
	return YES;
}

#pragma mark -
#pragma mark Memory management

@end