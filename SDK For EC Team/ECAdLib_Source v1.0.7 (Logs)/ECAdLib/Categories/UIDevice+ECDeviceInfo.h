//
//  UIDevice+ECDeviceInfo.h
//  ECaddFramework
//
//  Created by Hitesh Dave on 2/1/13.
//  Copyright (c) 2013 EngageClick. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (ECDeviceInfo)

+ (NSString *)model;
- (NSString *)EC_formattedUniqueIdentifier;
- (NSString *)deviceCurrentOSVersion;
- (NSString *) EC_identifierForVendor;
- (NSString *) EC_advertisingIdentifier;
- (BOOL)EC_isAdvertisingTrackingEnabled;
@end
