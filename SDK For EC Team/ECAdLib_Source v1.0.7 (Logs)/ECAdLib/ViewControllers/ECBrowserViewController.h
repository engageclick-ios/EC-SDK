//
//  ECModalinterstitialAdViewController.h
//  ECAdLib
//
//  Created by EngageClick on 5/22/13.
//  Copyright (c) 2013 EngageClick. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ECBrowserDelegate;

@interface ECBrowserViewController : UIViewController <UIWebViewDelegate>
@property (nonatomic, unsafe_unretained) id <ECBrowserDelegate> interstitialDelegate;
@property (nonatomic, strong) NSString *clickURL;

@end


@protocol ECBrowserDelegate <NSObject>
@optional
- (void)interstitialAdDidLoad:(ECBrowserViewController *)interstitialAdView;
- (void)interstitialAd:(ECBrowserViewController *)interstitialAdView didFailWithError:(NSError *)error;
- (void)interstitialAd:(ECBrowserViewController *)interstitialAdView didClickLink:(NSString *)urlStr;
- (void)interstitialAdDidClose:(ECBrowserViewController *)interstitialAdView;

@end