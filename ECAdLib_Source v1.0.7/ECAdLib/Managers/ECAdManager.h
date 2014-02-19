//
//  ECAdManager.h
//  ECAdLib
//
//  Copyright (c) 2013 EngageClick. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIViewController.h>
#import "ECBannerAdView.h"
#import "ECBrowserViewController.h"


#define ECLog(format, ...) [[ECAdManager sharedManager] logWithPath:__FILE__ line:__LINE__ string:(format), ## __VA_ARGS__]


@protocol ECBannerAdDelegate;
@protocol ECVideoAdDelegate;

@interface ECAdManager : NSObject<ECBannerAdViewDelegate, ECBrowserDelegate>
@property (nonatomic, unsafe_unretained) id <ECBannerAdDelegate> bannerAdDelegate;
@property (nonatomic, unsafe_unretained) id <ECVideoAdDelegate> videoAdDelegate;
@property (nonatomic) BOOL enableLog;
@property (nonatomic) BOOL enableDebugLog;

@property (nonatomic, strong) NSString *pubKey;


// Notifications sent about the result of showing the Ad
extern NSString * const kECAdManagerDidShowAdNotification;
extern NSString * const kECAdManagerShowAdFailedNotification;

// Status key that will give more information about the result of showing the Ad
extern NSString * const kECAdStatusKey;

// These values that are assocaited with the kECAdStatusKey will give extened information on the result of showing the ad
extern NSString * const kECAdUserCompletedInteraction;
extern NSString * const kECAdUserClosedAd;
extern NSString * const kECAdAdTimedOut;

// Ad parameters to be supplied by the developer
extern NSString * const kECAdUserParams;  // Key in user defined parametres such asa gender, age etc

extern NSString * const kECAdAppPublisherKey;   // The publisher ID given to you when you signed up with EngageClick
extern NSString * const kECAdAppZoneIDKey;      // The Zone ID given to you by EngageClick
extern NSString * const kECAdAppSiteIDKey;      // The Site ID given to you by EngageClick
extern NSString * const kECAdAppIDKey;          // Your app id
extern NSString * const kECAdReferrerKey;   // The screen or viewcontroller name that shows the Ad
extern NSString * const kECKeywordKey;      // Any keywords that describe the page that shows the Ad
extern NSString * const kECCategoryKey;     // The category of the page that shows the Ad
extern NSString * const kECVideoADURL;     // The category of the page that shows the Ad
extern NSString * const kECBannerADURL;     // The category of the page that shows the Ad

extern NSString * const kECAdWidth;
extern NSString * const kECAdHeight;
extern NSString * const kECAdSize;

typedef enum
{
    EC_AD_320x50,
    EC_AD_300x50,
    EC_AD_300x250,
    EC_AD_320x480,
    EC_AD_480x320,
    EC_AD_468x60,
    EC_AD_120x600,
    EC_AD_728x90,
    EC_AD_728x1024,
    EC_AD_1024x728,
    EC_AD_768x1024,
    EC_AD_1024x768
} kECAdSizeDef;


typedef enum
{
    kECVideoAdFilmStrip,
    kECVideoAdDPE,
    kECVideoInlineSocial,
    kECVideoInlineSocialHorizontal,
    kECVideoInlineSocialVertical,
    kECVideoAdControlBar,
    kECVideoAdTimeSync,
    kECVideoAdPullDownSocial,
    kECVideoAdRegional,
    kECVideoAdSmartSkippable
} kECVideoAdType;

typedef enum
{
    kECVideoAdTimeSyncBannerSlide,
    kECVideoAdTimeSyncOverlay,
    kECVideoAdDPEOverlay,
    kECVideoAdDPEBubble,
    kECVideoAdSkipSurvey
} kECVideoSubType;

/* sharedManager - A singleton method that will return the instance of the ECAdManager to be used to show Ads
 */
+ (ECAdManager *)sharedManager;
- (void)logWithPath:(char *)path line:(NSUInteger)line string:(NSString *)format, ...;
- (void)addTelephonyCarrierInfoToParams:(NSMutableDictionary *)params;
- (NSString *)queryStringFromParams:(NSDictionary *)params;

- (void)startSession:(NSString *)pubKey;
@property (nonatomic, strong) NSBundle *libBundle;
- (NSData *)loadFile:(NSString *)name;

/* showECModalAd - This method will show a full screen modal Ad
 * Return Value - YES if the call was successful, NO if the call failed e.g. if the pubkey or zoneid was not passed in
 */
- (BOOL)showECModalAdWithParameters:(NSDictionary *)appParams withViewController:(UIViewController *)vc refresh:(CGFloat)refreshRate;
- (void)dismissECModalAd:(BOOL)animated;

/* Banner Ad Related Methods
 * showECModalBannerAdWithParameters - Will return a UIView which contains a webview in it
 * layoutFrameForBannerAd - this is to set the Frame of the Banner Ad internally the webview
 */
- (ECBannerAdView *)showECBannerAdWithParameters:(NSDictionary *)appParams withViewController:(UIView *)parentView Custom:(BOOL)isCustom refresh:(CGFloat)refreshRate delegate:(id)delegate_;
- (void)layoutFrameForBannerAd:(CGRect)rect;
- (void)refreshBannerAd;
- (void)refreshModalAd:(NSArray *)adsize;
- (NSURL *)getBannerURL:(NSMutableDictionary *)adParams SDK:(NSMutableDictionary *)sdkParams;


- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation;
- (void)setCloseButtonHidden:(BOOL)hide;
- (void)removeBannerAdView;
- (void)loadInterstitialWebView:(NSString *)urlStr;

/* For Dislpaying Native Video Ads
 * Pass in the Video Ad Format
 */
- (void)showVideoAd:(NSMutableDictionary *)adParams;
- (void)showVideoAdWithParameters:(NSDictionary *)addParams adFormat:(kECVideoAdType)videoFormat withViewController:(UIViewController *)vc;
- (void)videoAdLandingPageOpened:(NSString *)landingpage;
- (void)logVideoImpression;
- (NSMutableDictionary *)getVideoLogDict;


- (UIViewController *)topViewController:(UIViewController *)rootViewController;

- (NSArray*) getAdSize:(kECAdSizeDef ) size;
/**** optional Method for getting Location ******/
// User should have to pass shouldSDKUseLocation BOOL flag to check whether SDK should use location or not
// If User dont want to use location, he can pass shouldSDKUseLocation - NO and currentLocation - nil
// If User want to use location, he can pass shouldSDKUseLocation - YES and should pass currentLocation if they have already, or pass nil (so SDK will fetch it).

-(void)canECAdLibGetLocation:(BOOL)shouldSDKUseLocation currentLocation:(CLLocation*)currentLocation;

@end

@protocol ECVideoAdDelegate <NSObject>
@optional
- (void)videoAdViewDidLoad;
- (void)videoAdViewDidClose;
- (void)videoAdViewDidFailWithError:(NSError *)error;
@end

@protocol ECBannerAdDelegate <NSObject>
@optional
- (void)bannerAdDidFinishWithResult:(kECBannerAdResult)result withServerResponse:(NSDictionary *)response;
- (void)bannerAdViewDidLoad:(ECBannerAdView *)bannerAdView;
- (void)bannerAdView:(ECBannerAdView *)bannerAdView didFailWithError:(NSError *)error;
- (void)bannerAdView:(ECBannerAdView *)bannerAdView didClickLink:(NSString *)urlStr;
- (void)bannerAdView:(ECBannerAdView *)bannerAdView willExpand:(NSString *)urlStr;
- (void)bannerAdViewDidClose:(ECBannerAdView *)bannerAdView;
- (void)bannerAdViewDidRestore:(ECBannerAdView *)bannerAdView;
- (UIViewController *)modalAdPresentingViewcontroller;
@end



