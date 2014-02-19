//
//  ECModalAdViewController.h
//  ECAdLib
//
//  Created by bsp on 4/13/13.
//  Copyright (c) 2013 EngageClick. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ECModalAdDelegate;

typedef enum
{
    kECModalAdUserInteractionComplete,
    kECModalAdUserClose,
    kECModalAdFailed,
    kECModalAdTimeout,
    kECModalAdDynamic
} kECModalAdResult;

// Ad parameters to be supplied by the developer
extern NSString * const kECModalAdAppPublisherKey;
extern NSString * const kECModalAdZoneIDKey;
extern NSString * const kECModalAdAppIDKey;
extern NSString * const kECModalAdReferrerKey;
extern NSString * const kECModalAdKeywordKey;
extern NSString * const kECModalAdCategoryKey;

@interface ECModalAdViewController : UIViewController

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) NSBundle *libBundle;
@property (nonatomic, strong) NSDictionary *adParams;
@property (nonatomic, unsafe_unretained) id <ECModalAdDelegate> delegate;
@property (nonatomic) BOOL customWebView;
@property (nonatomic, strong) NSMutableDictionary *responseDict;

@property (nonatomic, strong) NSMutableDictionary *sdkParams;
@property (nonatomic) CGFloat refreshRate;

- (IBAction)closeClicked:(id)sender;
- (id)initWithAdParams:(NSDictionary *)appAdParams;
- (BOOL)tryProcessingURLStringAsCommand:(NSString *)urlString;
- (void)refreshAd:(NSArray *)adSize;

@end

@protocol ECModalAdDelegate <NSObject>

- (void)modalAdDidFinishWithResult:(kECModalAdResult)result withServerResponse:(NSDictionary *)response;

@end