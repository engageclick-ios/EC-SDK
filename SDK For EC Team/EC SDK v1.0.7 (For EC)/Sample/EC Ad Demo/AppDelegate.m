//
//  AppDelegate.m
//  EC Ad Demo
//
//  Created by Engageclick on 9/20/13.
//  Copyright (c) 2013 Engageclick. All rights reserved.
//

#import "AppDelegate.h"
#import "ECAdManager.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    if ( [[UIDevice currentDevice] userInterfaceIdiom] ==UIUserInterfaceIdiomPad)
        [[ECAdManager sharedManager] startSession:@"5d24511077c3001cf1967759910763cb8feed9a419c7c14a130fff3b850a88f8df992512af57305802c023b961adb74212a7cc7821ed06a8345b6a63706864d4"]; // For iPad
    else
        [[ECAdManager sharedManager] startSession:@"cbcf339732ac86726725629daa36ff1beefd5eeb0b505e60962c14816312aecebc5b57aebe62d4fae187a45688d092c652f5a66b32e71e334be875c998867121"];


    return YES;
}


							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
