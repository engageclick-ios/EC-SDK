//
//  ECModalBannerAdView.h
//  ECAdLib
//
//  Created by Karthik Kumaravel on 5/21/13.
//  Copyright (c) 2013 EngageClick. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol ECBannerAdViewDelegate;

typedef enum
{
    kECBannerAdUserInteractionComplete,
    kECBannerAdUserClose,
    kECBannerAdTimeout,
    kECBannerAdDynamic
} kECBannerAdResult;


typedef enum
{
    kECBannerAd,
    kECIntertialAd
} kECAdType;




// Ad parameters to be supplied by the developer
extern NSString * const kECBannerAdAppPublisherKey;
extern NSString * const kECBannerAdZoneIDKey;
extern NSString * const kECBannerAdAppIDKey;
extern NSString * const kECBannerAdReferrerKey;
extern NSString * const kECBannerAdKeywordKey;
extern NSString * const kECBannerAdCategoryKey;


@interface ECBannerAdView : UIView <UIWebViewDelegate>

- (id)initWithParentView:(UIView *)parentView_;
- (void)layoutFrame:(CGRect)rect;
- (void)refreshAd;
- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation;
- (void)setCloseButtonHidden:(BOOL)hide;
- (void)setUseCustomClose:(BOOL)show;

@property (nonatomic, strong) NSData *webLink;
@property (nonatomic) BOOL customWebView;
@property (nonatomic, strong) NSDictionary *adParams;
@property (nonatomic, strong) NSBundle *libBundle;
@property (nonatomic, unsafe_unretained) id <ECBannerAdViewDelegate> delegate;
@property (nonatomic) CGFloat refreshRate;
@property (nonatomic, unsafe_unretained) id  parent;

@property (nonatomic, strong) NSString *clickURL;

@end

@protocol ECBannerAdViewDelegate <NSObject>
@optional
- (void)bannerAdDidLoad:(ECBannerAdView *)bannerAdView;
- (void)bannerAd:(ECBannerAdView *)bannerAdView didFailWithError:(NSError *)error;
- (void)bannerAd:(ECBannerAdView *)bannerAdView didClickLink:(NSString *)urlStr;
- (void)bannerAd:(ECBannerAdView *)bannerAdView willExpand:(NSString *)urlStr;
- (void)bannerAdDidClose:(ECBannerAdView *)bannerAdView;
- (void)bannerDidRestore:(ECBannerAdView *)bannerAdView;
- (UIViewController *)modalAdPresentingViewcontroller;
- (void)bannerAdDidFinishWithResult:(kECBannerAdResult)result withServerResponse:(NSDictionary *)response;
@end

