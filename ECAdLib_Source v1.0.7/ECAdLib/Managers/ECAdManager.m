//
//  ECAdManager.m
//  ECAdLib
//
//  Created by bsp on 4/14/13.
//  Copyright (c) 2013 EngageClick. All rights reserved.
//

#import "ECAdManager.h"
#import "ECModalAdViewController.h"
#import "ECReachability.h"
#import <CoreLocation/CoreLocation.h>
#import "UIDevice+ECDeviceInfo.h"
#import "ECAdConstants.h"
#import "ECBannerAdView.h"
#import "Flurry.h"
#import "EcAdCustomPlayer.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "ECAdUtilities.h"
#import <Accounts/Accounts.h>

// For Video Ads
#import "EcModalVideoAdViewController.h"
#import "ECModalVideoAdViewController_iPhone.h"

#import "ECModalVideoPlaylistAdViewController.h"
#import "ECModalVideoAdTimeSyncViewController.h"
#import "ECModalVideoFilmStripAdViewController.h"
#import "ECModalDPEViewController.h"
#import "ECModalViewRegionalViewController.h"
#import "ECModalVideoInlineSocialViewController.h"
// For Getting Mac Address
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

// Notifications sent to the app about the result of showing the Ad
NSString * const kECAdManagerDidShowAdNotification = @"kECAdManagerDidShowAdNotification";
NSString * const kECAdManagerShowAdFailedNotification = @"kECAdManagerShowAdFailedNotification";

// Status key that will give more information about the result of showing the Ad
NSString * const kECAdStatusKey = @"kECAdStatusKey";

// These values that are assocaited with the kECAdStatusKey will give extened information on the result of showing the ad
NSString * const kECAdUserCompletedInteraction = @"kECAdUserCompletedInteraction";
NSString * const kECAdUserClosedAd = @"kECAdUserClosedAd";
NSString * const kECAdAdTimedOut = @"kECAdAdTimedOut";

// Ad parameters to be supplied by the developer
NSString * const kECAdUserParams = @"userparams";

NSString * const kECAdAppPublisherKey = @"pubkey";
NSString * const kECAdAppZoneIDKey = @"zid";
NSString * const kECAdAppSiteIDKey = @"siteid";

NSString * const kECAdAppIDKey = @"kECAdAppIDKey";
NSString * const kECAdReferrerKey = @"kECAdReferrerKey";
NSString * const kECKeywordKey = @"kECKeywordKey";
NSString * const kECCategoryKey = @"kECCategoryKey";

NSString * const kECAdWidth = @"w";
NSString * const kECAdHeight = @"h";
NSString * const kECAdSize = @"adsize";

NSString * const kECAdSessionID = @"sessionid";
NSString * const kECAdLatitude = @"latitude";
NSString * const kECAdLongitude = @"longitude";
NSString * const kECAdCity = @"city";
NSString * const kECAdRegion = @"region";
NSString * const kECAdCountry = @"country";
NSString * const kECIsWifi = @"ct";
NSString * const kECAdBrand = @"brand";
NSString * const kECAdModel = @"model";
NSString * const kECAdIOSVersion = @"version";
NSString * const kECAdMacId = @"macid";

NSString * const kECAdOSName = @"os";
NSString * const kECAdIOS = @"iOS";
NSString * const kECAdDeviceID = @"deviceid";
NSString * const kECAdDeviceIDFV = @"idfv";
NSString * const kECAdDeviceIDFA = @"idfa";

NSString * const kECAdDeviceTrackingEnabled = @"trackenabled";

NSString * const kECAdSDKVersion = @"sdkversion";
NSString * const kECAdSDKVersionNumber = @"1.0.7";

NSString * const kECADStateLogURL = @"http://demo.engageclick.com/ecadserve/debuglog";//@"http://demo.engageclick.com/ecadserve/debuglog?message=iossdk:-debug:closed";//@"http://devefence.engageclick.com:8080/ecadserve/ecadstatelog";
NSString * const kECADStateParam = @"adstate";


NSString * const kECVideoADURL = @"videoAdURL";

NSString * const kECBannerADURL = @"AdURL";

NSString * const kECVideoRequestURL = @"http://demo.engageclick.com/ecadserve/ecvideo";
NSString * const kECVideoHURL = @"hurl";
NSString * const kECAdRequestURL = @"http://serve.engageclick.com/ecadserve/sdkconfig?";

#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )



@interface ECAdManager() <ECModalAdDelegate,CLLocationManagerDelegate>
@property (nonatomic, strong) NSMutableDictionary *sdkParams;
@property (nonatomic, strong) UIViewController *modalAdViewController;
@property (nonatomic, strong) ECBannerAdView *modalBannerAdView;
@property (nonatomic, strong) ECBrowserViewController *modalinterstitialAdView;
@property (nonatomic, assign) CLLocationCoordinate2D currentLocationCoordinate;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSString *currentCity;
@property (nonatomic, strong) NSString *currentRegion;
@property (nonatomic, strong) NSString *currentCountry;
@property (nonatomic, strong) ECReachability *reachability;
@property (nonatomic, assign) BOOL isReachable;
@property (nonatomic, assign) BOOL shouldSDKUseCurrentLocation;
@property (nonatomic, assign) BOOL isWiFiAsActiveNetwork;
@property (nonatomic, strong) NSString *sessionID;
@property (nonatomic, strong) NSMutableArray *adResponses;
@property (nonatomic, strong) NSString *adResponsesFile;
@property (nonatomic, strong) NSMutableDictionary *adStateDict;
@property (nonatomic, strong) NSMutableDictionary *videoAdResponseDict;

// Private methods
- (void)mapAppParams:(NSDictionary *)appParams toAdParams:(NSMutableDictionary *)modalAdParams;
- (void)insertAdditionalAdParams:(NSMutableDictionary *)modalAdParams;
- (void)reachabilityChanged:(NSNotification *)notification;
- (void)updateReachability;
- (void)getRegionFromCurrentLocation:(CLLocation*)currentLocation;
- (void)postAdResponseToServer:(NSDictionary *)resoponse;
- (NSString *)generateSessionID;
- (void)saveResponsesToFile;
- (void)loadResponsesFromFile;
@end

@implementation ECAdManager

static id sharedManager;

- (id)init
{
    if (nil != sharedManager)
    {
        NSAssert(nil, @"Please do not init a ECAdManager use sharedManager");
        return nil;
    }
    self = [super init];
    if (nil != self)
    {
        // Initialize network reachability and get the current internet connection status and register to listen for change in network status
        self.reachability = [ECReachability reachabilityForInternetConnection];
        [self updateReachability];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        [self.reachability startNotifier];
        self.shouldSDKUseCurrentLocation = NO;
        self.isWiFiAsActiveNetwork = NO;
        
        // generate a new session id
        self.sessionID = [self generateSessionID];
        self.adResponses = [[NSMutableArray alloc] init];
        
        // Load any responses we did not send so that we can send them all together
        self.adResponsesFile = [NSString stringWithFormat:@"%@ecadresponses.json", NSTemporaryDirectory()];
        
        self.libBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"ECAdLibResources" withExtension:@"bundle"]];
        
        [self loadResponsesFromFile];
    }
    return self;
}

#pragma mark - Public
+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[ECAdManager alloc] init];
    });
}

+ (ECAdManager *)sharedManager
{
    
    return sharedManager;
}

- (void)logWithPath:(char *)path line:(NSUInteger)line string:(NSString *)format, ... {
    if (!self.enableLog)
        return;
	NSString *pathString = [[NSString alloc] initWithBytes:path	length:strlen(path) encoding:NSUTF8StringEncoding];
	
	va_list argList;
	va_start(argList, format);
	NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:argList];
	va_end(argList);
	
	NSLog(@"%@", [NSString stringWithFormat:@"%@ (%d): %@", [pathString lastPathComponent], line, formattedString]);
}

- (void)startSession:(NSString *)pubKey {
    // proceed only if we have network connectivity
    if (NO == self.isReachable)
    {
        ECLog(@"There is NO internet connectivity unable to show Ad");
        return;
    }else if (![pubKey length]) {
        ECLog(@"Invalid Pubkey");
        return;
        
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.pubKey = pubKey;
        [Flurry startSession:@"3D4Q2TPFCXF57HC6D3HP"];
        [self canECAdLibGetLocation:self.shouldSDKUseCurrentLocation currentLocation:nil];
        [self getADRequestURL];
    });
    
}

/*
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
*/
- (NSArray*) getAdSize:(kECAdSizeDef ) size {
    NSArray *result;
    switch(size) {
        case EC_AD_320x50:
            result =[NSArray arrayWithObjects:@"320",@"50", nil];
            break;
        case EC_AD_300x50:
            result =[NSArray arrayWithObjects:@"300",@"50", nil];
            break;
        case EC_AD_300x250:
            result =[NSArray arrayWithObjects:@"300",@"250", nil];
            break;
        case EC_AD_320x480:
            result =[NSArray arrayWithObjects:@"320",@"480", nil];
            break;
        case EC_AD_480x320:
            result =[NSArray arrayWithObjects:@"480",@"320", nil];
            break;
            case EC_AD_468x60:
            result =[NSArray arrayWithObjects:@"468",@"60", nil];
            break;
        case EC_AD_120x600:
            result =[NSArray arrayWithObjects:@"120",@"600", nil];
            break;
        case EC_AD_728x90:
            result =[NSArray arrayWithObjects:@"728",@"90", nil];
            break;
        case EC_AD_728x1024:
            result =[NSArray arrayWithObjects:@"728",@"1024", nil];
            break;
        case EC_AD_1024x728:
            result =[NSArray arrayWithObjects:@"1024",@"728", nil];
            break;
        case EC_AD_768x1024:
            result =[NSArray arrayWithObjects:@"768",@"1024", nil];
            break;
            break;
        case EC_AD_1024x768:
            result =[NSArray arrayWithObjects:@"1024",@"768", nil];
            break;
        default:
            result =[NSArray arrayWithObjects:@"320",@"50", nil];
    }
    
    return result;
}

- (void)getADRequestURL {
    NSString *url = kECAdRequestURL;
    url = [url stringByAppendingString:[NSString stringWithFormat:@"pubkey=%@&appid=%@&deviceid=%@&idfv=%@&idfa=%@",self.pubKey,[[NSBundle mainBundle] bundleIdentifier],[[UIDevice currentDevice] EC_formattedUniqueIdentifier],[[UIDevice currentDevice] EC_identifierForVendor],[[UIDevice currentDevice] EC_advertisingIdentifier]]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]] ;
    
    [request setHTTPMethod:@"GET"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        ECLog(@"SDK COnfig URL %@",url);
        
        ECLog(@"responseString = %@ and response statusCode = %d",responseString, [httpResponse statusCode]);
        data=[responseString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (responseDictionary) {
            NSString *adServiceURL = [responseDictionary objectForKey:@"adserviceurl"];
            NSString *debugURL = [responseDictionary objectForKey:@"debugurl"];
            NSString *impServiceURL = [responseDictionary objectForKey:@"impserviceurl"];
            NSString *clickServiceURL = [responseDictionary objectForKey:@"clickserviceurl"];
            NSString *blkLogURL = [responseDictionary objectForKey:@"blklogurl"];
            NSString *videoLogURL = [responseDictionary objectForKey:@"videoadserviceurl"];
            if ([adServiceURL length])
                [[NSUserDefaults standardUserDefaults] setObject:adServiceURL forKey:@"ecadserviceurl"];
            if ([debugURL length])
                [[NSUserDefaults standardUserDefaults] setObject:debugURL forKey:@"ecdebugurl"];
            if ([impServiceURL length])
                [[NSUserDefaults standardUserDefaults] setObject:impServiceURL forKey:@"ecimpserviceurl"];
            if ([clickServiceURL length])
                [[NSUserDefaults standardUserDefaults] setObject:clickServiceURL forKey:@"ecclickserviceurl"];
            if ([blkLogURL length])
                [[NSUserDefaults standardUserDefaults] setObject:blkLogURL forKey:@"ecblklogurl"];
            if ([videoLogURL length])
                [[NSUserDefaults standardUserDefaults] setObject:videoLogURL forKey:@"ecvideoserviceurl"];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [[NSUserDefaults standardUserDefaults] synchronize];
            });
        }
    }];
}



- (NSString *)trimResponse:(NSString *)response {
    NSString *trimmedStr = [[response componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    if ([trimmedStr length]) {
        NSRange urlStart = [trimmedStr rangeOfString: @"{"];
        NSRange urlEnd = [trimmedStr rangeOfString: @"};"];
        if (urlEnd.length <= 0)
            return trimmedStr;
        NSRange resultedMatch = NSMakeRange(urlStart.location, urlEnd.location - urlStart.location + urlEnd.length-1);
        if (resultedMatch.location != NSNotFound)
            trimmedStr = [trimmedStr substringWithRange:resultedMatch];
    }
    return response;
}

- (NSData *)loadFile:(NSString *)name
{
    NSArray *fileComponents = [name componentsSeparatedByString:@"."];
    // construct the file for the file that needs to be loaded
    NSString *filePath = [self.libBundle pathForResource:[fileComponents objectAtIndex:0] ofType:[fileComponents objectAtIndex:1]];
    // return the contents of the file
    return [NSData dataWithContentsOfFile:filePath];
}


- (void)showAlert:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

- (void)removeBannerAdView {
    if (self.modalBannerAdView) {
        [self.modalBannerAdView removeFromSuperview];
        self.modalBannerAdView = nil;
    }
    
}
- (ECBannerAdView *)showECBannerAdWithParameters:(NSDictionary *)appParams withViewController:(UIView *)parentView Custom:(BOOL)isCustom refresh:(CGFloat)refreshRate delegate:(id)delegate_ {
    [self removeBannerAdView];
    
    if (nil == [appParams objectForKey:kECAdAppIDKey]) {
        ECLog(@"kECAdAppIDKey missing from the params that are passed in");
        return nil;
        
    }
    if (![self.pubKey length] && nil == [appParams objectForKey:kECAdAppPublisherKey])
    {
        ECLog(@"kECAdAppPublisherKey missing from the params that are passed in");
        
        return nil;
    }
    
    // proceed only if we have network connectivity
    if (NO == self.isReachable)
    {
        ECLog(@"There is NO internet connectivity unable to show Ad");
        return nil;
    }
    [self setBannerAdDelegate:delegate_];
    // letter we will present modal viewController on locationManager success and fail methods
    
    // map the ad params passed in, to params that need to be passed to the modal ad viewcontroller
    NSMutableDictionary *modalAdParams = [[NSMutableDictionary alloc] init];
    [self mapAppParams:appParams toAdParams:modalAdParams];
    [self insertAdditionalAdParams:modalAdParams];
    if (![modalAdParams objectForKey:kECAdAppPublisherKey])
        [modalAdParams setObject:self.pubKey forKey:kECAdAppPublisherKey];
    if ([appParams objectForKey:kECBannerADURL]) {
        [modalAdParams setObject:[appParams objectForKey:kECBannerADURL] forKey:kECBannerADURL];
    }
    if ([appParams objectForKey:kECAdUserParams])
        [modalAdParams setObject:[appParams objectForKey:kECAdUserParams] forKey:kECAdUserParams];
    
    CGFloat OSVersion =[[[UIDevice currentDevice] deviceCurrentOSVersion] floatValue];
    if (OSVersion >= 5.0) {
        NSString *twitterUN = [self getUsername:ACAccountTypeIdentifierTwitter];
        if ([twitterUN length])
            [modalAdParams setObject:twitterUN forKey:@"twitterusername"];
        if (OSVersion >= 6.0) {
            NSString *fbUN = [self getUsername:ACAccountTypeIdentifierFacebook];
            if ([fbUN length])
                [modalAdParams setObject:fbUN forKey:@"facebookusername"];
            
        }
    }
    //ECLog(@"Banner Params %@", modalAdParams);
    //ECLog(@"City: %@ : Region: %@: Country: %@",self.currentCity,self.currentRegion,self.currentCountry);

    ECBannerAdView *bannerView = [[ECBannerAdView alloc] initWithParentView:parentView];
    [bannerView setRefreshRate:refreshRate];
    [bannerView setCustomWebView:isCustom];
    [bannerView setAdParams:modalAdParams];
    bannerView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    bannerView.delegate = self;
    [bannerView setParent:delegate_];
    [bannerView setBackgroundColor:[UIColor clearColor]];
    [parentView addSubview:bannerView];
    
    return bannerView;

    
    
//    self.modalBannerAdView = [[ECBannerAdView alloc] initWithParentView:parentView];
//    [self.modalBannerAdView setRefreshRate:refreshRate];
//    [self.modalBannerAdView setCustomWebView:isCustom];
//    [self.modalBannerAdView setAdParams:modalAdParams];
//    self.modalBannerAdView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
//    self.modalBannerAdView.delegate = self;
//    [self.modalBannerAdView setBackgroundColor:[UIColor clearColor]];
//    [parentView addSubview:self.modalBannerAdView];
//    
//    return self.modalBannerAdView;
    
}

- (void)layoutFrameForBannerAd:(CGRect)rect {
    if (self.modalBannerAdView)
        [self.modalBannerAdView layoutFrame:rect];
}

- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation {
    if (self.modalBannerAdView)
        [self.modalBannerAdView rotateToOrientation:newOrientation];
    
}
- (void)refreshBannerAd {
    if (self.modalBannerAdView)
        [self.modalBannerAdView refreshAd];
}


- (void)setCloseButtonHidden:(BOOL)hide {
    [self.modalBannerAdView setCloseButtonHidden:hide];
}

#pragma mark - Bannner Ad Delegate
- (void)bannerAdDidFinishWithResult:(kECBannerAdResult)result withServerResponse:(NSDictionary *)response
{
    self.modalAdViewController = nil;
    //ECLog(@"Result of Showing Ad - %d\n Response for EC server = %@", result, response);
    NSString *adResult;
    
    // map the result from the modal ad controller to return the result to the app
    switch (result) {
        case kECModalAdUserInteractionComplete:
            adResult = kECAdUserCompletedInteraction;
            break;
            
        case kECModalAdUserClose:
            adResult = kECAdUserClosedAd;
            break;
            
        case kECModalAdTimeout:
            adResult = kECAdAdTimedOut;
            break;
            
        default:
            break;
    }
    
    // put the result into the user info
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setValue:adResult forKey:kECAdStatusKey];
    
    // send the notification to the app about the result of showing the ad
    //[[NSNotificationCenter defaultCenter] postNotificationName:kECAdManagerDidShowAdNotification object:self userInfo:userInfo];
    
    // send response to EC server
    [Flurry logEvent:BannerAdDidCompleteInteraction withParameters:userInfo];
    if ([response count])
        [self postAdResponseToServer:response];
}


- (UIViewController *)modalAdPresentingViewcontroller {
    if ([self.bannerAdDelegate respondsToSelector:@selector(modalAdPresentingViewcontroller)])
        return [self.bannerAdDelegate modalAdPresentingViewcontroller];
    return nil;
}
- (void)bannerAdDidLoad:(ECBannerAdView *)bannerAdView {
    [Flurry logEvent:BannerAdDidShow];
    
    if ([bannerAdView.parent respondsToSelector:@selector(bannerAdViewDidLoad:)])
        [bannerAdView.parent performSelector:@selector(bannerAdViewDidLoad:) withObject:bannerAdView];
}
- (void)bannerAd:(ECBannerAdView *)bannerAdView didFailWithError:(NSError *)error {
    [Flurry logEvent:BannerAdDidFail];
    
    if ([bannerAdView.parent respondsToSelector:@selector(bannerAdView:didFailWithError:)])
        [bannerAdView.parent performSelector:@selector(bannerAdView:didFailWithError:) withObject:bannerAdView withObject:error];
}
- (void)bannerAd:(ECBannerAdView *)bannerAdView willExpand:(NSString *)urlStr {
    [Flurry logEvent:BannerAdDidExpand];
    
    if ([bannerAdView.parent respondsToSelector:@selector(bannerAdView:willExpand:)])
        [bannerAdView.parent performSelector:@selector(bannerAdView:willExpand:) withObject:bannerAdView withObject:urlStr];
}

- (void)bannerAd:(ECBannerAdView *)bannerAdView didClickLink:(NSString *)urlStr {
    [Flurry logEvent:BannerAdDidClickLink];
    
    if ([bannerAdView.parent respondsToSelector:@selector(bannerAdView:didClickLink:)])
        [bannerAdView.parent performSelector:@selector(bannerAdView:didClickLink:) withObject:bannerAdView withObject:urlStr];
    
    // Code for Diplaying Intertial Ads
    [self loadInterstitialWebView:urlStr];
}

- (void)loadInterstitialWebView:(NSString *)urlStr {
    //    UIViewController *rootViewController = [self modalAdPresentingViewcontroller];
    if (![urlStr length] || (self.modalinterstitialAdView.isViewLoaded && self.modalinterstitialAdView.view.window ))
        return;
    
    //    if (/*nil != self.modalAdViewController ||*/ ![urlStr length])
    //        return;
    UIViewController *rootViewController = [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
    if (nil == rootViewController)
        rootViewController = [self modalAdPresentingViewcontroller];
    if (rootViewController) {
        self.modalinterstitialAdView = [[ECBrowserViewController alloc] init];
        [self.modalinterstitialAdView setClickURL:urlStr];
        self.modalinterstitialAdView.interstitialDelegate =self;
        //self.modalinterstitialAdView.view.frame =rootViewController.view.bounds;
        [rootViewController presentViewController:self.modalinterstitialAdView animated:YES completion:nil];
    }
    
}

- (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    if ([rootViewController.presentedViewController isMemberOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}


- (void)bannerAdDidClose:(ECBannerAdView *)bannerAdView {
    [Flurry logEvent:BannerAdDidCompleteInteraction];
    
    if ([bannerAdView.parent respondsToSelector:@selector(bannerAdViewDidClose:)])
        [bannerAdView.parent performSelector:@selector(bannerAdViewDidClose:) withObject:bannerAdView];
}

- (void)bannerDidRestore:(ECBannerAdView *)bannerAdView {
    [Flurry logEvent:BannerAdDidRestore];
    
    if ([bannerAdView.parent respondsToSelector:@selector(bannerAdViewDidRestore:)])
        [bannerAdView.parent performSelector:@selector(bannerAdViewDidRestore:) withObject:bannerAdView];
    
}
#pragma mark - interstitial Ad Delegate

- (void)interstitialAdDidLoad:(ECBrowserViewController *)interstitialAdView {
    
}
- (void)interstitialAd:(ECBrowserViewController *)interstitialAdView didFailWithError:(NSError *)error {
    
}
- (void)interstitialAd:(ECBrowserViewController *)interstitialAdView didClickLink:(NSString *)urlStr {
    
}
- (void)interstitialAdDidClose:(ECBrowserViewController *)interstitialAdView {
    self.modalinterstitialAdView = nil;
    
    
}



#pragma mark - Native Video Ads

- (NSString *)urlEncode:(NSString *)str
{
    return [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (void)addTelephonyCarrierInfoToParams:(NSMutableDictionary *)params
{
    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier * carrier = [netInfo subscriberCellularProvider];
    [params setValue:carrier.carrierName forKey:@"carrier"];
    [params setValue:carrier.mobileCountryCode forKey:@"mcc"];
    [params setValue:carrier.mobileNetworkCode forKey:@"mnc"];
    
    [params setValue:[ECAdUtilities getIP] forKey:@"ip"];
    [params setValue:[ECAdUtilities getMacMD5Hash] forKey:@"mac_md5"];
    [params setValue:[ECAdUtilities getMacSHA1Hash] forKey:@"mac_sha1"];
    [params setValue:[ECAdUtilities getAppName] forKey:@"app_name"];
    [params setValue:[ECAdUtilities getAppVersion] forKey:@"app_version"];
    [params setValue:[ECAdUtilities getShortAppVersion] forKey:@"app_short_version"];
    [params setValue:[ECAdUtilities getScreenScale] forKey:@"screen_scale"];

    [params setValue:NSStringFromCGSize([ECAdUtilities getScreenResolution]) forKey:@"screen_resolution"];
    [params setValue:[ECAdUtilities getDeviceOrientation] forKey:@"device_orientation"];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        [params setValue:@"iPhone" forKey:@"device-type"];
    else
        [params setValue:@"iPad" forKey:@"device-type"];
}

- (void)initSDKParams {
    if (self.sdkParams)
        self.sdkParams = nil;
    self.sdkParams = [[NSMutableDictionary alloc] init];
    
    // set the viewport height and width
    int width = [[UIScreen mainScreen] bounds].size.width;
    int height = [[UIScreen mainScreen] bounds].size.height;
    
    [self.sdkParams setValue:[NSString stringWithFormat:@"%d", width] forKey:@"w"];
    [self.sdkParams setValue:[NSString stringWithFormat:@"%d",height] forKey:@"h"];
    
    // set the ad type
    [self.sdkParams setValue:@"native_video" forKey:@"adtype"];
    
    // set the request time stamp
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss:SSS";
    [self.sdkParams setValue:[dateFormatter stringFromDate:now] forKey:@"reqtimestamp"];
    
    // set the medium
    [self.sdkParams setValue:@"mweb" forKey:@"medium"];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = [bundle infoDictionary];
    NSString *prodName = [info objectForKey:@"CFBundleDisplayName"];
    
    [self.sdkParams setValue:prodName forKey:kECVideoHURL];
    [self.sdkParams setValue:[[NSBundle mainBundle] bundleIdentifier] forKey:@"bundleID"];
    
    // add the carrier information
    [self addTelephonyCarrierInfoToParams:self.sdkParams];
}

- (NSString *)queryStringFromParams:(NSDictionary *)params
{
    // go thru the params and create a query string
    NSMutableArray *queryParams = [[NSMutableArray alloc] init];
    for (NSString *key in params)
    {
        NSString *value = [params objectForKey:key];
        if ([value isKindOfClass:[NSMutableDictionary class]]) {
            NSMutableDictionary *userParams = (NSMutableDictionary *)value;
            [userParams enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
                if ([obj isKindOfClass:[NSString class]]) {
                    NSString *querry = [NSString stringWithFormat:@"%@=%@", [self urlEncode:key], [self urlEncode:obj]];
                    [queryParams addObject:querry];
                }
                
            }];
            continue;
        }
        else if (![value isKindOfClass:[NSString class]]) {
            value = [NSString stringWithFormat:@"%f",[[params objectForKey:key] doubleValue]];//[[params objectForKey:key] stringValue];
        }
        NSString *keyValue = [NSString stringWithFormat:@"%@=%@", [self urlEncode:key], [self urlEncode:value]];
        [queryParams addObject:keyValue];
    }
    return [queryParams componentsJoinedByString:@"&"];
}



- (kECVideoAdType)getVidedAdType {
    NSString *format = [[self.videoAdResponseDict objectForKey:@"data"] objectForKey:@"format"];
    if ([format isEqualToString:@"filmstrip"]) {
        return kECVideoAdFilmStrip;
    }
    else if ([format isEqualToString:@"adcontrolbar"]) {
        return kECVideoAdControlBar;
    }
    else if ([format isEqualToString:@"inlinesocial"]) {
        return kECVideoInlineSocial;
    }
    else if ([format isEqualToString:@"inlinesocialhori"]) {
        return kECVideoInlineSocialHorizontal;
    }
    else if ([format isEqualToString:@"inlinesocialvert"]) {
        return kECVideoInlineSocialVertical;
    }
    else if ([format isEqualToString:@"pulldownsocial"]) {
        return kECVideoAdPullDownSocial;
    }
    else if ([format isEqualToString:@"regional"]) {
        return kECVideoAdRegional;
    }
    else if ([format isEqualToString:@"timesync"]) {
        return kECVideoAdTimeSync;
    }
    else if ([format isEqualToString:@"dpe"] || [format isEqualToString:@"overlay"]) {
        return kECVideoAdDPE;
    }
    else if ([format isEqualToString:@"smartskippable"])
        return kECVideoAdSmartSkippable;
    return kECVideoInlineSocial;
}

- (kECVideoSubType)getSubType {
    NSString *format = [self.videoAdResponseDict objectForKey:@"subformat"];
    NSString *adformat = [[self.videoAdResponseDict objectForKey:@"data"] objectForKey:@"format"];
    
    if ([adformat isEqualToString:@"overlay"]) {
        return kECVideoAdDPEOverlay;
    }
    if ([adformat isEqualToString:@"dpe"]) {
        return kECVideoAdDPEBubble;
    }
    
    if ([format isEqualToString:@"slide banner"]) {
        return kECVideoAdTimeSyncBannerSlide;
    }
    else if ([format isEqualToString:@"overlay"]) {
        return kECVideoAdTimeSyncOverlay;
    }
    else if ([format isEqualToString:@"dpe overlay"]) {
        return kECVideoAdDPEOverlay;
    }
    else if ([format isEqualToString:@"dpe"]) {
        return kECVideoAdDPEBubble;
    }
    else if ([format isEqualToString:@"smartskippable survey"])
        return kECVideoAdSkipSurvey;
    return kECVideoAdTimeSyncBannerSlide;
}

- (void)showVideoAd:(NSMutableDictionary *)adParams {
    UIViewController *rootViewController = [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
    [self showVideoAdWithParameters:adParams adFormat:[self getVidedAdType] withViewController:rootViewController];
}
- (void)showVideoAdWithParameters:(NSDictionary *)addParams adFormat:(kECVideoAdType)videoFormat withViewController:(UIViewController *)vc {
    if (nil == [addParams objectForKey:kECAdAppIDKey])
    {
        ECLog(@"kECAdAppIDKey missing from the params that are passed in");
        return ;
    }
    
    if (![self.pubKey length] && nil == [addParams objectForKey:kECAdAppPublisherKey])
    {
        ECLog(@"kECAdAppPublisherKey missing from the params that are passed in");
        
        return ;
    }
    
    // proceed only if we have network connectivity
    if (NO == self.isReachable)
    {
        ECLog(@"There is NO internet connectivity unable to show Ad");
        return ;
    }
    
    // letter we will present modal viewController on locationManager success and fail methods
    
    // map the ad params passed in, to params that need to be passed to the modal ad viewcontroller
    NSMutableDictionary *modalAdParams = [[NSMutableDictionary alloc] init];
    [self mapAppParams:addParams toAdParams:modalAdParams];
    [self insertAdditionalAdParams:modalAdParams];
    if (![modalAdParams objectForKey:kECAdAppPublisherKey])
        [modalAdParams setObject:self.pubKey forKey:kECAdAppPublisherKey];
    
    if ([addParams objectForKey:kECBannerADURL]) {
        [modalAdParams setObject:[addParams objectForKey:kECBannerADURL] forKey:kECBannerADURL];
    }
    if ([addParams objectForKey:kECAdUserParams])
        [modalAdParams setObject:[addParams objectForKey:kECAdUserParams] forKey:kECAdUserParams];
    
    CGFloat OSVersion =[[[UIDevice currentDevice] deviceCurrentOSVersion] floatValue];
    if (OSVersion >= 5.0) {
        NSString *twitterUN = [self getUsername:ACAccountTypeIdentifierTwitter];
        if ([twitterUN length])
            [modalAdParams setObject:twitterUN forKey:@"twitterusername"];
        if (OSVersion >= 6.0) {
            NSString *fbUN = [self getUsername:ACAccountTypeIdentifierFacebook];
            if ([fbUN length])
                [modalAdParams setObject:fbUN forKey:@"facebookusername"];
            
        }
    }
    
    [self initSDKParams];
    [self.sdkParams addEntriesFromDictionary:modalAdParams];
    
    if ([modalAdParams objectForKey:kECAdSize]) {
        NSArray *size = [self getAdSize:[[modalAdParams objectForKey:kECAdSize] intValue]];
        [self.sdkParams setValue:[size objectAtIndex:0] forKey:@"w"];
        [self.sdkParams setValue:[size objectAtIndex:1] forKey:@"h"];
    }
    //ECLog(@"SDK Video Params: %@",self.sdkParams);
    
    // Convert the params that have been passed in into a query string
    NSString *queryParams = [self queryStringFromParams:self.sdkParams];
    NSString *str = [[NSUserDefaults standardUserDefaults] objectForKey:@"ecvideoserviceurl"];
    NSString *requestURL = ([str length]?str:kECVideoRequestURL);
    requestURL =     [requestURL stringByAppendingString:@"?"];
    requestURL =     [requestURL stringByAppendingString:queryParams];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestURL]] ;
    
    [request setHTTPMethod:@"GET"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        responseString = [self trimResponse:responseString];
        if ([responseString isEqualToString:@"Error"]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"JSON Error" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
                [alertView show];
            });
        }
        //NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        //ECLog(@"responseString = %@ and response statusCode = %d",responseString, [httpResponse statusCode]);
        data=[responseString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            if (responseDictionary) {
                [self.videoAdResponseDict removeAllObjects];
                self.videoAdResponseDict = nil;
                
                self.videoAdResponseDict = [NSMutableDictionary dictionaryWithDictionary:responseDictionary];
                //[[UIApplication sharedApplication] setStatusBarHidden:YES];
                __block kECVideoAdType videoFormat = [self getVidedAdType];
                switch (videoFormat) {
                    case kECVideoAdFilmStrip:
                        [self showVideoAdFilmStrip:[addParams objectForKey:kECVideoADURL]];
                        break;
                    case kECVideoAdDPE:
                        [self showDPEVideoFormat:[addParams objectForKey:kECVideoADURL]];
                        break;
                    case kECVideoInlineSocial:
                        [self showVideoInlineSocial:[addParams objectForKey:kECVideoADURL]];
                        break;
                    case kECVideoInlineSocialHorizontal:
                        [self showInlineSocialHorizontal:[addParams objectForKey:kECVideoADURL]];
                        break;
                    case kECVideoInlineSocialVertical:
                        [self showInlineSocialVertical:[addParams objectForKey:kECVideoADURL]];
                        break;
                        
                    case kECVideoAdControlBar:
                        [self showVideoAdControlBar:[addParams objectForKey:kECVideoADURL]];
                        break;
                    case kECVideoAdTimeSync:
                        [self showVideoAdTimeSync:[addParams objectForKey:kECVideoADURL]];
                        break;
                    case kECVideoAdPullDownSocial:
                        [self showVideoAdPullDownSocial:[addParams objectForKey:kECVideoADURL]];
                        break;
                    case kECVideoAdRegional:
                        [self showVideoAdRegional:[addParams objectForKey:kECVideoADURL]];
                        break;
                    case kECVideoAdSmartSkippable:
                        [self showSmartSkippableVideoFormat:[addParams objectForKey:kECVideoADURL]];
                        break;
                    default:
                        break;
                }
                [(ECModalVideoPlaylistAdViewController *)self.modalAdViewController setResponseDict:self.videoAdResponseDict];
                [vc presentViewController:self.modalAdViewController animated:YES completion:^{
                    if ([self.videoAdDelegate respondsToSelector:@selector(videoAdViewDidLoad)])
                        [self.videoAdDelegate videoAdViewDidLoad];
                    [self logVideoImpression];
                    
                }];
            }
            else {
                if ([self.videoAdDelegate respondsToSelector:@selector(videoAdViewDidFailWithError:)])
                    [self.videoAdDelegate videoAdViewDidFailWithError:nil];
            }
        });
    }];
}
- (void)showSmartSkippableVideoFormat:(NSString *)url {
    UIViewController *viewController = nil;
    viewController = [[ECModalVideoPlaylistAdViewController alloc] init];
    [(ECModalVideoPlaylistAdViewController *)viewController setBasePath:url];
    if ([self getSubType] == kECVideoAdSkipSurvey)
        [(ECModalVideoPlaylistAdViewController *)viewController setAdFormat:kECAdSmartSkipSurvey];
    else
        [(ECModalVideoPlaylistAdViewController *)viewController setAdFormat:kECAdSmartSkip];
    
    [(ECModalVideoPlaylistAdViewController *)viewController setDelegate:self];
    self.modalAdViewController = viewController;
    
}

- (void)showDPEVideoFormat:(NSString *)url {
    if ([self getSubType] == kECVideoAdDPEBubble) {
        ECModalVideoPlaylistAdViewController *vc = [[ECModalVideoPlaylistAdViewController alloc] init];
        [vc setDelegate:self];
        [vc setAdFormat:kECAdControlOverlay];
        self.modalAdViewController = vc;
    }
    else {
        ECModalDPEViewController *viewController = [[ECModalDPEViewController alloc] init];
        [viewController setDelegate:self];
        [viewController setDPEFormat:kECDPEFormatOverlay];
        self.modalAdViewController = viewController;
    }
}

- (void)showVideoAdFilmStrip:(NSString *)url {
    ECModalVideoPlaylistAdViewController * viewController = [[ECModalVideoPlaylistAdViewController alloc] init];
    [(ECModalVideoPlaylistAdViewController *)viewController setBasePath:url];
    [(ECModalVideoPlaylistAdViewController *)viewController setAdFormat:kECVideoPlaylist];
    [(ECModalVideoPlaylistAdViewController *)viewController setDelegate:self];
    self.modalAdViewController = viewController;
    
}


- (void)showVideoInlineSocial:(NSString *)url {
    UIViewController *viewController = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        viewController =  [[ECModalVideoAdViewController_iPhone alloc] init];
    } else {
        viewController = [[EcModalVideoAdViewController alloc] init];
    }
    [(EcModalVideoAdViewController *)viewController setBasePath:url];
    [(EcModalVideoAdViewController *)viewController setDelegate:self ];
    self.modalAdViewController = viewController;
    
}

- (void)showInlineSocialHorizontal:(NSString *)url {
    ECModalVideoInlineSocialViewController *viewController = [[ECModalVideoInlineSocialViewController alloc] init];
    [viewController setDelegate:self];
    [viewController setECInlineFormat:kECInlineFormatSocialHorizontal];
    self.modalAdViewController = viewController;
    [viewController setBasePath:url];
    
}

- (void)showInlineSocialVertical:(NSString *)url {
    ECModalVideoInlineSocialViewController *viewController = [[ECModalVideoInlineSocialViewController alloc] init];
    [viewController setDelegate:self];
    [viewController setECInlineFormat:kECInlineFormatSocialVertical];
    self.modalAdViewController = viewController;
    [viewController setBasePath:url];
}
- (void)showVideoAdControlBar:(NSString *)url {
    ECModalVideoPlaylistAdViewController *viewController = [[ECModalVideoPlaylistAdViewController alloc] init];
    [(ECModalVideoPlaylistAdViewController *)viewController setBasePath:url];
    
    //    [(ECModalVideoPlaylistAdViewController *)viewController setBasePath:@"http://devefence.engageclick.com/ecadserve/ecvideoFlash?mediaIdExternal=6&mediaSystemId=1&flashFormat=FSALL"];
    
    [(ECModalVideoPlaylistAdViewController *)viewController setAdFormat:kECAdControlBar];
    [(ECModalVideoPlaylistAdViewController *)viewController setDelegate:self];
    self.modalAdViewController = viewController;
    
}

- (void)showVideoAdTimeSync:(NSString *)url {
    ECModalVideoAdTimeSyncViewController *viewController = [[ECModalVideoAdTimeSyncViewController alloc] init];
    [viewController setDelegate:self];
    [viewController setAdFormat:[self getSubType]];
    self.modalAdViewController = viewController;
    [viewController setBasePath:url];
}

- (void)showVideoAdPullDownSocial:(NSString *)url {
    ECModalVideoFilmStripAdViewController *viewController = [[ECModalVideoFilmStripAdViewController alloc] init];
    [viewController setDelegate:self];
    self.modalAdViewController = viewController;
    [viewController setBasePath:url];
    
    //    [viewController setBasePath:@"http://devefence.engageclick.com/ecadserve/ecvideoFlash?mediaIdExternal=7&mediaSystemId=1&flashFormat=FSALL"];
}

- (void)showVideoAdRegional:(NSString *)url {
    url = [url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    ECModalViewRegionalViewController *viewController = [[ECModalViewRegionalViewController alloc] init];
    [viewController setDelegate:self];
    self.modalAdViewController = viewController;
    
}

- (void)format1Clicked_iPhone {
    UIViewController *viewController = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        viewController =  [[ECModalVideoAdViewController_iPhone alloc] init];
    } else {
        viewController = [[EcModalVideoAdViewController alloc] init];
    }
    [(EcModalVideoAdViewController *)viewController setDelegate:self ];
    self.modalAdViewController = viewController;
    
}



- (void)adVideoDidFinishPlayback {
    [self.modalAdViewController dismissViewControllerAnimated:YES completion:^{
        self.modalAdViewController = nil;
        if ([self.videoAdDelegate respondsToSelector:@selector(videoAdViewDidClose)])
            [self.videoAdDelegate videoAdViewDidClose];
        [self bulkLog];
        // [[UIApplication sharedApplication] setStatusBarHidden:NO];
        
    }];
}

- (NSMutableDictionary *)getVideoLogDict {
    if (![self.videoAdResponseDict objectForKey:@"logdict"])
        [self.videoAdResponseDict setObject:[NSMutableDictionary dictionary] forKey:@"logdict"];
    return [self.videoAdResponseDict objectForKey:@"logdict"];
    
}
- (void)bulkLog {
    NSMutableDictionary *logDict = [self.videoAdResponseDict objectForKey:@"logdict"];
    if (![logDict objectForKey:@"userAdClose"])
        [logDict setObject:@"yes" forKey:@"videoCompleted"];
    if ([[self.videoAdResponseDict objectForKey:@"enablelog"] isEqualToString:@"no"] ||![logDict count] || !self.isReachable || ![self.videoAdResponseDict objectForKey:@"adid"] || ![self.videoAdResponseDict objectForKey:@"reqid"])
        return;
    NSString *url = [[NSUserDefaults standardUserDefaults] objectForKey:@"ecblklogurl"];
    url = [url stringByAppendingString:@"?"];
    
    url =[url stringByAppendingString:[NSString stringWithFormat:@"pubkey=%@&appid=%@&deviceid=%@&zid=%@&adid=%@&adreqid=%@&blklog=%@&idfv=%@&idfa=%@",self.pubKey,[[NSBundle mainBundle] bundleIdentifier],[[UIDevice currentDevice] EC_formattedUniqueIdentifier],[self.sdkParams objectForKey:kECAdAppZoneIDKey],[self.videoAdResponseDict objectForKey:@"adid"],[self.videoAdResponseDict objectForKey:@"reqid"],[self parseMessageFromLog:logDict],[[UIDevice currentDevice] EC_identifierForVendor],[[UIDevice currentDevice] EC_advertisingIdentifier]]];
    
    [self logResponse:url method:@"POST"];
}

- (NSString *)parseMessageFromLog:(NSMutableDictionary *)logDict {
    __block NSString *message=@"";
    [logDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        message = [message stringByAppendingString:[NSString stringWithFormat:@"%@=%@:",key,obj]];
    }];
    return message;
}

- (void)logVideoImpression {
    NSString *url = [[NSUserDefaults standardUserDefaults] objectForKey:@"ecimpserviceurl"];
    if (![url length] || !self.isReachable || ![self.videoAdResponseDict objectForKey:@"adid"] || ![self.videoAdResponseDict objectForKey:@"reqid"])
        return;
    url = [url stringByAppendingString:@"?"];
    
    url =[url stringByAppendingString:[NSString stringWithFormat:@"pubkey=%@&appid=%@&deviceid=%@&zid=%@&adid=%@&adreqid=%@&idfv=%@&idfa=%@",self.pubKey,[[NSBundle mainBundle] bundleIdentifier],[[UIDevice currentDevice] EC_formattedUniqueIdentifier],[self.sdkParams objectForKey:kECAdAppZoneIDKey],[self.videoAdResponseDict objectForKey:@"adid"],[self.videoAdResponseDict objectForKey:@"reqid"],[[UIDevice currentDevice] EC_identifierForVendor],[[UIDevice currentDevice] EC_advertisingIdentifier]]];
    [self logResponse:url method:@"GET"];
    
}

- (void)logResponse:(NSString *)url method:(NSString *)method {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]] ;
    
    [request setHTTPMethod:method];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if ([httpResponse statusCode] == 200)
        {
            ECLog(@"Video AD State Logged");
        }
    }];
    
    
}

- (void)videoAdLandingPageOpened:(NSString *)landingpage {
    NSString *url = [[NSUserDefaults standardUserDefaults] objectForKey:@"ecclickserviceurl"];
    if ([[self.videoAdResponseDict objectForKey:@"enablelog"] isEqualToString:@"no"] || ![url length] || !self.isReachable || ![self.videoAdResponseDict objectForKey:@"adid"] || ![self.videoAdResponseDict objectForKey:@"reqid"])
        return;
    url = [url stringByAppendingString:@"?"];
    
    url = [url stringByAppendingString:[NSString stringWithFormat:@"pubkey=%@&appid=%@&deviceid=%@&zid=%@&adid=%@&adreqid=%@&ecadurl=%@&idfv=%@&idfa=%@",self.pubKey,[[NSBundle mainBundle] bundleIdentifier],[[UIDevice currentDevice] EC_formattedUniqueIdentifier],[self.sdkParams objectForKey:kECAdAppZoneIDKey],[self.videoAdResponseDict objectForKey:@"adid"],[self.videoAdResponseDict objectForKey:@"reqid"],landingpage,[[UIDevice currentDevice] EC_identifierForVendor],[[UIDevice currentDevice] EC_advertisingIdentifier]]];
    [self logResponse:url method:@"GET"];
}

#pragma mark - Full Page Ad

- (BOOL)showECModalAdWithParameters:(NSDictionary *)appParams withViewController:(UIViewController *)vc refresh:(CGFloat)refreshRate {
    if (nil == [appParams objectForKey:kECAdAppIDKey]) {
        ECLog(@"kECAdAppIDKey missing from the params that are passed in");
        return NO;
        
    }
    if (![self.pubKey length] && nil == [appParams objectForKey:kECAdAppPublisherKey])
    {
        ECLog(@"kECAdAppPublisherKey missing from the params that are passed in");
        return NO;
    }
    
    // proceed only if we have network connectivity
    if (NO == self.isReachable)
    {
        ECLog(@"There is NO internet connectivity unable to show Ad");
        return NO;
    }
    
    
    // letter we will present modal viewController on locationManager success and fail methods
    
    // map the ad params passed in, to params that need to be passed to the modal ad viewcontroller
    NSMutableDictionary *modalAdParams = [[NSMutableDictionary alloc] init];
    [self mapAppParams:appParams toAdParams:modalAdParams];
    [self insertAdditionalAdParams:modalAdParams];
    if (![modalAdParams objectForKey:kECAdAppPublisherKey])
        [modalAdParams setObject:self.pubKey forKey:kECAdAppPublisherKey];
    
    if ([appParams objectForKey:kECBannerADURL]) {
        [modalAdParams setObject:[appParams objectForKey:kECBannerADURL] forKey:kECBannerADURL];
    }
    if ([appParams objectForKey:kECAdUserParams])
        [modalAdParams setObject:[appParams objectForKey:kECAdUserParams] forKey:kECAdUserParams];
    
    CGFloat OSVersion =[[[UIDevice currentDevice] deviceCurrentOSVersion] floatValue];
    if (OSVersion >= 5.0) {
        NSString *twitterUN = [self getUsername:ACAccountTypeIdentifierTwitter];
        if ([twitterUN length])
            [modalAdParams setObject:twitterUN forKey:@"twitterusername"];
        if (OSVersion >= 6.0) {
            NSString *fbUN = [self getUsername:ACAccountTypeIdentifierFacebook];
            if ([fbUN length])
                [modalAdParams setObject:fbUN forKey:@"facebookusername"];
            
        }
    }
    
    //Make a Request and be ready
    NSMutableDictionary *sdkParams = [self modalAdSDKParams:modalAdParams];
    [sdkParams addEntriesFromDictionary:modalAdParams];

    //ECLog(@"Modal Params %@", modalAdParams);
    //ECLog(@"City: %@ : Region: %@: Country: %@",self.currentCity,self.currentRegion,self.currentCountry);

    NSURL *bannerURL = [self getBannerURL:modalAdParams SDK:sdkParams];//[NSURL URLWithString:[self.adParams objectForKey:kECBannerADURL]];
    NSURLRequest *bannerRequest = [NSURLRequest requestWithURL:bannerURL];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:bannerRequest queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSMutableDictionary *responseDict = [NSMutableDictionary dictionary];
            [responseDict setObject:httpResponse forKey:@"httpResponse"];
            if ([data length])
                [responseDict setObject:data forKey:@"data"];
            if (error)
                [responseDict setObject:error forKey:@"error"];
            // create the ECModalAdVC and show it
            self.modalAdViewController = [[ECModalAdViewController alloc] initWithAdParams:modalAdParams];
            [(ECModalAdViewController *)self.modalAdViewController setRefreshRate:refreshRate];
            [(ECModalAdViewController *)self.modalAdViewController setSdkParams:sdkParams];
            [(ECModalAdViewController *)self.modalAdViewController setResponseDict:responseDict];
            [(ECModalAdViewController *)self.modalAdViewController setDelegate:self];
            
            [vc presentViewController:self.modalAdViewController animated:YES completion:nil];
        });
        
    }];
    
    
    
    
    return YES;
}


- (void)dismissECModalAd:(BOOL)animated {
    if (self.modalAdViewController)
        [self.modalAdViewController dismissModalViewControllerAnimated:animated];
}
- (void)refreshModalAd:(NSArray *)adsize {
    if ([self.modalAdViewController respondsToSelector:@selector( refreshAd:)])
        [self.modalAdViewController performSelector:@selector(refreshAd:) withObject:adsize];
    
}

- (NSURL *)getBannerURL:(NSMutableDictionary *)adParams SDK:(NSMutableDictionary *)sdkParams {
    NSURL *url;
    if ([adParams objectForKey:kECBannerADURL])
        url = [NSURL URLWithString:[adParams objectForKey:kECBannerADURL]];
    else {
        NSString *str = [[NSUserDefaults standardUserDefaults] objectForKey:@"ecadserviceurl"];
        NSString *requestURL = ([str length]?str:@"http://serve.engageclick.com/ecadserve/ecadserve?cltype=ecsdk&rformat=html&");
        requestURL =     [requestURL stringByAppendingString:@"?cltype=ecsdk&rformat=html&"];
        
        NSString *queryParams = [NSString stringWithFormat:@"%@%@",requestURL,[self queryStringFromParams:sdkParams]];//[self queryStringFromParams:self.sdkParams];
        url = [NSURL URLWithString:queryParams];
    }
    return url;
}


- (NSMutableDictionary *)modalAdSDKParams:(NSMutableDictionary *)adParams {
    NSMutableDictionary *sdkParams = [[NSMutableDictionary alloc] init];
    
    if ([adParams objectForKey:kECAdSize]) {
        NSArray *size = [self getAdSize:[[adParams objectForKey:kECAdSize] intValue]];
        [sdkParams setValue:[size objectAtIndex:0] forKey:@"w"];
        [sdkParams setValue:[size objectAtIndex:1] forKey:@"h"];
    }
    else {
        int width = [UIScreen mainScreen].bounds.size.width;
        int height = [UIScreen mainScreen].bounds.size.height;
        // set the viewport height and width
        [sdkParams setValue:[NSString stringWithFormat:@"%d",width] forKey:kECAdWidth];
        [sdkParams setValue:[NSString stringWithFormat:@"%d",height] forKey:kECAdHeight];
        
    }
    
    // set the ad type
    [sdkParams setValue:@"s" forKey:@"adtype"];
    
    // set the request time stamp
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss:SSS";
    [sdkParams setValue:[dateFormatter stringFromDate:now] forKey:@"reqtimestamp"];
    
    // set the medium
    [sdkParams setValue:@"mweb" forKey:@"medium"];
    
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = [bundle infoDictionary];
    NSString *prodName = [info objectForKey:@"CFBundleDisplayName"];
    
    [sdkParams setValue:prodName forKey:@"hurl"];
    [sdkParams setValue:[[NSBundle mainBundle] bundleIdentifier] forKey:@"bundleID"];
    



    // add the carrier information
    [[ECAdManager sharedManager] addTelephonyCarrierInfoToParams:sdkParams];
    return sdkParams;
}

-(void)canECAdLibGetLocation:(BOOL)shouldAllocateLocation currentLocation:(CLLocation*)currentLocation
{
    self.shouldSDKUseCurrentLocation = [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized;
    
    if (nil == self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = kCLDistanceFilterNone; // whenever we move
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 100 m
    }
    if(self.shouldSDKUseCurrentLocation)
    {
        if(nil == currentLocation)
        {
            [self.locationManager startUpdatingLocation];
        }
        else
        {
            self.currentLocationCoordinate = currentLocation.coordinate;
            [self getRegionFromCurrentLocation:currentLocation];
        }
    }
}

#pragma mark - Private
- (void)saveResponsesToFile
{
    [self.adStateDict writeToFile:self.adResponsesFile atomically:YES];
}

- (void)loadResponsesFromFile
{
    self.adStateDict = [NSDictionary dictionaryWithContentsOfFile:self.adResponsesFile];
    if (nil == self.adStateDict)
    {
        self.adStateDict = [[NSMutableDictionary alloc] init];
    }
    
    NSMutableArray *olderAdResponses = [self.adStateDict objectForKey:kECADStateParam];
    if (nil != olderAdResponses)
    {
        [self.adResponses addObjectsFromArray:olderAdResponses];
    }
}

- (void)mapAppParams:(NSDictionary *)appParams toAdParams:(NSMutableDictionary *)modalAdParams
{
    for(NSString* key in appParams)
    {
        NSString *value = [appParams objectForKey:key];
        if ([key isEqualToString:kECAdAppPublisherKey])
        {
            [modalAdParams setValue:value forKey:kECModalAdAppPublisherKey];
        }
        else if ([key isEqualToString:kECAdAppZoneIDKey])
        {
            [modalAdParams setValue:value forKey:kECModalAdZoneIDKey];
        }
        else if ([key isEqualToString:kECAdAppSiteIDKey])
        {
            [modalAdParams setValue:value forKey:kECAdAppSiteIDKey];
        }
        else if ([key isEqualToString:kECAdAppIDKey])
        {
            [modalAdParams setValue:value forKey:kECModalAdAppIDKey];
        }
        else if ([key isEqualToString:kECAdReferrerKey])
        {
            [modalAdParams setValue:value forKey:kECModalAdReferrerKey];
        }
        else if ([key isEqualToString:kECKeywordKey])
        {
            [modalAdParams setValue:value forKey:kECModalAdKeywordKey];
        }
        else if ([key isEqualToString:kECCategoryKey])
        {
            [modalAdParams setValue:value forKey:kECModalAdCategoryKey];
        }
        else if ([key isEqualToString:kECAdSize])
        {
            [modalAdParams setValue:value forKey:kECAdSize];
            NSArray *size = [self getAdSize:[value intValue]];
            [modalAdParams setValue:[size objectAtIndex:0] forKey:kECAdWidth];
            [modalAdParams setValue:[size objectAtIndex:1] forKey:kECAdHeight];

        }
    }
}


- (void)insertAdditionalAdParams:(NSMutableDictionary *)modalAdParams
{
    [self updateReachability];
    if (self.isWiFiAsActiveNetwork)
        [modalAdParams setValue:@"wifi" forKey:kECIsWifi];
    else
        [modalAdParams setValue:@"data" forKey:kECIsWifi];
    
    [modalAdParams setValue:@"Apple" forKey:kECAdBrand];
    [modalAdParams setValue:self.sessionID forKey:kECAdSessionID];
    [modalAdParams setValue:kECAdSDKVersionNumber forKey:kECAdSDKVersion];
    [modalAdParams setValue:kECAdIOS forKey:kECAdOSName];
    
    // Add params to pass device and os information
    UIDevice *currentDevice = [UIDevice currentDevice];
    [modalAdParams setValue:[UIDevice model] forKey:kECAdModel];
    [modalAdParams setValue:[currentDevice deviceCurrentOSVersion] forKey:kECAdIOSVersion];
    [modalAdParams setValue:[currentDevice EC_formattedUniqueIdentifier] forKey:kECAdDeviceID];
    [modalAdParams setValue:[currentDevice EC_identifierForVendor] forKey:kECAdDeviceIDFV];
    [modalAdParams setValue:[currentDevice EC_advertisingIdentifier] forKey:kECAdDeviceIDFA];
    [modalAdParams setValue:([currentDevice EC_isAdvertisingTrackingEnabled] ? @"true":@"false") forKey:kECAdDeviceTrackingEnabled];
    //[modalAdParams setValue:[self getMacAddress] forKey:kECAdMacId];
    
    
    if(YES == self.shouldSDKUseCurrentLocation)
    {
        [modalAdParams setValue:[NSNumber numberWithDouble:self.currentLocationCoordinate.latitude] forKey:kECAdLatitude];
        [modalAdParams setValue:[NSNumber numberWithDouble:self.currentLocationCoordinate.longitude] forKey:kECAdLongitude];
        if (self.currentCity)
            [modalAdParams setValue:self.currentCity forKey:kECAdCity];
        if (self.currentRegion)
            [modalAdParams setValue:self.currentRegion forKey:kECAdRegion];
        if (self.currentCountry)
            [modalAdParams setValue:self.currentCountry forKey:kECAdCountry];
    }
    
    [self addTelephonyCarrierInfoToParams:modalAdParams];
}

- (NSString *)getUsername:(NSString *)typeIdentifier {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:typeIdentifier];
    BOOL access = [accountType accessGranted];
    if (access) {
        NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
        if ([accountsArray lastObject]) {
            ACAccount *account = [accountsArray objectAtIndex:0];
            return  account.username;
        }
    }
    return nil;
}

- (NSString *)getMacAddress
{
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    NSString            *errorFlag = NULL;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
        errorFlag = @"if_nametoindex failure";
    else
    {
        // Get the size of the data available (store in len)
        if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
            errorFlag = @"sysctl mgmtInfoBase failure";
        else
        {
            // Alloc memory based on above call
            if ((msgBuffer = malloc(length)) == NULL)
                errorFlag = @"buffer allocation failure";
            else
            {
                // Get system information, store in buffer
                if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
                    errorFlag = @"sysctl msgBuffer failure";
            }
        }
    }
    
    // Befor going any further...
    if (errorFlag != NULL)
    {
        NSLog(@"Error: %@", errorFlag);
        return errorFlag;
    }
    
    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
    
    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
    
    // Copy link layer address data in socket structure to an array
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
    
    // Read from char array into a string object, into traditional Mac address format
    NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                                  macAddress[0], macAddress[1], macAddress[2],
                                  macAddress[3], macAddress[4], macAddress[5]];
    NSLog(@"Mac Address: %@", macAddressString);
    
    // Release the buffer memory
    free(msgBuffer);
    
    return macAddressString;
}



- (NSString *)generateSessionID
{
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    NSString * uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    CFRelease(newUniqueId);
    
    return uuidString;
}

- (void)postAdResponseToServer:(NSDictionary *)resoponse
{
    if (!self.enableDebugLog)
        return;
    //// {"adstate": [{"adid":1,"state":"SUCCESS","requestid":"value","sessionid":"somevalue"}]}
    
    // Put the response into an array cause we need to be able to report multiple ad results at the same time
    [self.adResponses addObject:resoponse];
    
    // package the array of responses into a dictionary
    [self.adStateDict setValue:self.adResponses forKey:kECADStateParam];
    
    // create  a request using the EC Log URL
    NSString *path = kECADStateLogURL ;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"ecdebugurl"])
        path = [[NSUserDefaults standardUserDefaults] objectForKey:@"ecdebugurl"];
    
    path = [path stringByAppendingString:@"?message=iossdk:-debug:closed"];
    __block NSString *str = [[NSString alloc] init];
    [self.adResponses enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        str = [self queryStringFromParams:obj];
        if (idx < [self.adResponses count]-1)
            str = [str stringByAppendingString:@"&"];
    }];
    NSString *queryParams = [NSString stringWithFormat:@"%@%@",path,str];
    
    
    
    
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:queryParams]] ;
    
    // This will be a POST call with the reponse of the ad being the json data
    [request setHTTPMethod:@"GET"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    // make an async call to send the response
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        //ECLog(@"responseString = %@ and response statusCode = %d",responseString, [httpResponse statusCode]);
        
        if ([httpResponse statusCode] == 200)
        {
            [self.adResponses removeAllObjects];
            [self.adStateDict setValue:self.adResponses forKey:kECADStateParam];
        }
        [self saveResponsesToFile];
    }];
    
}

#pragma mark - ECModalAdDelegate method
- (void)modalAdDidFinishWithResult:(kECModalAdResult)result withServerResponse:(NSDictionary *)response
{
    self.modalAdViewController = nil;
    //ECLog(@"Result of Showing Ad - %d\n Response for EC server = %@", result, response);
    NSString *adResult;
    
    // map the result from the modal ad controller to return the result to the app
    switch (result) {
        case kECModalAdUserInteractionComplete:
            adResult = kECAdUserCompletedInteraction;
            break;
            
        case kECModalAdUserClose:
            adResult = kECAdUserClosedAd;
            break;
            
        case kECModalAdTimeout:
            adResult = kECAdAdTimedOut;
            break;
            
        default:
            break;
    }
    
    // put the result into the user info
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setValue:adResult forKey:kECAdStatusKey];
    
    // send the notification to the app about the result of showing the ad
    [[NSNotificationCenter defaultCenter] postNotificationName:kECAdManagerDidShowAdNotification object:self userInfo:userInfo];
    [Flurry logEvent:ModalAdClose withParameters:userInfo];
    
    // send response to EC server
    if (response)
        [self postAdResponseToServer:response];
}

#pragma mark
#pragma mark locationManager Delegate methods


- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    self.currentLocationCoordinate = newLocation.coordinate;
    [self getRegionFromCurrentLocation:newLocation];
    
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
    self.locationManager = nil;
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self canECAdLibGetLocation:self.shouldSDKUseCurrentLocation currentLocation:nil];
}

#pragma mark - Reachability Notification
- (void) reachabilityChanged: (NSNotification* )note
{
    [self updateReachability];
}

- (void)updateReachability
{
    self.isReachable = [self.reachability currentReachabilityStatus] != NotReachable;
    self.isWiFiAsActiveNetwork = ([self.reachability currentReachabilityStatus] == ReachableViaWiFi );
    
}

- (BOOL)isReachable {
    return  [self.reachability currentReachabilityStatus] != NotReachable;
}

-(void)getRegionFromCurrentLocation:(CLLocation*)currentLocation
{
    [Flurry setLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude horizontalAccuracy:currentLocation.horizontalAccuracy verticalAccuracy:currentLocation.verticalAccuracy];
    
    CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        for (CLPlacemark * placemark in placemarks) {
            
            
            self.currentCity = [placemark locality];
            self.currentCountry = [placemark country];
            self.currentRegion = [[placemark region] identifier];
        }
    }];
    
}
@end
