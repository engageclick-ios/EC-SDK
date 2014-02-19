//
//  UIDevice+ECDeviceInfo.m
//  ECaddFramework
//
//  Created by Hitesh Dave on 2/1/13.
//  Copyright (c) 2013 EngageClick. All rights reserved.
//

#import "UIDevice+ECDeviceInfo.h"
#import <sys/utsname.h>
#import <AdSupport/AdSupport.h>


@implementation UIDevice (ECDeviceInfo)

+ (NSString *)machineName {
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

+ (NSString *)friendlyModelName:(NSString *)inPlatform {
    
    NSString *outPlatform = nil;
    
    NSDictionary *platformTransalationDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                              @"Simulator", @"i386",
                                              @"iPod Touch", @"iPod1,1",
                                              @"iPod Touch 2", @"iPod2,1",
                                              @"iPod Touch 3", @"iPod3,1",
                                              @"iPod Touch 4", @"iPod4,1",
                                              @"iPod Touch 5", @"iPod5,1",
                                              @"iPhone", @"iPhone1,1",
                                              @"iPhone 3G", @"iPhone1,2",
                                              @"iPhone 3GS", @"iPhone2,1",
                                              @"iPad", @"iPad1,1",
                                              @"iPad 2", @"iPad2,1",
											  @"iPad 2", @"iPad2,2",
											  @"iPad 2", @"iPad2,3",
											  @"iPad 2", @"iPad2,4",
                                              @"iPad Mini", @"iPad2,5",
											  @"iPad 3", @"iPad3,1",
											  @"iPad 3", @"iPad3,2",
											  @"iPad 3", @"iPad3,3",
                                              @"iPad 4", @"iPad3,4",
                                              @"iPhone 4", @"iPhone3,1",
                                              @"iPhone 4", @"iPhone3,2",
											  @"iPhone 4", @"iPhone3,3",
                                              @"iPhone 4S", @"iPhone4,1",
											  @"iPhone 5", @"iPhone5,1",
                                              @"iPhone 5", @"iPhone5,2", nil];
    
    outPlatform = [platformTransalationDict objectForKey:inPlatform];
    
    if (!outPlatform)
        outPlatform = inPlatform;
    
    return outPlatform;
}

+ (NSString *)model {
    
    NSString *outModel = @"";
    outModel = [NSString stringWithFormat:@"%@",[self friendlyModelName:[self machineName]]];
    return outModel;
}


- (NSString *)EC_formattedUniqueIdentifier {
    return [self OpenUDID];
    
    //    NSString *UDID;
    //
    //    if ([[self deviceCurrentOSVersion] floatValue] >= 6.0) {
    //            NSUUID *UUID = [[ASIdentifierManager sharedManager] advertisingIdentifier];
    //            UDID = [UUID UUIDString];
    //        }else {
    //            CFUUIDRef theUUID = CFUUIDCreate(NULL);
    //            CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    //            CFRelease(theUUID);
    //            UDID =  (__bridge NSString *)string;
    //        }
    //    return UDID;
    
}


- (NSString *)OpenUDID {
    NSString *UDID;
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"EC_UDID"])
        UDID = [[NSUserDefaults standardUserDefaults] objectForKey:@"EC_UDID"];
    else {
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef string = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        UDID =  (__bridge NSString *)string;
        [[NSUserDefaults standardUserDefaults] setObject:UDID forKey:@"EC_UDID"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return UDID;
    
}

- (NSString *) EC_advertisingIdentifier
{
    if (!NSClassFromString(@"ASIdentifierManager")) {
        return [self OpenUDID];
    }
    return ([[[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString] length] ? [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString] : @"NA");
}

- (NSString *) EC_identifierForVendor
{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        return ([[[[UIDevice currentDevice] identifierForVendor] UUIDString] length] ? [[[UIDevice currentDevice] identifierForVendor] UUIDString]  : @"NA");
    }
    return [self OpenUDID];
}

- (BOOL)EC_isAdvertisingTrackingEnabled
{
    if (NSClassFromString(@"ASIdentifierManager") && ![[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]) {
        return NO;
    }
    return YES;
}



- (NSString *)deviceCurrentOSVersion
{
    return [[UIDevice currentDevice] systemVersion];
}

@end
