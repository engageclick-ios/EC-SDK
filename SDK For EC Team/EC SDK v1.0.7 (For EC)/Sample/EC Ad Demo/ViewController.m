//
//  ViewController.m
//  EC Ad Demo
//
//  Created by Engageclick on 9/20/13.
//  Copyright (c) 2013 Engageclick. All rights reserved.
//

#import "ViewController.h"



static NSString *kDemoAppTitle = @"Demo";

@interface ViewController () {
    ECBannerAdView *bannerView;
}

- (void) didShowECAd:(NSNotification *)notification;
@end


@implementation ViewController

- (id)init
{
    self = [super init];
    if (self)
    {
        [self.view setBackgroundColor:[UIColor grayColor]];
        // initialize the params that need to be passed to the EC Ad SDK

    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    iPad = [[UIDevice currentDevice] userInterfaceIdiom] ==UIUserInterfaceIdiomPad;

    self.navigationItem.title = kDemoAppTitle;
    
    self.adParams = [NSMutableDictionary dictionary];
    
    /*
     Ad Sizes:
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
    if (iPad)
        [self.adParams setObject:@"20b8a27e-8fbe-11e3-9f9e-22000a1c450e" forKey:kECAdAppIDKey]; // Put in your App Id Here
    else
        [self.adParams setObject:@"20b852f6-8fbe-11e3-9f9e-22000a1c450e" forKey:kECAdAppIDKey]; // Put in your App Id Here

    
    // Provide user paramters below if any.
    [self.adParams setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"male",@"Gender",@"26",@"Age", nil]forKey:kECAdUserParams];
    
    
    
    // These are optional parameters
    [self.adParams setObject:@"MainViewController" forKey:kECAdReferrerKey];
    [self.adParams setObject:@"Sample" forKey:kECKeywordKey];
    [self.adParams setObject:@"Technology Demonstrator" forKey:kECCategoryKey];

//   BOOL to enable/disable debug logs
    [[ECAdManager sharedManager] setEnableLog:YES];
    
    
    // Add this observer in case of Modal Ad to get notified when a Modal ad is loaded.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowECAd:) name:kECAdManagerDidShowAdNotification object:nil];
}

- (void)viewDidUnload
{
    // stop listening to the notificatino that tells us about showing the ad
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kECAdManagerDidShowAdNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    // Dispose of any resources that can be recreated.
}

- (void) didShowECAd:(NSNotification *)notification
{
    NSString *result = [notification.userInfo objectForKey:kECAdStatusKey];
    ECLog(@"EC Ad Status : %@", result);
}

- (IBAction)showModalAd:(id)sender
{
    if (iPad)
        [self.adParams setObject:[NSNumber numberWithInt:EC_AD_728x1024] forKey:kECAdSize]; //  Put in your Ad Size here
    else
        [self.adParams setObject:[NSNumber numberWithInt:EC_AD_320x480] forKey:kECAdSize]; //  Put in your Ad Size here

    if (NO == [[ECAdManager sharedManager] showECModalAdWithParameters:self.adParams withViewController:self refresh:0.0])
    {
        // ECLog(@"Failed to show EngageClick Ad");
    }
    
    /*
     Use this code to dismiss ECAd Modal View. Set animated paramters to YES or NO
     [[ECAdManager sharedManager] dismissECModalAd:YES];
     */
}

- (IBAction)showBannerAd:(id)sender {
    if (iPad)
        [self.adParams setObject:[NSNumber numberWithInt:EC_AD_728x90] forKey:kECAdSize]; //  Put in your Ad Size here
    else
        [self.adParams setObject:[NSNumber numberWithInt:EC_AD_320x50] forKey:kECAdSize]; //  Put in your Ad Size here


    if (bannerView) {
        [bannerView removeFromSuperview];
        bannerView = nil;
    }
    /* Set th refresh Parameter to number of seconds the ad needs to refresh every time. Default is set to 0
    You can also use [[ECAdManager sharedManager] refreshBannerAd] to refresh the ad manually
    */
    ECBannerAdView *view =     [[ECAdManager sharedManager] showECBannerAdWithParameters:self.adParams withViewController:self.view Custom:NO refresh:0.0 delegate:self];
 
//    Uncomment this line to manually set the delegate to override "modalAdPresentingViewcontroller" method
//    [[ECAdManager sharedManager] setBannerAdDelegate:self];
    
    if (view) {
        if (iPad) {
            if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
                [view layoutFrame:CGRectMake(0,self.view.frame.size.width,self.view.frame.size.height,90)];
            else
                [view layoutFrame:CGRectMake(0,self.view.frame.size.height,self.view.frame.size.width,90)];
            
        }
        else {
            if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
                [view layoutFrame:CGRectMake(0,self.view.frame.size.width,self.view.frame.size.height,50)];
            else
                [view layoutFrame:CGRectMake(0,self.view.frame.size.height,self.view.frame.size.width,50)];
            
        }
        [view refreshAd];
        bannerView = view;
    }
}



#pragma mark - Banner Ad delegate

- (UIViewController *)modalAdPresentingViewcontroller {
    return self; //  Specify the ViewController from which the Modal Ads will be presented from
}



- (void)bannerAdViewDidLoad:(ECBannerAdView *)bannerAdView {
    [UIView animateWithDuration:1.0 animations:^{
        if (iPad) {
            if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
                [bannerAdView layoutFrame:CGRectMake(0,self.view.frame.size.width-90,self.view.frame.size.height,90)];
            else
                [bannerAdView layoutFrame:CGRectMake(0,self.view.frame.size.height-90,self.view.frame.size.width,90)];
            
        }
        else {
            if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
                [bannerAdView layoutFrame:CGRectMake(0,self.view.frame.size.width-50,self.view.frame.size.height,50)];
            else
                [bannerAdView layoutFrame:CGRectMake(0,self.view.frame.size.height-50,self.view.frame.size.width,50)];
            
        }

        
        [bannerAdView setCloseButtonHidden:YES];
    } completion:^(BOOL finished) {
    }];
}
- (void)bannerAdView:(ECBannerAdView *)bannerAdView didFailWithError:(NSError *)error {
    
}
- (void)bannerAdViewDidClose:(ECBannerAdView *)bannerAdView {
}
- (void)bannerAdViewDidRestore:(ECBannerAdView *)bannerAdView {
}
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // This is to notify the MRAID about the orientation Change.
    [bannerView rotateToOrientation:toInterfaceOrientation] ;
    
    // The below methods can be used to refresh the Ad on Orientation Change
    //    [bannerView layoutFrame:CGRectMake(0,self.view.frame.size.height - 125, self.view.frame.size.width, 120)];
    //    [bannerView  performSelector:@selector(refreshAd)];
}


- (void)bannerAdView:(ECBannerAdView *)bannerAdView willExpand:(NSString *)urlStr {
}





- (void)dealloc {
    self.adParams = nil;
    [bannerView removeFromSuperview];
    bannerView = nil;
}

@end
