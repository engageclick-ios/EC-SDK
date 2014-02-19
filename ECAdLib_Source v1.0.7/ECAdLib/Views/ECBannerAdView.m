//
//  ECModalBannerAdView.m
//  ECAdLib
//
//  Created by Karthik Kumaravel on 5/21/13.
//  Copyright (c) 2013 EngageClick. All rights reserved.
//

#import "ECBannerAdView.h"
#import "ECAdManager.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <AudioToolbox/AudioServices.h>
#import "ECAdConstants.h"
#import "MRProperty.h"
#import "MPGlobal.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "ECAdMapPoint.h"
#import "ECMRAIDHelper.h"
#import <StoreKit/StoreKit.h>

#define kGOOGLE_API_KEY @"AIzaSyBO25quts5C-FJFt5zdLuZWOmPLU58h5uQ"

NSInteger const kECBannerAdShowCloseButtonDelay = 5;
static NSString * const kMraidURLScheme = @"mraid";
static NSString * const kECURLScheme = @"ecad";

#pragma mark - Ad Parameters to be passed to Ad Server

// parameters to be supplied by app developer
NSString * const kECBannerAdAppPublisherKey = @"pubkey";
NSString * const kECBannerAdAppIDKey = @"appid";
NSString * const kECBannerAdZoneIDKey = @"zid";
NSString * const kECBannerAdReferrerKey = @"referrer";
NSString * const kECBannerAdKeywordKey = @"keyword";
NSString * const kECBannerAdCategoryKey = @"category";

// parameters that the app can figure out for itself
NSString * const kECBannerAdTypeKey = @"adtype";
NSString * const kECBannerAdViewportWidth = @"w";
NSString * const kECBannerAdViewportHeight = @"h";
NSString * const kECBannerAdRequestTime = @"reqtimestamp";
NSString * const kECBannerAdMedium = @"medium";
NSString * const kECBannerAdCarrier = @"carrier";
NSString * const kECBannerAdMCC = @"mcc";
NSString * const kECBannerAdMNC = @"mnc";
NSString * const kECBannerAdHURL = @"hurl";


// navigate actions sent by ad from webview
NSString * const kECBannerAdScheme = @"ecad";
NSString * const kECBannerAdActionClose = @"close";
NSString * const kECBannerAdActionAdLoaded = @"adloaded";
NSString * const kECBannerAdActionAdFailed = @"adfailed";

NSString * const kECBannerAdActionAdVibrate = @"vibrate";
NSString * const kECBannerAdActionInteractionSuccess = @"INTERACTION_SUCCESS";
NSString * const kECBannerAdActionInteractionTimeout = @"TIMEDOUT";
NSString * const kECBannerAdID = @"adid";
NSString * const kECBannerRequestID = @"requestid";
NSString * const kECBannerShouldEnableLog = @"shouldenablelog";
NSString * const kECBannerIsBackgroundTransparent = @"isbackgroundtransparent";

NSString * const kECBannerAdTime = @"time";
NSString * const kECBannerAdState = @"state";

NSString * const kECBannerAdCallus = @"callus";

NSString * const kECBannerAdresize = @"resize";

NSString * const kECBannerAdOpenAppStore = @"openappstore";
NSString * const kECBannerAdLocate = @"locate";
NSString * const kECBannerAdCallback = @"callback";
NSString * const kECBannerAdExpand = @"expand";
NSString * const kECBannerAdOpen = @"open";
NSString * const kECExpandableUseCustomClose = @"usecustomclose";

NSString * const kBannerADCloseParamArray = @"closeParamArray";

NSString * const kECADPassURL = @"pass";


NSString * const kECBannerRequestURL = @"http://serve.engageclick.com/ecadserve/ecadserve";//@"http://demo.engageclick.com/client/js/interaction/minline/ecinline.m.webview.1.0.js?";


@interface ECBannerAdView ()<CLLocationManagerDelegate,SKStoreProductViewControllerDelegate> {
    BOOL isLoading;
    MRAdViewPlacementType _placementType;
    MRAdViewState _currentState;
    CGRect homeRect_;
    CGRect expandFrame_;
    CGRect _defaultFrameInKeyWindow;
    int _originalTag;
    int _parentTag;
    BOOL isMRAID;

}

@property (nonatomic, assign) UIView *parentView;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSMutableDictionary *sdkParams;
@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) NSString *keyword;
@property (nonatomic, strong) NSString *impURL;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
- (void)loadAd;
- (NSData *)loadFile:(NSString *)name fromBundle:(NSBundle *)bundle;
- (void)initSDKParams:(NSMutableDictionary *)dict;
- (void)finishAdWithResult:(kECBannerAdResult)result;
- (void)addECADParamsFrom:(NSDictionary*)inADParameters ToParmas:(NSMutableDictionary*)dictionary;
//- (void)showCloseButton;
- (void)vibrateDevice;
- (NSDictionary *)responseToSendToECForResult:(kECBannerAdResult)result;

@end
@implementation ECBannerAdView

- (id)initWithAdParams:(NSDictionary *)appAdParams
{
    self = [super init];
    if (self)
    {
        self.adParams = appAdParams;
    }
    return self;
}

- (void)setCloseButtonHidden:(BOOL)hide {
    //self.closeBtn.hidden = hide;
}

- (id)initWithParentView:(UIView *)parentView_{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.parentView  = parentView_;
        self.libBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"ECAdLibResources" withExtension:@"bundle"]];
        self.clickURL = nil;
     }
    return self;
}




- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)layoutFrame:(CGRect)rect {
    self.frame = rect;
    homeRect_ = rect;
    if (nil == self.webView) {
        self.webView = [[UIWebView alloc] initWithFrame:self.bounds];
        [self addSubview:self.webView];
        [self.webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self.webView setBackgroundColor:[UIColor clearColor]];
        [self.webView.scrollView setScrollEnabled:NO];
        [self.webView setAllowsInlineMediaPlayback:YES];
        if (self.customWebView) {
            [self.webView setOpaque:NO];
        }
    }
    self.webView.frame = self.bounds;
}

- (void)refreshAd {
    [self initSDKParams:nil];
    [self loadAd];
}
- (void)setWebLink:(NSData *)webLink {
    _webLink = webLink;
    if (nil !=  webLink) {
        
    }
}

- (void)finishAdWithResult:(kECBannerAdResult)result
{
    NSDictionary *serverResponse = [self responseToSendToECForResult:result];
    //[self dismissViewControllerAnimated:YES completion:nil];
    [self.delegate bannerAdDidFinishWithResult:result withServerResponse:serverResponse];
    if ([self.delegate respondsToSelector:@selector(bannerDidRestore:)])
        [self.delegate performSelector:@selector(bannerDidRestore:) withObject:self];

}

- (NSDictionary *)responseToSendToECForResult:(kECBannerAdResult)result
{
    if ([[self.sdkParams objectForKey:kECBannerShouldEnableLog] caseInsensitiveCompare:@"yes"] == NSOrderedSame || [[self.sdkParams objectForKey:kECBannerShouldEnableLog] caseInsensitiveCompare:@"true"] == NSOrderedSame || ![self.sdkParams objectForKey:kECBannerAdID] || ![self.sdkParams objectForKey:kECBannerRequestID])
        return nil;
    NSString *stateOfRequest;
    
    // translate the result of showing the Ad into a string
    switch (result)
    {
        case kECBannerAdUserInteractionComplete:
            stateOfRequest = kECBannerAdActionInteractionSuccess;
            break;
        case kECBannerAdUserClose:
            stateOfRequest = kECBannerAdActionClose;
            break;
        case kECBannerAdTimeout:
            stateOfRequest = kECBannerAdActionInteractionTimeout;
            break;
        case kECBannerAdDynamic:
            stateOfRequest = [self.sdkParams objectForKey:kECBannerAdState];
            break;
        default:
            break;
    }
    
    
    NSMutableDictionary* info = [[NSMutableDictionary alloc] init];
    
    // Add the Ad ID that was shown
    NSString *adID = [self.sdkParams objectForKey:kECBannerAdID];
    if ([adID length])
        [info setValue:adID forKey:kECBannerAdID];
    
    // Add the result of showing the ad
    if ([stateOfRequest length])
        [info setValue:stateOfRequest forKey:kECBannerAdState];
    
    // The request id for the ad
    NSString *requestID = [self.sdkParams objectForKey:kECBannerRequestID];
    if ([requestID length])
        [info setValue:requestID forKey:kECBannerRequestID];
    
    // and finally the session id
    if ([[self.sdkParams objectForKey:kECAdSessionID] length])
        [info setValue:[self.sdkParams objectForKey:kECAdSessionID] forKey:kECAdSessionID];
//    [self.adCloseParamArray addObject:info];
    
    return info;
}

//- (IBAction)closeClicked:(id)sender
//{
//    // Indicate to the listener that the user closed the Ad
//    [self finishAdWithResult:kECBannerAdUserClose];
//}

- (NSData *)loadFile:(NSString *)name fromBundle:(NSBundle *)bundle
{
    NSArray *fileComponents = [name componentsSeparatedByString:@"."];
    // construct the file for the file that needs to be loaded
    NSString *filePath = [bundle pathForResource:[fileComponents objectAtIndex:0] ofType:[fileComponents objectAtIndex:1]];
    // return the contents of the file
    return [NSData dataWithContentsOfFile:filePath];
}




- (void)initSDKParams:(NSMutableDictionary *)dict
{
    if (nil != dict)
        self.sdkParams = nil;
    
    if (nil == self.sdkParams)
        self.sdkParams = [[NSMutableDictionary alloc] init];
    
    if ([self.adParams objectForKey:kECAdWidth] && [self.adParams objectForKey:kECAdHeight]) {
        [self.sdkParams setValue:[self.adParams objectForKey:kECAdWidth] forKey:kECBannerAdViewportWidth];
        [self.sdkParams setValue:[self.adParams objectForKey:kECAdHeight] forKey:kECBannerAdViewportHeight];
    }
    else {
        int width = self.webView.frame.size.width;
        int height = self.webView.frame.size.height;
        // set the viewport height and width
        [self.sdkParams setValue:[NSString stringWithFormat:@"%d",width] forKey:kECBannerAdViewportWidth];
        [self.sdkParams setValue:[NSString stringWithFormat:@"%d",height] forKey:kECBannerAdViewportHeight];

    }
    
    // set the ad type
    [self.sdkParams setValue:@"i" forKey:kECBannerAdTypeKey];
    
    // set the request time stamp
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss:SSS";
    [self.sdkParams setValue:[dateFormatter stringFromDate:now] forKey:kECBannerAdRequestTime];
    
    // set the medium
    [self.sdkParams setValue:@"mweb" forKey:kECBannerAdMedium];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = [bundle infoDictionary];
    NSString *prodName = [info objectForKey:@"CFBundleDisplayName"];
    
    [self.sdkParams setValue:prodName forKey:kECBannerAdHURL];
    [self.sdkParams setValue:[[NSBundle mainBundle] bundleIdentifier] forKey:@"bundleID"];

    // add the carrier information
    [[ECAdManager sharedManager] addTelephonyCarrierInfoToParams:self.sdkParams];
}
- (NSString *)queryStringFromParams:(NSDictionary *)params
{
    return [[ECAdManager sharedManager] queryStringFromParams:params];
    
}


- (void)loadAd
{
    // Load the HTML page that we will use to show the Ad
    isLoading = YES;
    
    self.webView.scrollView.scrollEnabled = NO;
    self.webView.delegate = self;
    
    [self.sdkParams addEntriesFromDictionary:self.adParams];
    if (([self.adParams objectForKey:kECBannerADURL])) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[self.adParams objectForKey:kECBannerADURL]]]];
        self.webView.scrollView.scrollEnabled = NO;
        return;
    }
    NSURL *bannerURL =[self getBannerURL];//[NSURL URLWithString:[self.adParams objectForKey:kECBannerADURL]];
    NSURLRequest *bannerRequest = [NSURLRequest requestWithURL:bannerURL];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:bannerRequest queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary* headers = [httpResponse allHeaderFields];
        //ECLog(@"Headers %@",headers);
        //ECLog(@"responseString %@",responseString);
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if ([[headers objectForKey:@"X-ADTYPE"] intValue] != 2 &&  [[headers objectForKey:@"X-ADTYPE"] intValue] != 4) {
                ECLog(@"Error: The ad you are trying to render is of Non-Inline / Expandable type");
                [self webView:self.webView didFailLoadWithError:error];
            }
            else {
                if ([headers objectForKey:@"X-CLICK-URL"])
                    [[NSUserDefaults standardUserDefaults] setObject:[headers objectForKey:@"X-CLICK-URL"] forKey:@"ecclickserviceurl"];
                
                
                if ([headers objectForKey:@"X-IMPRESSION-URL"]) {
                    self.impURL = [headers objectForKey:@"X-IMPRESSION-URL"];
                    [[NSUserDefaults standardUserDefaults] setObject:[headers objectForKey:@"X-IMPRESSION-URL"] forKey:@"ecimpserviceurl"];
                }
                
                
                if ([[headers objectForKey:@"X-DEBUG"] intValue] != 0)
                    [[ECAdManager sharedManager] setEnableDebugLog:YES];
                else
                    [[ECAdManager sharedManager] setEnableDebugLog:NO];
                
                if ([[headers objectForKey:@"X-MRAID"] intValue] == 1) // To Enable/Disable Debug Logs To be Sent To The Server
                    isMRAID = YES;
                else
                    isMRAID = NO;
                
                
                if ([[headers objectForKey:@"X-ERROR"] intValue] == 1 || [httpResponse statusCode] != 200 || error || [responseString rangeOfString:@"html"].location == NSNotFound || [responseString rangeOfString:@"HTML"].location == NSNotFound)
                {
                    // handle error condition
                    ECLog(@"Ad Failed:%@",error);
                    [self webView:self.webView didFailLoadWithError:error];
                } else {
                    if (isMRAID) {
                        
                        NSString *mraidBundlePath = [[NSBundle mainBundle] pathForResource:@"ECAdLibResources" ofType:@"bundle"];
                        NSBundle *mraidBundle = [NSBundle bundleWithPath:mraidBundlePath];
                        NSString *mraidPath = [mraidBundle pathForResource:@"mraid" ofType:@"js"];
                        NSString *mraidString = [NSString stringWithContentsOfFile:mraidPath encoding:NSUTF8StringEncoding error:nil];
                        
                        [self.webView stringByEvaluatingJavaScriptFromString:mraidString];
                        
                    }
                    [self.webView loadData:[responseString dataUsingEncoding:NSUTF8StringEncoding] MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:nil];
                    self.webView.scrollView.scrollEnabled = NO;
                }
            }
        });
    }];
    
}


- (NSURL *)getBannerURL {
    NSURL *url;
    if ([self.adParams objectForKey:kECBannerADURL])
        url = [NSURL URLWithString:[self.adParams objectForKey:kECBannerADURL]];
    else {
        NSString *str = [[NSUserDefaults standardUserDefaults] objectForKey:@"ecadserviceurl"];
        NSString *requestURL = ([str length]?str:kECBannerRequestURL);
        requestURL =     [requestURL stringByAppendingString:@"?cltype=ecsdk&rformat=html&"];

        NSString *queryParams = [NSString stringWithFormat:@"%@%@",requestURL,[self queryStringFromParams:self.sdkParams]];//[self queryStringFromParams:self.sdkParams];
        url = [NSURL URLWithString:queryParams];
    }
    return url;
}


- (void)addECADParamsFrom:(NSDictionary *)inADParameters ToParmas:(NSMutableDictionary*)paramDictionary
{
    
    [inADParameters enumerateKeysAndObjectsUsingBlock:^(NSString * key, id obj, BOOL *stop) {
        [paramDictionary setObject:obj forKey:[key lowercaseString]];
    }];
    
    if ([[paramDictionary objectForKey:kECBannerIsBackgroundTransparent] caseInsensitiveCompare:@"yes"] == NSOrderedSame || [[paramDictionary objectForKey:kECBannerIsBackgroundTransparent] caseInsensitiveCompare:@"true"] == NSOrderedSame) {
        self.customWebView = YES;
        [self.webView setOpaque:NO];
    }else {
        self.customWebView = NO;
        [self.webView setOpaque:YES];
    }
    return;
    

    
    
    for(NSString *adParamsString in inADParameters)
    {
        NSArray *paramSeparatedArray = [adParamsString componentsSeparatedByString:@"="];
        if(! [paramSeparatedArray isKindOfClass:[NSNull class]])
        {
            if([paramSeparatedArray count] > 1)
            {
                NSString *paramKey = [paramSeparatedArray objectAtIndex:0];
                NSString *paramValue = [paramSeparatedArray objectAtIndex:1];
                if([paramKey caseInsensitiveCompare:kECBannerAdTime] == NSOrderedSame)
                {
                    [paramDictionary setValue:[NSNumber numberWithInteger:[paramValue integerValue]] forKey:paramKey];
                }
                else if([paramKey caseInsensitiveCompare:kECBannerAdID] == NSOrderedSame)
                {
                    [paramDictionary setValue:paramValue forKey:paramKey];
                }
                else if([paramKey caseInsensitiveCompare:kECBannerRequestID] == NSOrderedSame)
                {
                    [paramDictionary setValue:paramValue forKey:paramKey];
                }
                else if([paramKey caseInsensitiveCompare:kECBannerShouldEnableLog] == NSOrderedSame) {
                        [paramDictionary setValue:paramValue forKey:kECBannerShouldEnableLog];
                }
                else if([paramKey caseInsensitiveCompare:kECBannerIsBackgroundTransparent] == NSOrderedSame) {
                    if ([paramValue caseInsensitiveCompare:@"yes"] == NSOrderedSame) {
                        self.customWebView = YES;
                        [self.webView setOpaque:NO];
                    }else {
                        self.customWebView = NO;
                        [self.webView setOpaque:YES];
                    }
                }
            }
        }
    }
}

- (void)vibrateDevice
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}


#pragma mark - MRAID Java Script Utility
- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation {
    [[ECMRAIDHelper sharedHelper] rotateToOrientation:newOrientation];
    [self rotateExpandedWindowsToCurrentOrientation];
}

- (void)rotateExpandedWindowsToCurrentOrientation {
    // This method must have no effect if our ad isn't expanded.
    if (_currentState != MRAdViewStateExpanded) return;
    
    UIApplication *application = [UIApplication sharedApplication];
    
    // Update the location of our default frame in window coordinates.
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    expandFrame_ =keyWindow.frame;
    CGRect _defaultFrameWithStatusBarOffset = expandFrame_;
    if (!application.statusBarHidden) _defaultFrameWithStatusBarOffset.origin.y += 20;
    expandFrame_ =
    [self convertRectToWindowForCurrentOrientation:_defaultFrameWithStatusBarOffset];
    
    CGRect f = [UIScreen mainScreen].applicationFrame;
    CGPoint centerOfApplicationFrame = CGPointMake(CGRectGetMidX(f), CGRectGetMidY(f));
    
    [UIView beginAnimations:@"expand" context:nil];
    [UIView setAnimationDuration:0.3];
    
    // Center the view in the application frame.
//    self.frame = _defaultFrameInKeyWindow;
    self.center = centerOfApplicationFrame;
   // self.webView.frame = self.bounds;
    
    [self constrainViewBoundsToApplicationFrame];
    [self applyRotationTransformForCurrentOrientationOnView:self];
    
    [UIView commitAnimations];
}

- (void)constrainViewBoundsToApplicationFrame {
    CGFloat height = expandFrame_.size.height;
    CGFloat width = expandFrame_.size.width;
    
    CGRect applicationFrame = MPApplicationFrame();
    if (height > CGRectGetHeight(applicationFrame)) height = CGRectGetHeight(applicationFrame);
    if (width > CGRectGetWidth(applicationFrame)) width = CGRectGetWidth(applicationFrame);
    
    self.bounds = CGRectMake(0, 0, width, height);
}

- (CGRect)orientationAdjustedRect:(CGRect)rect {
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    UIInterfaceOrientation orientation = MPInterfaceOrientation();
    
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            rect.origin.y = keyWindow.frame.size.height - rect.origin.y - rect.size.height;
            rect.origin.x = keyWindow.frame.size.width - rect.origin.x - rect.size.width;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            rect = CGRectMake(keyWindow.frame.size.height - rect.origin.y - rect.size.height,
                              rect.origin.x,
                              rect.size.height,
                              rect.size.width);
            break;
        case UIInterfaceOrientationLandscapeRight:
            rect = CGRectMake(rect.origin.y,
                              keyWindow.frame.size.width - rect.origin.x - rect.size.width,
                              rect.size.height,
                              rect.size.width);
            break;
        default: break;
    }
    
    return rect;
}

- (CGRect)convertRectToWindowForCurrentOrientation:(CGRect)rect {
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    UIInterfaceOrientation orientation = MPInterfaceOrientation();
    
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            rect.origin.y = keyWindow.frame.size.height - rect.origin.y - rect.size.height;
            rect.origin.x = keyWindow.frame.size.width - rect.origin.x - rect.size.width;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            rect = CGRectMake(rect.origin.y,
                              keyWindow.frame.size.height - rect.origin.x - rect.size.width,
                              rect.size.height,
                              rect.size.width);
            break;
        case UIInterfaceOrientationLandscapeRight:
            rect = CGRectMake(keyWindow.frame.size.width - rect.origin.y - rect.size.height,
                              rect.origin.x,
                              rect.size.height,
                              rect.size.width);
            break;
        default: break;
    }
    
    return rect;
}

- (void)logImpression {
    if (![self.impURL length])
        return;
    NSURLRequest *bannerRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.impURL]];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:bannerRequest queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if ( [httpResponse statusCode] == 200) {
            ECLog(@"Impression Logged");
            self.impURL = nil;
        }
    }];

    
}
#pragma mark - Webview Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = [request URL];
    NSMutableString *urlString = [NSMutableString stringWithString:[url absoluteString]];

    NSString *scheme = request.URL.scheme;
    //ECLog(@"Web Commands %@",urlString);
    if ([scheme isEqualToString:@"tel"] || [scheme isEqualToString:@"mailto"]) {
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
            return NO;
        }
        return YES;
    }
    if (!isLoading && navigationType == UIWebViewNavigationTypeOther && (![scheme isEqualToString:kECURLScheme] && ![scheme isEqualToString:kMraidURLScheme])) {
        BOOL iframe = ![request.URL isEqual:request.mainDocumentURL];
        if (iframe) return YES;
        NSMutableString *urlString = [NSMutableString stringWithString:[url absoluteString]];
        
        self.clickURL =urlString;
        if ([self.delegate respondsToSelector:@selector(bannerAd:didClickLink:)])
            [self.delegate performSelector:@selector(bannerAd:didClickLink:) withObject:self withObject:self.clickURL];
        return NO;
    }
    
    if (!isLoading && navigationType == UIWebViewNavigationTypeLinkClicked && (![scheme isEqualToString:kECURLScheme] && ![scheme isEqualToString:kMraidURLScheme])) {
        [[UIApplication sharedApplication] openURL:url];
        return NO;
    }
    
    if ([scheme isEqualToString:kMraidURLScheme]) {// For MRAID events
        BOOL success = [self tryProcessingURLStringAsCommand:urlString];
        if (success) return NO;
    }
    // To Process NON MRAID Querry String
    scheme = [NSString stringWithFormat:@"%@://", kECURLScheme];
    NSString *schemelessUrlString = [urlString substringFromIndex:scheme.length];
    
    NSRange r = [schemelessUrlString rangeOfString:@"?"];
    NSString *commandType;
    NSString *parameterString;
    NSDictionary *parameters;
    if (r.location != NSNotFound) {
        commandType = [[schemelessUrlString substringToIndex:r.location] lowercaseString];
        parameterString = [schemelessUrlString substringFromIndex:(r.location + 1)];
        parameters = MPDictionaryFromQueryString(parameterString);

    }
    

    if ([request.URL.scheme isEqualToString:kECURLScheme]) {// For EC Events
        if ([commandType isEqualToString:kECADPassURL]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@",parameterString]]];
            return NO;
        }
        
        if ([schemelessUrlString isEqualToString:@"close"] || [commandType isEqualToString:@"close"]) {
            if (r.location != NSNotFound) {
                if ([parameters objectForKey:kECBannerAdState]) {
                    [self.sdkParams setObject:[parameters objectForKey:kECBannerAdState] forKey:kECBannerAdState];
                    [self closeBannerAd:kECBannerAdDynamic];
                }
                else
                    [self closeBannerAd:kECBannerAdUserClose];
            }
            else
                [self closeBannerAd:kECBannerAdUserClose];
            
        }
        else if ([commandType isEqualToString:kECBannerAdActionAdLoaded])
        {
            // Show Close button here and start a timer so the user can click it.
//            [self showCloseButton];
            [self addECADParamsFrom:parameters ToParmas:self.sdkParams];
            [self logImpression];
            if (self.refreshRate > 0.0) {
                [self performSelector:@selector(refreshAd) withObject:nil afterDelay:self.refreshRate];
            }
            return NO;
        }else if ([commandType isEqualToString:kECBannerAdActionAdFailed]) {
            [self addECADParamsFrom:parameters ToParmas:self.sdkParams];
            [self finishAdWithResult:kECBannerAdTimeout];
            [self.delegate bannerAd:self didFailWithError:nil];
            return NO;
        }
        
        else if ([commandType isEqualToString:kECBannerAdActionAdVibrate])
        {
            [self vibrateDevice];
            return NO;
        }

        
        if (r.location == NSNotFound) {
            if ([schemelessUrlString isEqualToString:kECBannerAdCallback]) {
                //Code for Callback
                [self callBack];
            }
            if ([schemelessUrlString isEqualToString:kECBannerAdExpand]) {
                _currentState = MRAdViewStateExpanded;
                if ([self.delegate respondsToSelector:@selector(bannerAd:willExpand:)])
                    [self.delegate performSelector:@selector(bannerAd:willExpand:) withObject:self withObject:self.clickURL];
                
                /*
//                self.alpha = 0.0;
                [self removeFromSuperview];
                UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
                [keyWindow addSubview:self];
                
                [UIView animateWithDuration:0.8 animations:^{
//                    self.alpha = 1.0;
                    self.frame = [UIScreen mainScreen].bounds;
                    self.webView.frame = self.bounds;
                    [[UIApplication sharedApplication] setStatusBarHidden:NO];
                    
                }];*/
                [self processExpandCommand:nil];

            }
            if ([schemelessUrlString isEqualToString:kECBannerAdActionClose]) {
                _currentState = MRAdViewStateDefault;
                [self closeNonMRAIDBannerAd];
            }
            return NO;
        }
        
        
        if ([commandType isEqualToString:kECBannerAdOpen] && [parameterString length]) {
            self.clickURL =parameterString;
            if ([self.delegate respondsToSelector:@selector(bannerAd:didClickLink:)]) {
                if (_currentState == MRAdViewStateExpanded) {
                    [[UIApplication sharedApplication].keyWindow sendSubviewToBack:self];
                    [self closeBannerAd:kECBannerAdUserInteractionComplete];
                }
                [self.delegate performSelector:@selector(bannerAd:didClickLink:) withObject:self withObject:self.clickURL];
            }
            return NO;
        }
        else if ([commandType isEqualToString:kECBannerAdExpand]) {
            //NSString *commandType = [[schemelessUrlString substringToIndex:r.location] lowercaseString];
            self.closeBtn.hidden = YES;
            _currentState = MRAdViewStateExpanded;
            if ([self.delegate respondsToSelector:@selector(bannerAd:willExpand:)])
                [self.delegate performSelector:@selector(bannerAd:willExpand:) withObject:self withObject:self.clickURL];
            [self processExpandCommand:parameters];
        }
        else if ([commandType isEqualToString:kECExpandableUseCustomClose] || [parameters objectForKey:@"shouldUseCustomClose"]) {
            BOOL show = ([[[parameters objectForKey:@"shouldUseCustomClose"] lowercaseString] isEqualToString:@"true"]  || [[[parameters objectForKey:@"shouldUseCustomClose"] lowercaseString] isEqualToString:@"yes"]  )? YES:NO;
            [self setUseCustomClose:!show];
        }
        else if ([commandType isEqualToString:kECBannerAdCallus] && [parameterString length]) {
            // Code for Call Now
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",parameterString]]];
            return NO;
        }
        else if ([commandType isEqualToString:kECBannerAdresize] && [parameterString length]) {
            [self resizeAd:parameterString];
            return NO;
        }
        else if ([commandType isEqualToString:kECBannerAdLocate] && [parameterString length]) {
            // Code for Find Dealer
            [self searchForLocation:parameterString];
            return NO;
        }
        else if ([commandType isEqualToString:kECBannerAdOpenAppStore] && [parameterString length]) {
            // Code for Call Now
            NSDictionary *parameters = MPDictionaryFromQueryString(parameterString);
            NSString *appstoreId = [parameters objectForKey:@"id"];
            NSString *appstoreURL = [parameters objectForKey:@"url"];
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0 ) {
                BOOL success = [self openInAppStore:appstoreId];
                if (!success) 
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appstoreURL]];
            }
            else if ([appstoreURL length])
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appstoreURL]];
            return NO;
        }
    }
    

    return YES;
}


- (void)resizeAd:(NSString *)frameStr {
    NSArray *coordinates = [frameStr componentsSeparatedByString:@","];
    float x,y,w,h;
    if ([coordinates count] == 4) {
        x = [[coordinates objectAtIndex:0] floatValue];
        y = [[coordinates objectAtIndex:1] floatValue];
        w = [[coordinates objectAtIndex:2] floatValue];
        h = [[coordinates objectAtIndex:3] floatValue];
    } else {
        return;
    }
    self.frame = CGRectMake(x, y, w, h);
    self.webView.frame = self.bounds;
}

- (void)closeNonMRAIDBannerAd {
    [self closeBannerAd:kECBannerAdUserClose];
    return;
    if ([self.delegate respondsToSelector:@selector(bannerDidRestore:)])
        [self.delegate performSelector:@selector(bannerDidRestore:) withObject:self];
    self.alpha = 0.0;
    [self removeFromSuperview];
    [self.parentView addSubview:self];
    self.frame = homeRect_;
    self.webView.frame = self.bounds;
    
    [UIView animateWithDuration:0.8 animations:^{
        self.alpha = 1.0;
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        
    }];
    
    

}

- (void)setUseCustomClose:(BOOL)show {
    [self.closeBtn setHidden:!show];
}

- (void)animateSpinner {
    if (nil == self.spinner) {
        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.spinner setCenter:self.center];
        [self addSubview:self.spinner];
        [self.spinner setHidesWhenStopped:YES];
        [self bringSubviewToFront:self.spinner];
    }
    [self.spinner startAnimating];
}

- (BOOL)openInAppStore:(NSString *)appID {
    [self animateSpinner];
    if (![appID length])
        return NO;
    SKStoreProductViewController *storeProductViewController = [[SKStoreProductViewController alloc] init];
    // Configure View Controller
    [storeProductViewController setDelegate:self];
    __block BOOL success;
    [storeProductViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier : appID} completionBlock:^(BOOL result, NSError *error) {
        if (error) {
            ECLog(@"Error %@ with User Info %@.", error, [error userInfo]);
            success = NO;
        } else {
            // Present Store Product View Controller
            UIViewController *rootViewController = [[ECAdManager sharedManager] topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
            if (rootViewController) {
                [rootViewController presentViewController:storeProductViewController animated:YES completion:^{
                    [self.spinner stopAnimating];
                    self.spinner = nil;
                    success =  YES;
                }];
            }
            else
                success = NO;
            
        }
    }];
    return success;
}
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)closeBannerAd:(kECBannerAdResult)result {
    [self setUseCustomClose:NO];
    if (_currentState == MRAdViewStateExpanded)
        _currentState = MRAdViewStateDefault;
    else
        _currentState = MRAdViewStateHidden;
    
    [[ECMRAIDHelper sharedHelper] fireChangeEventForProperty:[MRStateProperty propertyWithState:_currentState]];
   // self.transform = CGAffineTransformIdentity;
    if ([self.delegate respondsToSelector:@selector(bannerDidRestore:)])
        [self.delegate performSelector:@selector(bannerDidRestore:) withObject:self];
    self.alpha = 0.0;
    UIWindow *keyWindow = MPKeyWindow();
    UIView *parentView = [keyWindow viewWithTag:_parentTag];
    CGRect rect  = [parentView convertRect:homeRect_ toView:keyWindow];

//    [self removeFromSuperview];
   // [self.parentView addSubview:self];
  //  self.frame = rect;//homeRect_;
   // self.webView.frame = self.bounds;
    self.frame = rect;//homeRect_;

    
    [UIView animateWithDuration:0.8 animations:^{
        self.alpha = 1.0;

       // [[UIApplication sharedApplication] setStatusBarHidden:NO];
        
    } completion:^(BOOL finished) {
        [self moveViewFromWindowToDefaultSuperview];
        self.frame = homeRect_;
        [self finishAdWithResult:result];
    }];
}

- (BOOL)tryProcessingURLStringAsCommand:(NSString *)urlString {
    NSString *scheme = [NSString stringWithFormat:@"%@://", kMraidURLScheme];
    NSString *schemelessUrlString = [urlString substringFromIndex:scheme.length];
    
    NSRange r = [schemelessUrlString rangeOfString:@"?"];
    
    NSString *commandType;
    NSString *parameterString;
    NSDictionary *parameters;
    
    if (r.location != NSNotFound) {
        commandType = [[schemelessUrlString substringToIndex:r.location] lowercaseString];
        parameterString = [schemelessUrlString substringFromIndex:(r.location + 1)];
        parameters = MPDictionaryFromQueryString(parameterString);
        
    }
    
    if ([schemelessUrlString isEqualToString:@"close"] || [commandType isEqualToString:@"close"]) {
        if (r.location != NSNotFound) {
            if ([parameters objectForKey:kECBannerAdState]) {
                [self.sdkParams setObject:[parameters objectForKey:kECBannerAdState] forKey:kECBannerAdState];
                [self closeBannerAd:kECBannerAdDynamic];
            }
            else
                [self closeBannerAd:kECBannerAdUserClose];
        }
        else
            [self closeBannerAd:kECBannerAdUserClose];

    }
   // NSRange r = [schemelessUrlString rangeOfString:@"?"];
    
    if (r.location == NSNotFound) {
        return [self tryProcessingCommand:schemelessUrlString parameters:nil];
    }
    
//    NSString *commandType = [[schemelessUrlString substringToIndex:r.location] lowercaseString];
//    NSString *parameterString = [schemelessUrlString substringFromIndex:(r.location + 1)];
//    NSDictionary *parameters = MPDictionaryFromQueryString(parameterString);
    if ([commandType isEqualToString:@"open"] && [parameters objectForKey:@"url"]) {
        self.clickURL = [parameters objectForKey:@"url"];
        if ([self.delegate respondsToSelector:@selector(bannerAd:didClickLink:)]) {
            if (_currentState == MRAdViewStateExpanded) {
                [[UIApplication sharedApplication].keyWindow sendSubviewToBack:self];
                [self closeBannerAd:kECBannerAdUserInteractionComplete];
            }
            [self.delegate performSelector:@selector(bannerAd:didClickLink:) withObject:self withObject:self.clickURL];
        }

    }
    if ([commandType isEqualToString:kECExpandableUseCustomClose] || [parameters objectForKey:@"shouldUseCustomClose"]) {
        BOOL show = ([[[parameters objectForKey:@"shouldUseCustomClose"] lowercaseString] isEqualToString:@"true"]  || [[[parameters objectForKey:@"shouldUseCustomClose"] lowercaseString] isEqualToString:@"yes"]  )? YES:NO;
        [self setUseCustomClose:!show];
    }
    if ([commandType isEqualToString:@"expand"]) {
        _currentState = MRAdViewStateExpanded;
        [[ECMRAIDHelper sharedHelper] fireChangeEventForProperty:[MRStateProperty propertyWithState:_currentState]];
        [self processExpandCommand:parameters];
    }

    return [self tryProcessingCommand:commandType parameters:parameters];
    
}

- (void)processExpandCommand:(NSDictionary *)parameters {
    CGRect applicationFrame = MPApplicationFrame();
    CGFloat afWidth = CGRectGetWidth(applicationFrame);
    CGFloat afHeight = CGRectGetHeight(applicationFrame);
    
    // If the ad has expandProperties, we should use the width and height values specified there.
	CGFloat w = [self floatFromParametersForKey:@"w" withDefault:afWidth param:parameters];
	CGFloat h = [self floatFromParametersForKey:@"h" withDefault:afHeight param:parameters];
    
    // Constrain the ad to the application frame size.
    if (w>0 && h >0) {
        if (w > afWidth) w = afWidth;
        if (h > afHeight) h = afHeight;
    } else {
        w = afHeight;
        h  = afHeight;
    }
    
    
    
    // Center the ad within the application frame.
    CGFloat x = applicationFrame.origin.x + floor((afWidth - w) / 2);
    CGFloat y = applicationFrame.origin.y + floor((afHeight - h) / 2);
	
	NSString *urlString = [self stringFromParametersForKey:@"url" param:parameters];
	NSURL *url = [NSURL URLWithString:urlString];
    
	ECLog(@"Expanding to (%.1f, %.1f, %.1f, %.1f); displaying %@.", x, y, w, h, url);
	CGRect newFrame = CGRectMake(x, y, w, h);
    
    expandFrame_ = newFrame;
    CGRect expandedFrameInWindow = [self convertRectToWindowForCurrentOrientation:expandFrame_];

    if ([self.delegate respondsToSelector:@selector(bannerAd:willExpand:)])
        [self.delegate performSelector:@selector(bannerAd:willExpand:) withObject:self withObject:self.clickURL];
    //        self.alpha = 0.0;
//    [self removeFromSuperview];
//    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
//    [keyWindow addSubview:self];
    [self moveViewFromDefaultSuperviewToWindow];

    [UIView animateWithDuration:0.8 animations:^{
        //            self.alpha = 1.0;
        self.frame =expandedFrameInWindow;// [UIScreen mainScreen].bounds;
        self.webView.frame = self.bounds;
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }];
}


- (void)assignRandomTagToDefaultSuperview {
    _originalTag = self.superview.tag;
    do {
        _parentTag = arc4random() % 25000;
    } while ([MPKeyWindow() viewWithTag:_parentTag]);
    
    self.superview.tag = _parentTag;
}

- (void)restoreDefaultSuperviewTag {
    [[MPKeyWindow() viewWithTag:_parentTag] setTag:_originalTag];
}

- (void)moveViewFromDefaultSuperviewToWindow {
    [self applyRotationTransformForCurrentOrientationOnView:self];
    [self assignRandomTagToDefaultSuperview];

    // Add the ad view as a subview of the window. This requires converting the ad view's frame from
    // its superview's coordinate system to that of the window.
    UIWindow *keyWindow = MPKeyWindow();
    _defaultFrameInKeyWindow = [self.superview convertRect:homeRect_ toView:keyWindow];
    self.frame = _defaultFrameInKeyWindow;
    self.webView.frame = self.bounds;
    
    [keyWindow addSubview:self];
}

- (void)moveViewFromWindowToDefaultSuperview {
    UIView *defaultSuperview = [MPKeyWindow() viewWithTag:_parentTag];
    [defaultSuperview addSubview:self];
    
    [self restoreDefaultSuperviewTag];
    self.transform = CGAffineTransformIdentity;
}

- (void)applyRotationTransformForCurrentOrientationOnView:(UIView *)view {
    // We need to rotate the ad view in the direction opposite that of the device's rotation.
    // For example, if the device is in LandscapeLeft (90 deg. clockwise), we have to rotate
    // the view -90 deg. counterclockwise.
    
    CGFloat angle = 0.0;
    
    switch (MPInterfaceOrientation()) {
        case UIInterfaceOrientationPortraitUpsideDown: angle = M_PI; break;
        case UIInterfaceOrientationLandscapeLeft: angle = -M_PI_2; break;
        case UIInterfaceOrientationLandscapeRight: angle = M_PI_2; break;
        default: break;
    }
    
    view.transform = CGAffineTransformMakeRotation(angle);
}


- (CGFloat)floatFromParametersForKey:(NSString *)key withDefault:(CGFloat)defaultValue param:(NSDictionary *)parameters {
    NSString *stringValue = [parameters valueForKey:key];
    return stringValue ? [stringValue floatValue] : defaultValue;
}

- (BOOL)boolFromParametersForKey:(NSString *)key param:(NSDictionary *)parameters {
    NSString *stringValue = [parameters valueForKey:key];
    return [stringValue isEqualToString:@"true"];
}

- (NSString *)stringFromParametersForKey:(NSString *)key param:(NSDictionary *)parameters {
    
    NSString *value = [parameters objectForKey:key];
    if (!value || [value isEqual:[NSNull null]]) return nil;
    
    value = [value stringByTrimmingCharactersInSet:
             [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!value || [value isEqual:[NSNull null]] || value.length == 0) return nil;
    
    return value;
}


- (BOOL)tryProcessingCommand:(NSString *)command parameters:(NSDictionary *)parameters {
    [[ECMRAIDHelper sharedHelper] fireNativeCommandCompleteEvent:command];
    return YES;
}

- (void)createCloseButton {
    if (self.closeBtn)
        return;
    NSBundle *resourceBundle =  [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"ECAdLibResources" withExtension:@"bundle"]];
    NSString *path =    [resourceBundle pathForResource:@"black_Close" ofType:@"png"];

    self.closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeBtn setImage:[UIImage imageWithContentsOfFile:path] forState:UIControlStateNormal];
    [self.closeBtn addTarget:self action:@selector(closeAd) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.closeBtn];
    self.closeBtn.frame = CGRectMake(5, 5, 40, 40);
    [self bringSubviewToFront:self.closeBtn];
    [self.closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin];
    [self.closeBtn setHidden:YES];
}

- (void)closeAd {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.spinner stopAnimating];
    self.spinner = nil;
    if (self.mapView) {
        [UIView animateWithDuration:0.5 animations:^{
            self.mapView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self.closeBtn setHidden:YES];
            self.mapView.delegate = nil;
            [self.mapView removeFromSuperview];
            self.mapView = nil;
        }];
    }else {
        [self closeBannerAd:kECBannerAdUserClose];
    }
//    else if ([self.delegate respondsToSelector:@selector(bannerAdDidClose:)])
//        [self.delegate performSelector:@selector(bannerAdDidClose:) withObject:self];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    if (isLoading && [self.delegate respondsToSelector:@selector(bannerAdDidLoad:)]) {
        isLoading = NO;
        _currentState = MRAdViewStateDefault;
        [self createCloseButton];
//        [self initializeJavascriptState];
        [[ECMRAIDHelper sharedHelper] setWebView:_webView];
        [[ECMRAIDHelper sharedHelper] initializeJavascriptState:_placementType state:_currentState];
        [self.delegate performSelector:@selector(bannerAdDidLoad:) withObject:self];
    }
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    isLoading = NO;
    if ([self.delegate respondsToSelector:@selector(bannerAd:didFailWithError:)])
        [self.delegate performSelector:@selector(bannerAd:didFailWithError:) withObject:self withObject:error];
    [self createCloseButton];
    

}

#pragma mark - Location Manager Methods

- (void)searchForLocation:(NSString *)keyword {
    [self animateSpinner];
    if (nil == self.mapView) {
        self.mapView = [[MKMapView alloc] initWithFrame:self.webView.bounds];
        [self addSubview:self.mapView];
        self.mapView.autoresizingMask = self.autoresizingMask;
        [self bringSubviewToFront:self.closeBtn];
        self.mapView.alpha = 0.0;
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        self.mapView.alpha = 1.0;
    } completion:^(BOOL finished) {
        [self.closeBtn setHidden:NO];
        self.keyword = keyword;
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        // Larger target area should save battery power.
         self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;//kCLLocationAccuracyThreeKilometers;
        // Set a movement threshold for new events
        // This is in meters
         self.locationManager.distanceFilter = kCLDistanceFilterNone;
        [ self.locationManager startUpdatingLocation];

    }];
}


- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    //ECLog(@"Location: %@", [newLocation description]);
    [manager stopUpdatingLocation];
    if (newLocation == nil)
        return;
    [self fetchNearbyStores:newLocation];
    self.locationManager.delegate = nil;
    self.locationManager = nil;
}

//- (void)locationManager:(CLLocationManager *)manager
//     didUpdateLocations:(NSArray *)locations {
//    [manager stopUpdatingLocation];
//    if (![locations lastObject])
//        return;
//    [self fetchNearbyStores:[locations lastObject]];
//}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
	//ECLog(@"Error: %@", [error description]);
}


- (void)fetchNearbyStores:(CLLocation *)currentLocation {
    int  currenDist = 1000000;
    
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    
    span.latitudeDelta=1;//0.01;
    span.longitudeDelta=1;//0.01;
    
    CLLocationCoordinate2D location=currentLocation.coordinate;
    
    region.span=span;
    region.center=location;
    
    [self.mapView setRegion:region animated:YES];
    
    NSString *url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/search/json?keyword=%@&location=%f,%f&radius=%@&sensor=false&key=%@",self.keyword,location.latitude,location.longitude,[NSString stringWithFormat:@"%i", currenDist], kGOOGLE_API_KEY];
    //Formulate the string as URL object.
    NSURL *googleRequestURL=[NSURL URLWithString:url];

    // Retrieve the results of the URL.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSData dataWithContentsOfURL: googleRequestURL];
        [self performSelectorOnMainThread:@selector(fetchedStoreData:) withObject:data waitUntilDone:YES];
    });
    
}

- (void)fetchedStoreData:(NSData *)responseData {
    //parse out the json data
    if (![responseData length]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"No Nearby Location Found" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    NSError* error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:responseData
                          
                          options:kNilOptions
                          error:&error];
    
    //The results from Google will be an array obtained from the NSDictionary object with the key "results".
    NSArray* places = [json objectForKey:@"results"];
    
    //Write out the data to the console.
    //ECLog(@"Google Data: %@", places);
    
    //Plot the data in the places array onto the map with the plotPostions method.
    //    [self plotPositions:places];
    if ([places count])
        [self plotPositions:places];
    
    
}


- (void)plotPositions:(NSArray *)data
{
    //Remove any existing custom annotations but not the user location blue dot.
    for (id<MKAnnotation> annotation in self.mapView.annotations)
    {
        if ([annotation isKindOfClass:[ECAdMapPoint class]])
        {
            [self.mapView removeAnnotation:annotation];
        }
    }
    
    
    //Loop through the array of places returned from the Google API.
    for (int i=0; i<[data count]; i++)
    {
        
        //Retrieve the NSDictionary object in each index of the array.
        NSDictionary* place = [data objectAtIndex:i];
        
        //There is a specific NSDictionary object that gives us location info.
        NSDictionary *geo = [place objectForKey:@"geometry"];
        
        
        //Get our name and address info for adding to a pin.
        NSString *name=[place objectForKey:@"name"];
        NSString *vicinity=[place objectForKey:@"vicinity"];
        
        //Get the lat and long for the location.
        NSDictionary *loc = [geo objectForKey:@"location"];
        
        //Create a special variable to hold this coordinate info.
        CLLocationCoordinate2D placeCoord;
        
        //Set the lat and long.
        placeCoord.latitude=[[loc objectForKey:@"lat"] doubleValue];
        placeCoord.longitude=[[loc objectForKey:@"lng"] doubleValue];
        
        //Create a new annotiation.
        ECAdMapPoint *placeObject = [[ECAdMapPoint alloc] initWithName:name address:vicinity coordinate:placeCoord];
        
        
        [self.mapView addAnnotation:placeObject];
    }
    
    
    @try {
        double upperLatitude = [[[[[data objectAtIndex:0] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"] doubleValue];
        double lowerLatitude =[[[[[data lastObject] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"] doubleValue];
        
        double upperLongitude = [[[[[data objectAtIndex:0] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"] doubleValue];
        double lowerLongitude =[[[[[data lastObject] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"] doubleValue];
        
        MKCoordinateSpan locationSpan;
        locationSpan.latitudeDelta = upperLatitude - lowerLatitude;
        locationSpan.longitudeDelta = upperLongitude - lowerLongitude;
        CLLocationCoordinate2D locationCenter;
        locationCenter.latitude = (upperLatitude + lowerLatitude) / 2;
        locationCenter.longitude = (upperLongitude + lowerLongitude) / 2;
        
        
        //MKCoordinateRegion region = MKCoordinateRegionMake(locationCenter, locationSpan);
        //     [self.mapView setRegion:region animated:YES];
        //            [self.mapView setCenter:self.mapView.userLocation.coordinate animated:YES];
    }
    @catch (NSException *exception) {
    }
}

#pragma mark - Call Back Methods

- (void)callBack {
    UIAlertView *inputAlertView = [[UIAlertView alloc] initWithTitle:@"Callback" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    [inputAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    UITextField *documentNameTextField = [inputAlertView textFieldAtIndex:0];
    documentNameTextField.keyboardAppearance = UIKeyboardAppearanceDefault;
    [documentNameTextField setKeyboardType:UIKeyboardTypeNumberPad];
    [documentNameTextField setPlaceholder:@"Phone Number"];
    [inputAlertView show];
}



#pragma mark -
#pragma mark - Alert view delegates

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
	UITextField *doucmentNameTextField = [alertView textFieldAtIndex:0];
    NSString *str = [doucmentNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if([str length]) {
		return YES;
	}
	return NO;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [[ECMRAIDHelper sharedHelper] setWebView:nil];
    self.parentView = nil;
    self.webView.delegate = self;
    self.webView = nil;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
