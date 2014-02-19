//
//  ECModalAdViewController.m
//  ECAdLib
//
//  Created by bsp on 4/13/13.
//  Copyright (c) 2013 EngageClick. All rights reserved.
//

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <AudioToolbox/AudioServices.h>
#import "ECModalAdViewController.h"
#import "ECAdConstants.h"
#import "ECBannerAdView.h"
#import "ECAdManager.h"
#import "MRProperty.h"
#import "MPGlobal.h"
#import "ECMRAIDHelper.h"
#import <StoreKit/StoreKit.h>
#import "Flurry.h"

NSInteger const kECShowCloseButtonDelay = 1;

#pragma mark - Ad Parameters to be passed to Ad Server

// parameters to be supplied by app developer
NSString * const kECModalAdAppPublisherKey = @"pubkey";
NSString * const kECModalAdAppIDKey = @"appid";
NSString * const kECModalAdZoneIDKey = @"zid";
NSString * const kECModalAdReferrerKey = @"referrer";
NSString * const kECModalAdKeywordKey = @"keyword";
NSString * const kECModalAdCategoryKey = @"category";

// parameters that the app can figure out for itself
NSString * const kECModalAdTypeKey = @"adtype";
NSString * const kECModalAdViewportWidth = @"w";
NSString * const kECModalAdViewportHeight = @"h";
NSString * const kECModalAdRequestTime = @"reqtimestamp";
NSString * const kECModalAdMedium = @"medium";
NSString * const kECModalAdCarrier = @"carrier";
NSString * const kECModalAdMCC = @"mcc";
NSString * const kECModalAdMNC = @"mnc";
NSString * const kECModalAdHURL = @"hurl";

// navigate actions sent by ad from webview
static NSString * const kMraidURLScheme = @"mraid";
NSString * const kECAdScheme = @"ecad";
NSString * const kECAdActionClose = @"close";
NSString * const kECAdExpandableUseCustomClose = @"usecustomclose";

NSString * const kECAdActionAdLoaded = @"adloaded";
NSString * const kECAdActionAdFailed = @"adfailed";

NSString * const kECShouldEnableLog = @"shouldenablelog";
NSString * const kECIsBackgroundTransparent = @"isbackgroundtransparent";

NSString * const kECAdActionAdVibrate = @"vibrate";
NSString * const kECAdActionInteractionSuccess = @"INTERACTION_SUCCESS";
NSString * const kECAdActionInteractionTimeout = @"TIMEDOUT";
NSString * const kECAdID = @"adid";
NSString * const kECAdOpenAppStore = @"openappstore";
NSString * const kECAdOpen = @"open";

NSString * const kECRequestID = @"requestid";
NSString * const kECADTime = @"time";
NSString * const kECADState = @"state";
NSString * const kECADPass = @"pass";

NSString * const kADCloseParamArray = @"closeParamArray";



NSString * const kECInterstitialRequestURL = @"http://demo.engageclick.com/ecadserve/ecadserve?cltype=ecsdk&rformat=html&";//@"http://demo.engageclick.com/client/js/interaction/minterstitial/ecinterstitials.m.webview.1.0.js?";


@interface ECModalAdViewController () <UIWebViewDelegate,SKStoreProductViewControllerDelegate> {
    BOOL isLoading;
    MRAdViewPlacementType _placementType;
    MRAdViewState _currentState;
    BOOL isPresentingController;
    BOOL isMRAID;
    
    NSArray *portraitOrientation;
    NSArray *landscapeOrientation;

}

@property (nonatomic, strong) NSMutableArray *adCloseParamArray; // inside Array there is Dictionary
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSArray *portraitOrientation;
@property (nonatomic, strong) NSArray *landscapeOrientation;



// private methods
- (void)loadAd;
- (NSData *)loadFile:(NSString *)name fromBundle:(NSBundle *)bundle;
- (void)initSDKParams:(NSMutableDictionary *)dict;
- (void)finishAdWithResult:(kECModalAdResult)result;
- (void)addECADParamsFrom:(NSDictionary *)inADParameters ToParmas:(NSMutableDictionary*)dictionary;
- (void)showCloseButton;
- (void)vibrateDevice;
- (NSDictionary *)responseToSendToECForResult:(kECModalAdResult)result;
@end

@implementation ECModalAdViewController

- (id)initWithAdParams:(NSDictionary *)appAdParams
{
    self = [super init];
    if (self)
    {
        self.adParams = appAdParams;
        
        if ([self.adParams objectForKey:kECAdWidth] && [self.adParams objectForKey:kECAdHeight]) {
            if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
                self.landscapeOrientation = [NSArray arrayWithObjects:[self.adParams objectForKey:kECAdWidth],[self.adParams objectForKey:kECAdHeight], nil];
                self.portraitOrientation = [NSArray arrayWithObjects:[self.adParams objectForKey:kECAdHeight],[self.adParams objectForKey:kECAdWidth], nil];
            }else {
                self.portraitOrientation = [NSArray arrayWithObjects:[self.adParams objectForKey:kECAdWidth],[self.adParams objectForKey:kECAdHeight], nil];
                self.landscapeOrientation = [NSArray arrayWithObjects:[self.adParams objectForKey:kECAdHeight],[self.adParams objectForKey:kECAdWidth], nil];

            }
        }

        self.libBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"ECAdLibResources" withExtension:@"bundle"]];
        self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:self.webView];
        [self.webView.scrollView setScrollEnabled:NO];
        [self.view bringSubviewToFront:self.closeButton];
        [self.webView setAllowsInlineMediaPlayback:YES];
        [self.webView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        
        self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.closeButton.frame = CGRectMake(self.webView.frame.size.width - 35, 5, 35, 35);
        NSString *path =    [self.libBundle pathForResource:@"black_Close" ofType:@"png"];
        [self.closeButton addTarget:self action:@selector(closeClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.closeButton setImage:[UIImage imageWithContentsOfFile:path] forState:UIControlStateNormal];
        [self.view addSubview:self.closeButton];
        [self.closeButton setHidden:YES];
        [self.closeButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    }
    return self;
}

#pragma mark - Public
- (id)initWithNibName1:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    // Get the bundle where we have stored the resources
    
    // Initialize the view controller with the nib in the bundle
    if ((self = [super initWithNibName:@"ECModalAdViewController" bundle:self.libBundle]))
    {
        // Custom intialization
    }
    
    // Bring the Close button to the front
    [self.webView.scrollView setScrollEnabled:NO];
    [self.view bringSubviewToFront:self.closeButton];
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!isPresentingController) {
        // Start a timer that will tell us to show the [X] close button so that the user can close the Ad after 5 secs
        [NSTimer scheduledTimerWithTimeInterval:kECShowCloseButtonDelay target:self selector:@selector(showCloseButton) userInfo:nil repeats:NO];
        // Load the Ad
        [self loadAd];
    }else {
        isPresentingController = NO;
    }
    
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - MRAID Java Script Utility
- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation {
    [[ECMRAIDHelper sharedHelper] rotateToOrientation:newOrientation];
    //    [self fireChangeEventForProperty:
    //     [MRScreenSizeProperty propertyWithSize:MPApplicationFrame().size]];
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
        _currentState = MRAdViewStateHidden;
        [[ECMRAIDHelper sharedHelper] fireChangeEventForProperty:[MRStateProperty propertyWithState:_currentState]];
        if (r.location != NSNotFound) {
            if ([parameters objectForKey:kECADState]) {
                [self.sdkParams setObject:[parameters objectForKey:kECADState] forKey:kECADState];
                [self finishAdWithResult:kECModalAdDynamic];
            }
            else
                [self finishAdWithResult:kECModalAdUserClose];
            
        }
        else
            [self finishAdWithResult:kECModalAdUserClose];
        return YES;
    }
    
    if (r.location == NSNotFound) {
        return [self tryProcessingCommand:schemelessUrlString parameters:nil];
    }
    
    
    if ([commandType isEqualToString:@"open"] && [parameters objectForKey:@"url"]) {
        if ([self.delegate respondsToSelector:@selector(loadInterstitialWebView:)]) {
            isPresentingController = YES;
            [(ECAdManager *)self.delegate loadInterstitialWebView:[parameters objectForKey:@"url"]];
        }
        else {
            [[ECAdManager sharedManager] videoAdLandingPageOpened:[parameters objectForKey:@"url"]];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[parameters objectForKey:@"url"]]];
        }
        [Flurry logEvent:ModalAdDidClickLink];
        
    }
    if ([commandType isEqualToString:kECAdExpandableUseCustomClose] || [parameters objectForKey:@"shouldUseCustomClose"]) {
        BOOL show = ([[[parameters objectForKey:@"shouldUseCustomClose"] lowercaseString] isEqualToString:@"true"]  || [[[parameters objectForKey:@"shouldUseCustomClose"] lowercaseString] isEqualToString:@"yes"]  )? YES:NO;
        [self.closeButton setHidden:show];
    }
    return [self tryProcessingCommand:commandType parameters:parameters];
    
}



- (BOOL)tryProcessingCommand:(NSString *)command parameters:(NSDictionary *)parameters {
    [[ECMRAIDHelper sharedHelper] fireNativeCommandCompleteEvent:command];
    return YES;
}

- (void)refreshAd:(NSArray *)adSize {
    if ([adSize lastObject]) {
        self.responseDict = nil;
//        if ([self.adParams objectForKey:kECAdWidth] && [self.adParams objectForKey:kECAdHeight]) {
        [self.adParams setValue:[adSize objectAtIndex:0] forKey:kECAdWidth];
        [self.adParams setValue:[adSize objectAtIndex:1] forKey:kECAdHeight];
        
        NSURL *bannerURL = [self getBannerURL];//[NSURL URLWithString:[self.adParams objectForKey:kECBannerADURL]];
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
                NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSDictionary* headers = [httpResponse allHeaderFields];

                if ([[headers objectForKey:@"X-ERROR"] intValue] == 1 || [httpResponse statusCode] != 200 || error || [responseString rangeOfString:@"html"].location == NSNotFound || [responseString rangeOfString:@"HTML"].location == NSNotFound)
                {
                    // handle error condition
                    [self.adParams setValue:[adSize objectAtIndex:1] forKey:kECAdWidth];
                    [self.adParams setValue:[adSize objectAtIndex:0] forKey:kECAdHeight];

                }else {
                    [self setResponseDict:responseDict];
                    [self loadAd];
                }
            
        });
        }];
        
    }
    else {
        [self initSDKParams:nil];
        [self loadAd];
    }
}

#pragma mark - UIWebView delegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    NSString *scheme = request.URL.scheme;
    NSURL *url = [request URL];
    
    NSMutableString *urlString = [NSMutableString stringWithString:[request.URL absoluteString]];

    NSString *commandType;
    NSString *parameterString;
    NSDictionary *parameters;
    
    
    
    if (![scheme isEqualToString:kECAdScheme] && ![scheme isEqualToString:kMraidURLScheme])
    {
        // if the scheme is not ecad then let the navigation complete
        if ([scheme isEqualToString:@"tel"] || [scheme isEqualToString:@"mailto"]) {
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
                return NO;
            }
            return YES;
        }
        if (!isLoading && navigationType == UIWebViewNavigationTypeOther) {
            BOOL iframe = ![request.URL isEqual:request.mainDocumentURL];
            if (iframe) return YES;
            [Flurry logEvent:ModalAdDidClickLink];
            
            if ([self.delegate respondsToSelector:@selector(loadInterstitialWebView:)]) {
                isPresentingController = YES;
                NSMutableString *urlString = [NSMutableString stringWithString:[url absoluteString]];
                
                [(ECAdManager *)self.delegate loadInterstitialWebView:urlString];
            }
            else if ([[UIApplication sharedApplication] canOpenURL:url])
                [[UIApplication sharedApplication] openURL:url];
            return NO;
        }
        
        if (!isLoading && navigationType == UIWebViewNavigationTypeLinkClicked) {
            [[UIApplication sharedApplication] openURL:url];
            return NO;
        }
        
        return YES;
    }
    
    if ([scheme isEqualToString:kMraidURLScheme]) {// For MRAID events
        BOOL success = [self tryProcessingURLStringAsCommand:urlString];
        if (success) return NO;
    }
    scheme = [NSString stringWithFormat:@"%@://", kECAdScheme];
    NSString *schemelessUrlString = [urlString substringFromIndex:scheme.length];
    NSRange r = [schemelessUrlString rangeOfString:@"?"];
    
    if (r.location != NSNotFound) {
        
        commandType = [[schemelessUrlString substringToIndex:r.location] lowercaseString];
        parameterString = [schemelessUrlString substringFromIndex:(r.location + 1)];
        parameters = MPDictionaryFromQueryString(parameterString);
        
    }
    
    // Check the host to see if it is a close
    
    if ([schemelessUrlString isEqualToString:@"close"] || [commandType isEqualToString:@"close"]) {
        if (r.location != NSNotFound) {
            if ([parameters objectForKey:kECADState]) {
                [self.sdkParams setObject:[parameters objectForKey:kECADState] forKey:kECADState];
                [self finishAdWithResult:kECModalAdDynamic];
            }
            else
                [self finishAdWithResult:kECModalAdUserClose];
        }
        else
            [self finishAdWithResult:kECModalAdUserClose];
        return NO;
    }
    
    else if ([commandType isEqualToString:kECAdActionAdLoaded]) {
        // Show Close button here and start a timer so the user can click it.
        [Flurry logEvent:ModalAdDidShow];
        
        [self showCloseButton];
        [self addECADParamsFrom:parameters ToParmas:self.sdkParams];
        if (self.refreshRate > 0.0) {
            [self performSelector:@selector(refreshAd:) withObject:nil afterDelay:self.refreshRate];
        }
        return NO;
    }else if ([commandType isEqualToString:kECAdActionAdFailed]) {
        [self addECADParamsFrom:parameters ToParmas:self.sdkParams];
        [self finishAdWithResult:kECModalAdTimeout];
        return NO;
    }
    
    else if ([commandType isEqualToString:kECAdActionAdVibrate])
    {
        [self vibrateDevice];
        return NO;
    }
    
    
    if ([commandType isEqualToString:kECADPass]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@",parameterString]]];
        [Flurry logEvent:ModalADDidClickPassbook];
        return NO;
    }
    
    // To Process querry strings
    //    NSString *schemelessUrlString = [urlString substringFromIndex:scheme.length];
    //    NSRange r = [schemelessUrlString rangeOfString:@"?"];
    if (r.location != NSNotFound) {
        
        if ([commandType isEqualToString:kECAdOpenAppStore] && [parameterString length]) {
            // Code for Call Now
            NSString *appstoreId = [parameters objectForKey:@"id"];
            NSString *appstoreURL = [parameters objectForKey:@"url"];
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0 ) {
                BOOL success = [self openInAppStore:appstoreId];
                if (!success)
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appstoreURL]];
            }
            else if ([appstoreURL length])
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appstoreURL]];
            [Flurry logEvent:ModalADDidOpenAppstore];
            
            return NO;
        }
        if ([commandType isEqualToString:kECAdOpen] && [parameterString length]) {
            //ECLog(@"Open URL: %@",urlString);
            if ([self.delegate respondsToSelector:@selector(loadInterstitialWebView:)]) {
                isPresentingController = YES;
                [(ECAdManager *)self.delegate loadInterstitialWebView:parameterString];
            }
            return NO;
        }
        if ([commandType isEqualToString:kECAdExpandableUseCustomClose] || [parameters objectForKey:@"shouldUseCustomClose"]) {
            BOOL show = ([[[parameters objectForKey:@"shouldUseCustomClose"] lowercaseString] isEqualToString:@"true"]  || [[[parameters objectForKey:@"shouldUseCustomClose"] lowercaseString] isEqualToString:@"yes"]  )? YES:NO;
            [self.closeButton setHidden:show];
        }
    }
    
    return YES;
    
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    ECLog(@"webViewDidStartLoad");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    ECLog(@"webViewDidFinishLoad - %@", webView);
    
    if (isLoading) {
        isLoading = NO;
        _currentState = MRAdViewStateDefault;
        //        [self initializeJavascriptState];
        [[ECMRAIDHelper sharedHelper] setWebView:_webView];
        [[ECMRAIDHelper sharedHelper] initializeJavascriptState:_placementType state:_currentState];
    }
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    isLoading = NO;
    [Flurry logEvent:ModalAdDidFail];
    [self finishAdWithResult:kECModalAdFailed];
    
}

- (void)viewDidLoad
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self initSDKParams:self.sdkParams];
    NSUserDefaults *userDefaults =  [NSUserDefaults standardUserDefaults];
    self.adCloseParamArray = [[NSMutableArray alloc] initWithArray:[userDefaults objectForKey:kADCloseParamArray]];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(closeClicked:)
                                                name:UIApplicationDidEnterBackgroundNotification
                                              object:nil];
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}
#pragma mark - Private
- (void)animateSpinner {
    if (nil == self.spinner) {
        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.spinner setCenter:self.view.center];
        [self.view addSubview:self.spinner];
        [self.spinner setHidesWhenStopped:YES];
        [self.view bringSubviewToFront:self.spinner];
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
                    ECLog(@"Presented");
                    isPresentingController = YES;
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


- (void)showCloseButton
{
    ECLog(@"Show the Close button");
    self.closeButton.hidden = NO;
}

- (void)finishAdWithResult:(kECModalAdResult)result
{
    NSDictionary *serverResponse = [self responseToSendToECForResult:result];
    [self.delegate modalAdDidFinishWithResult:result withServerResponse:serverResponse];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (NSDictionary *)responseToSendToECForResult:(kECModalAdResult)result
{
    if ([[self.sdkParams objectForKey:kECShouldEnableLog] caseInsensitiveCompare:@"false"] == NSOrderedSame ||[[self.sdkParams objectForKey:kECShouldEnableLog] caseInsensitiveCompare:@"no"] == NSOrderedSame || ![self.sdkParams objectForKey:kECAdID] || ![self.sdkParams objectForKey:kECRequestID])
        return nil;
    
    NSString *stateOfRequest;
    
    // translate the result of showing the Ad into a string
    switch (result)
    {
        case kECModalAdUserInteractionComplete:
            stateOfRequest = kECAdActionInteractionSuccess;
            break;
        case kECModalAdUserClose:
            stateOfRequest = kECAdActionClose;
            break;
        case kECModalAdTimeout:
            stateOfRequest = kECAdActionInteractionTimeout;
            break;
        case kECModalAdDynamic:
            stateOfRequest = [self.sdkParams objectForKey:kECADState];
            break;
        default:
            break;
    }
    
    NSMutableDictionary* info = [[NSMutableDictionary alloc] init];
    
    // Add the Ad ID that was shown
    NSString *adID = [self.sdkParams objectForKey:kECAdID];
    if ([adID length])
        [info setValue:adID forKey:kECAdID];
    
    // Add the result of showing the ad
    if ([stateOfRequest length])
        [info setValue:stateOfRequest forKey:kECADState];
    
    // The request id for the ad
    NSString *requestID = [self.sdkParams objectForKey:kECRequestID];
    if ([requestID length])
        [info setValue:requestID forKey:kECRequestID];
    
    // and finally the session id
    if ([[self.sdkParams objectForKey:kECAdSessionID] length])
        [info setValue:[self.sdkParams objectForKey:kECAdSessionID] forKey:kECAdSessionID];
    [self.adCloseParamArray addObject:info];
    
    return info;
}

- (IBAction)closeClicked:(id)sender
{
    // Indicate to the listener that the user closed the Ad
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self finishAdWithResult:kECModalAdUserClose];
}

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

//    if ([self.sdkParams count])
//        return;
//    self.sdkParams = [[NSMutableDictionary alloc] init];
    
    if ([self.adParams objectForKey:kECAdWidth] && [self.adParams objectForKey:kECAdHeight]) {
        [self.sdkParams setValue:[self.adParams objectForKey:kECAdWidth] forKey:kECModalAdViewportWidth];
        [self.sdkParams setValue:[self.adParams objectForKey:kECAdHeight] forKey:kECModalAdViewportHeight];
    }
    else {
        int width = self.webView.frame.size.width;
        int height = self.webView.frame.size.height;
        // set the viewport height and width
        [self.sdkParams setValue:[NSString stringWithFormat:@"%d",width] forKey:kECModalAdViewportWidth];
        [self.sdkParams setValue:[NSString stringWithFormat:@"%d",height] forKey:kECModalAdViewportHeight];
        
    }
    
    
    //    // set the viewport height and width
    //    int width = self.webView.frame.size.width;
    //    int height = self.webView.frame.size.height;
    //
    //    [self.sdkParams setValue:[NSString stringWithFormat:@"%d", width] forKey:kECModalAdViewportWidth];
    //    [self.sdkParams setValue:[NSString stringWithFormat:@"%d", height] forKey:kECModalAdViewportHeight];
    
    // set the ad type
    [self.sdkParams setValue:@"s" forKey:kECModalAdTypeKey];
    
    // set the request time stamp
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss:SSS";
    [self.sdkParams setValue:[dateFormatter stringFromDate:now] forKey:kECModalAdRequestTime];
    
    // set the medium
    [self.sdkParams setValue:@"mweb" forKey:kECModalAdMedium];
    
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = [bundle infoDictionary];
    NSString *prodName = [info objectForKey:@"CFBundleDisplayName"];
    
    [self.sdkParams setValue:prodName forKey:kECModalAdHURL];
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
    if (![self.responseDict count]) {
        NSURL *bannerURL = [self getBannerURL];//[NSURL URLWithString:[self.adParams objectForKey:kECBannerADURL]];
        NSURLRequest *bannerRequest = [NSURLRequest requestWithURL:bannerURL];
        
        NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
        [NSURLConnection sendAsynchronousRequest:bannerRequest queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            [self.responseDict setObject:httpResponse forKey:@"httpResponse"];
            if ([data length])
                [self.responseDict setObject:data forKey:@"data"];
            if (error)
                [self.responseDict setObject:error forKey:@"error"];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self loadAdResponse];
            });
            
        }];
    }else {
        [self loadAdResponse];
        
    }
}

- (NSMutableDictionary *)responseDict {
    if (_responseDict == nil)
        _responseDict = [NSMutableDictionary dictionary];
    return _responseDict;
}
- (void)loadAdResponse {
    
    NSHTTPURLResponse *httpResponse  =[self.responseDict objectForKey:@"httpResponse"];
    NSData *data = [self.responseDict objectForKey:@"data"];
    NSError *error = [self.responseDict objectForKey:@"error"];
    
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary* headers = [httpResponse allHeaderFields];
    //ECLog(@"Headers %@",headers);
    //ECLog(@"responseString %@",responseString);
    
    
    if ([[headers objectForKey:@"X-ADTYPE"] intValue] != 1 ) {
        ECLog(@"Error: The ad you are trying to render is of Non-Interstial type");
        [self webView:self.webView didFailLoadWithError:error];
    }
    else {
        if ([headers objectForKey:@"X-CLICK-URL"])
            [[NSUserDefaults standardUserDefaults] setObject:[headers objectForKey:@"X-CLICK-URL"] forKey:@"ecclickserviceurl"];
        
        
        if ([headers objectForKey:@"X-IMPRESSION-URL"])
            [[NSUserDefaults standardUserDefaults] setObject:[headers objectForKey:@"X-IMPRESSION-URL"] forKey:@"ecimpserviceurl"];
        
        
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
}

- (NSURL *)getBannerURL {
    NSURL *url;
    if ([self.adParams objectForKey:kECBannerADURL])
        url = [NSURL URLWithString:[self.adParams objectForKey:kECBannerADURL]];
    else {
        NSString *str = [[NSUserDefaults standardUserDefaults] objectForKey:@"ecadserviceurl"];
        NSString *requestURL = ([str length]?str:kECInterstitialRequestURL);
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
    
    if ([[paramDictionary objectForKey:kECIsBackgroundTransparent] caseInsensitiveCompare:@"yes"] == NSOrderedSame || [[paramDictionary objectForKey:kECIsBackgroundTransparent] caseInsensitiveCompare:@"true"] == NSOrderedSame) {
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
                if([paramKey caseInsensitiveCompare:kECADTime] == NSOrderedSame)
                {
                    [paramDictionary setValue:[NSNumber numberWithInteger:[paramValue integerValue]] forKey:paramKey];
                }
                else if([paramKey caseInsensitiveCompare:kECAdID] == NSOrderedSame)
                {
                    [paramDictionary setValue:paramValue forKey:paramKey];
                }
                else if([paramKey caseInsensitiveCompare:kECRequestID] == NSOrderedSame)
                {
                    [paramDictionary setValue:paramValue forKey:paramKey];
                }
                else if([paramKey caseInsensitiveCompare:kECShouldEnableLog] == NSOrderedSame) {
                    [paramDictionary setValue:paramValue forKey:kECShouldEnableLog];
                }
                else if([paramKey caseInsensitiveCompare:kECIsBackgroundTransparent] == NSOrderedSame) {
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


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
//    if ([self.responseDict count]) {
//        isLoading = YES;
//        [self loadAdResponse];
//    }
    if ( UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
        [self refreshAd:self.landscapeOrientation];
    else
        [self refreshAd:self.portraitOrientation];

}


- (void)dealloc {
    [[ECMRAIDHelper sharedHelper] setWebView:nil];
    self.delegate = nil;
    self.adParams = nil;
    self.libBundle = nil;
    self.responseDict = nil;
    self.landscapeOrientation = nil;
    self.portraitOrientation = nil;

}
@end
