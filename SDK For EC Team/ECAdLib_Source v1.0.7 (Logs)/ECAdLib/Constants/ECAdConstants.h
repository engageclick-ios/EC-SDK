//
//  ECAdConstants.h
//  ECAdLib
//
//  Created by Hitesh Dave on 4/28/13.
//  Copyright (c) 2013 EngageClick. All rights reserved.
//

#ifndef ECAdLib_ECAdConstants_h
#define ECAdLib_ECAdConstants_h



// EC Ad Analytics Event Constants
static NSString * const ModalAdDidShow = @"ModalAdDidShow";
static NSString * const ModalAdDidFail = @"ModalAdDidFail";
static NSString * const ModalAdClose = @"ModalAdClose";
static NSString * const ModalAdDidCompleteInteraction = @"ModalAdDidCompleteInteraction";
static NSString * const ModalAdDidClickLink = @"ModalAdDidClickLink";
static NSString * const ModalADDidClickPassbook = @"ModalADDidClickPassbook";
static NSString * const ModalADDidOpenAppstore = @"ModalADDidOpenAppstore";


static NSString * const BannerAdDidShow = @"BannerAdDidShow";
static NSString * const BannerAdDidFail = @"BannerAdDidFail";
static NSString * const BannerAdDidExpand = @"BannerAdDidExpand";
static NSString * const BannerAdDidRestore = @"BannerAdDidRestore";
static NSString * const BannerAdDidCompleteInteraction = @"BannerAdDidCompleteInteraction";
static NSString * const BannerAdDidClickLink = @"BannerAdDidClickLink";




// Notifications sent to the app about the result of showing the Ad
extern NSString * const kECAdManagerDidShowAdNotification;
extern NSString * const kECAdManagerShowAdFailedNotification;

// Status key that will give more information about the result of showing the Ad
extern NSString * const kECAdStatusKey;

// These values that are assocaited with the kECAdStatusKey will give extened information on the result of showing the ad
extern NSString * const kECAdUserCompletedInteraction;
extern NSString * const kECAdUserClosedAd;
extern NSString * const kECAdAdTimedOut;

// Ad parameters to be supplied by the developer
extern NSString * const kECAdAppPublisherKey;
extern NSString * const kECAdAppZoneIDKey;
extern NSString * const kECAdAppIDKey;
extern NSString * const kECAdReferrerKey;
extern NSString * const kECKeywordKey;
extern NSString * const kECCategoryKey;

extern NSString * const kECAdSessionID;
extern NSString * const kECAdLatitude;
extern NSString * const kECAdLongitude;
extern NSString * const kECAdCity;
extern NSString * const kECAdRegion;
extern NSString * const kECAdCountry;
extern NSString * const kECIsWifi;
extern NSString * const kECAdBrand;
extern NSString * const kECAdModel;
extern NSString * const kECAdIOSVersion;
extern NSString * const kECAdDeviceID;
extern NSString * const kECAdDeviceIDFV;
extern NSString * const kECAdDeviceIDFA;
extern NSString * const kECAdDeviceTrackingEnabled;
#endif
