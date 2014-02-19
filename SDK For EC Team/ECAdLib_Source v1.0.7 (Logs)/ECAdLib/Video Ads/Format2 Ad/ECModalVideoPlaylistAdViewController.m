//
//  ECModalVideoPlaylistAdViewController.m
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/9/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import "ECModalVideoPlaylistAdViewController.h"
#import "ECVideoPlaylistFormSheetView.h"
#import "ECAdControlBarGalleryView.h"
#import <QuartzCore/QuartzCore.h>
#import "ECAdManager.h"
#import "EcAdCustomPlayer.h"
#import "ECAdCustomButton.h"

#define kECADControlBarItemTag 9000
#define kBuyBtnTag 1234
#define kMoreBtnTag 1235

#define kBuyNowCloseTag 1236
#define kMoreCloseTag 1237

#define kSurveyTag 9000

@interface SurveyView : UIView
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *questLabel;
@property (nonatomic, strong) UIButton *closeBtn;
@property BOOL shouldShowImages;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) id delegate;
@end
@implementation SurveyView


- (void)setupSurveyView {
    if (nil == self.titleLabel) {
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, self.frame.size.width, 50)];
        [self addSubview:self.titleLabel];
        
    }
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [self.titleLabel setBackgroundColor:[UIColor clearColor]];
    [self.titleLabel setTextColor:[UIColor blackColor]];
    [self.titleLabel setFont:[UIFont boldSystemFontOfSize:16]];
    [self.titleLabel setAdjustsFontSizeToFitWidth:YES];

    
    if (nil == self.questLabel) {
        self.questLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.titleLabel.frame.origin.x, self.titleLabel.frame.size.height + self.titleLabel.frame.origin.y+5, self.titleLabel.frame.size.width,self.titleLabel.frame.size.height)];
        [self addSubview:self.questLabel];
    }
    self.questLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    self.questLabel.numberOfLines = 0;
    self.questLabel.textAlignment = NSTextAlignmentCenter;

    [self.questLabel setBackgroundColor:[UIColor clearColor]];
    [self.questLabel setTextColor:[UIColor blackColor]];
    [self.questLabel setFont:[UIFont systemFontOfSize:14]];
    [self.questLabel setAdjustsFontSizeToFitWidth:YES];
    
    if (nil == self.closeBtn) {
        self.closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.closeBtn setImage:[UIImage imageWithData:[[ECAdManager sharedManager] loadFile:@"close_Icon.png"]] forState:UIControlStateNormal];
        [self.closeBtn addTarget:self action:@selector(closeSurvey) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.closeBtn];
        [self.closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin];
    }
    
    CGRect frame = self.bounds;
    frame.size = CGSizeMake(24, 24);
    frame.origin.x = self.frame.size.width - frame.size.width-8;
    frame.origin.y += 5;
    self.closeBtn.frame = frame;
    
    if (nil == self.scrollView) {
//        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(self.questLabel.frame.origin.x, self.questLabel.frame.origin.y + self.questLabel.frame.size.height + 5, self.questLabel.frame.size.width-10, self.frame.size.height - (self.questLabel.frame.origin.y + self.questLabel.frame.size.height + 5) -5 )];
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.questLabel.frame.origin.y + self.questLabel.frame.size.height + 5, self.frame.size.width, 100 )];

        [self.scrollView setBackgroundColor:[UIColor clearColor]];
        [self addSubview:self.scrollView];
        self.scrollView.center = self.center;
        CGRect rect = self.scrollView.frame;
        rect.origin.x = 0;
        self.scrollView.frame = rect;
        [self.scrollView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin];
    }
}

- (void)closeSurvey {
    [self.delegate continueAd];
}

- (void)dealloc {
    self.titleLabel = nil;
    self.questLabel = nil;
    self.closeBtn = nil;
    self.scrollView = nil;
}
@end
@interface AdContinueView : UIView

@property (nonatomic, strong) UIButton *continueBtn;
@property (nonatomic, strong) UIButton *skipBtn;
@property (nonatomic, unsafe_unretained) id delegate;
@end

@implementation AdContinueView

- (void)setupView:(id)delegate_ {
    self.delegate = delegate_;
    
    self.continueBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.continueBtn setBackgroundColor:[UIColor blueColor]];
    [self.continueBtn setTitle:@"Continue to Ad" forState:UIControlStateNormal];
    [self.continueBtn addTarget:self action:@selector(smartSkipContinueAd) forControlEvents:UIControlEventTouchUpInside];
    [self.continueBtn setAutoresizingMask: UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
    [self addSubview:self.continueBtn];
    
    self.skipBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.skipBtn setBackgroundColor:[UIColor blueColor]];
    [self.skipBtn setTitle:@"Continue to Content" forState:UIControlStateNormal];
    [self.skipBtn setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
    [self.skipBtn addTarget:self action:@selector(smartSkipAd) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.skipBtn];
    
    self.continueBtn.frame = CGRectMake((self.frame.size.width/2)-100, (self.frame.size.height/2)-50 , 200, 50);
    self.skipBtn.frame = CGRectMake((self.frame.size.width/2) -100, self.continueBtn.frame.origin.y + self.continueBtn.frame.size.height+10, 200, 50);
    
    
}

- (void) smartSkipContinueAd {
    if ([self.delegate respondsToSelector:@selector(smartSkipContinueAd:)])
        [self.delegate performSelector:@selector(smartSkipContinueAd:) withObject:self];
}

- (void)smartSkipAd {
    if ([self.delegate respondsToSelector:@selector(smartSkipAd:)])
        [self.delegate performSelector:@selector(smartSkipAd:) withObject:self];
    
}

@end

@interface  RolloverImageView : UIImageView {
}

@property (nonatomic, strong) UIImage *startImage;
@property (nonatomic, strong) UIImage *endImage;
@property (nonatomic, strong) UIView *fullView;
@property (nonatomic, strong) UIImageView *animatedImageView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIButton *clickToExpand;

- (void)createLabel:(NSString *)text withColor:(UIColor *)color withFont:(UIFont *)font;

@end

@implementation RolloverImageView

- (void)startAnimating {
    if (nil == self.animatedImageView) {
        self.animatedImageView = [[UIImageView alloc] initWithImage:self.startImage];
//        self.animatedImageView.frame = CGRectMake(self.frame.size.width - self.startImage.size.width, 0, self.startImage.size.width, self.startImage.size.height);
        self.animatedImageView.frame = CGRectMake(self.frame.size.width, 0, 50, self.frame.size.height);
        [self.animatedImageView setContentMode:UIViewContentModeScaleAspectFit];
        [self addSubview:self.animatedImageView];
        [self.animatedImageView setBackgroundColor:[UIColor clearColor]];
    }
    
    CGRect frame = self.animatedImageView.frame;
    frame.origin.x = 0;
    [UIView animateWithDuration:1.0 animations:^{
        [self rotate360WithDuration:0.0 repeatCount:3];
        self.animatedImageView.frame = frame;
    }completion:^(BOOL finished){
        [UIView animateWithDuration:0.3 animations:^{
            [self rotate360WithDuration:0.0 repeatCount:1];
            [self.animatedImageView setTransform:CGAffineTransformMakeScale(1.5, 1.5)];
            [self setContentMode:UIViewContentModeScaleToFill];
            self.image = self.endImage;
            self.textLabel.alpha = 1.0;
            self.clickToExpand.alpha = 1.0;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 animations:^{
                [self.animatedImageView setTransform:CGAffineTransformIdentity];
                
            }];
        }];
        //        [self.animatedImageView removeFromSuperview];
        //        self.animatedImageView = nil;
    }];
}
- (void)createLabel:(NSString *)text withColor:(UIColor *)color withFont:(UIFont *)font {
    self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.startImage.size.width+2, 0, self.frame.size.width-self.startImage.size.width+2, self.frame.size.height/2)];
    [self.textLabel setText:text];
    [self.textLabel setTextColor:color];
    [self.textLabel setFont:font];
    [self addSubview:self.textLabel];
    [self.textLabel setBackgroundColor:[UIColor clearColor]];
    self.clickToExpand = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.clickToExpand setTitle:@"Click To Expand" forState:UIControlStateNormal];
   // [self.clickToExpand setBackgroundImage:[UIImage imageNamed:@"buttonImage.png"] forState:UIControlStateNormal];
    
    CGRect frame = CGRectMake((self.frame.size.width-150)/2, self.textLabel.frame.size.height, 150, 30);
    CGPoint center = self.center;
    center.y =  self.textLabel.frame.size.height-5;
    center.x -= 75;
    frame.origin = center;
    self.clickToExpand.frame = frame;
    //    self.clickToExpand.center = self.center;
    [self addSubview:self.clickToExpand];
    
    self.textLabel.alpha = 0.0;
    self.clickToExpand.alpha = 0.0;
}
- (void)rotate360WithDuration:(CGFloat)aDuration repeatCount:(CGFloat)aRepeatCount {
	CAKeyframeAnimation *theAnimation = [CAKeyframeAnimation animation];
	theAnimation.values = [NSArray arrayWithObjects:
						   [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0, 0,0,1)],
						   [NSValue valueWithCATransform3D:CATransform3DMakeRotation(3.13, 0,0,1)],
						   [NSValue valueWithCATransform3D:CATransform3DMakeRotation(6.26, 0,0,1)],
						   nil];
	theAnimation.cumulative = YES;
	theAnimation.duration = aDuration;
	theAnimation.repeatCount = aRepeatCount;
	theAnimation.removedOnCompletion = YES;
	
    theAnimation.timingFunctions = [NSArray arrayWithObjects:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
                                    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
                                    nil
                                    ];
	[self.animatedImageView.layer addAnimation:theAnimation forKey:@"transform"];
}


- (void)dealloc {
    self.animatedImageView = nil;
    self.startImage = nil;
    self.endImage = nil;
}
@end


@interface ECModalVideoPlaylistAdViewController () {
    int currentBannerImageIndex;
}
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) ECVideoPlaylistFormSheetView *formSheetView;
@property (nonatomic, strong) UIView *dummyView;
@property (nonatomic, strong) UIImageView *controlBarBase;
@property (nonatomic, strong) ECAdControlBarGalleryView *galleryView;
@property (nonatomic, strong) SurveyView *surveyView;
@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, strong) NSMutableArray *timeSlots;

@property (nonatomic, strong) NSTimer *overlayTimer;

@end
@implementation ECModalVideoPlaylistAdViewController
@synthesize basePath;

- (NSMutableDictionary *)getResponseDict {
    return self.responseDict;
}

- (NSMutableDictionary *)getImageDict {
    return self.imageDict;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView {
    [super loadView];
    self.view.frame = self.view.bounds;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    
    [self.spinner setCenter:CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2)];
    [self.view addSubview:self.spinner];
    [self.spinner setHidesWhenStopped:YES];
    [self.spinner startAnimating];
    
    
    self.fbContentDict=[NSMutableDictionary dictionary];
    self.twitterContentDict =[NSMutableDictionary dictionary];
    self.socialImages =[NSMutableDictionary dictionary];
    self.socialFBImages =[NSMutableDictionary dictionary];
    self.imageDict= [NSMutableDictionary dictionary];
    self.timeSlots = [NSMutableArray array];

    if (nil == self.responseDict) {
        [self fetchData];
    }
    else {
        [self setupVideoPlayer];
        [self fetchGalleryImages];
    }
    
    
    [self.view bringSubviewToFront:self.spinner];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(playbackFinished:)
                                                name:UIApplicationDidEnterBackgroundNotification
                                              object:nil];

}

- (NSString *)trimResponse:(NSString *)response {
    NSString *trimmedStr = [[response componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    
    NSRange urlStart = [trimmedStr rangeOfString: @"{"];
    NSRange urlEnd = [trimmedStr rangeOfString: @"};"];
    NSRange resultedMatch = NSMakeRange(urlStart.location, urlEnd.location - urlStart.location + urlEnd.length-1);
    if (resultedMatch.location == NSNotFound) {
        return  @"Error";
    }
    trimmedStr = [trimmedStr substringWithRange:resultedMatch];
    return trimmedStr;
}

- (NSData *)loadFile:(NSString *)name {
    return [[ECAdManager sharedManager] loadFile:name];
}


- (void)fetchData {
    //    NSString *path = [NSString stringWithFormat:@"http://api.geonames.org/citiesJSON?north=44.1&south=-9.9&east=-22.4&west=55.2&lang=de&username=demo"];
    if (nil == self.basePath)
        self.basePath = [NSString stringWithFormat:@"http://devefence.engageclick.com/ecadserve/ecvideoFlash?mediaIdExternal=3&mediaSystemId=1&flashFormat=FSALL"];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.basePath]] ;
    
    
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
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        ECLog(@"responseString = %@ and response statusCode = %d",responseString, [httpResponse statusCode]);
        data=[responseString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (responseDictionary)
            self.responseDict = [NSMutableDictionary dictionaryWithDictionary:responseDictionary];
        
        if ([httpResponse statusCode] == 200) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self setupVideoPlayer];
                [self fetchGalleryImages];
            });
            
        } else {
        }
    }];
}
- (void)fetchGalleryImages {
    if (self.adFormat == kECAdControlOverlay)
        return;
    if (self.adFormat == kECAdSmartSkipSurvey) {
        
    }
    [self downloadLogoImage];
    NSDictionary *data =  [self.responseDict objectForKey:@"data"];
    NSString *baseURL = [self.responseDict objectForKey:@"apiserver"];
    if (![baseURL length])
        return;
    NSArray *imagesArray = [data objectForKey:@"fois"];
    
    [imagesArray enumerateObjectsUsingBlock:^(NSString *imgUrl, NSUInteger idx, BOOL *stop) {
        NSString *imageURL = [baseURL stringByAppendingString:imgUrl];
        [self downloadGalleryImages:imageURL forIndexPath:idx];
    }];
    //    if (self.adFormat == kECAdControlBar) {
    if (self.adFormat != kECAdSmartSkip) {
        [self fetchSocialImages];
        [self fetchVideoThumbnails];
    }
    
}

- (void)fetchVideoThumbnails {
    if (nil == self.videoThumbDict)
        self.videoThumbDict = [NSMutableDictionary dictionary];
    [self.videoThumbDict removeAllObjects];
    NSString *media = [self.responseDict objectForKey:@"similarmediathumbnail"];
    if ((NSNull *)media == [NSNull null])      return;
    NSArray *thumbnails = [media componentsSeparatedByString:@","];
    [thumbnails enumerateObjectsUsingBlock:^(NSString *imgUrl, NSUInteger idx, BOOL *stop) {
        [self downloadVideoThumbnails:imgUrl forIndexPath:idx];
    }];
    
}

- (void)downloadVideoThumbnails:(NSString *)urlStr forIndexPath:(int)index {
    //    NSString *path = [NSString stringWithFormat:@"http://devefence.engageclick.com/ecadserve/ecvideoFlash?mediaIdExternal=2&mediaSystemId=1&flashFormat=FSALL"];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlStr]] ;
    
    
    [request setHTTPMethod:@"GET"];
    //	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if ([httpResponse statusCode] == 200) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                UIImage *image = [UIImage imageWithData:data];
                if (image)
                    [self.videoThumbDict setObject:[UIImage imageWithData:data] forKey:[NSString stringWithFormat:@"%d",index]];
                
            });
        } else {
        }
    }];
    
}

- (void)fetchSocialImages {
    NSDictionary *data =  [self.responseDict objectForKey:@"socialData"];
    NSArray *keys =[data allKeys];
    NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
    keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
    if (![keys count])
        return;
    
    [keys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        NSDictionary *socialFeed = [data objectForKey:key];
        //[self.socialData addObject:socialFeed];
        BOOL isTwitter = [[socialFeed objectForKey:@"source"] isEqualToString:@"Twitter"] ? YES : NO;
        if (isTwitter) {
            [self.twitterContentDict setObject:socialFeed forKey:key];
            [self downloadSocialImages:[socialFeed objectForKey:@"iconurl"]];
            
        }
        else {
            [self.fbContentDict setObject:socialFeed forKey:key];
            [self downloadSocialImages:[socialFeed objectForKey:@"picture"]];
            
        }
    }];
}

- (void)downloadSocialImages:(NSString *)urlStr {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlStr]] ;
    
    
    [request setHTTPMethod:@"GET"];
    //	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if ([httpResponse statusCode] == 200) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                UIImage *image = [UIImage imageWithData:data];
                if (image)
                    [self.socialImages setObject:[UIImage imageWithData:data] forKey:urlStr];
                
            });
        } else {
        }
    }];
    
}

- (void)downloadLogoImage {
    //    brandlogo
    if ([NSNull null] == [self.responseDict objectForKey:@"brandlogo"])
        return;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[self.responseDict objectForKey:@"brandlogo"]]] ;
    
    
    [request setHTTPMethod:@"GET"];
    //	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if ([httpResponse statusCode] == 200) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                UIImage *image = [UIImage imageWithData:data];
                if (image) {
                    self.logoImage = image;
                }
                
            });
        } else {
        }
    }];
    
}

- (void)downloadGalleryImages:(NSString *)urlStr forIndexPath:(int)index {
    //    NSString *path = [NSString stringWithFormat:@"http://devefence.engageclick.com/ecadserve/ecvideoFlash?mediaIdExternal=2&mediaSystemId=1&flashFormat=FSALL"];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlStr]] ;
    
    
    [request setHTTPMethod:@"GET"];
    //	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if ([httpResponse statusCode] == 200) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                UIImage *image = [UIImage imageWithData:data];
                if (image)
                    [self.imageDict setObject:[UIImage imageWithData:data] forKey:[NSString stringWithFormat:@"%d",index]];
                
            });
        } else {
        }
    }];
    
}

- (void)setupVideoPlayer {
    
    NSDictionary *data =  [self.responseDict objectForKey:@"data"];
    self.moviePlayer = [[EcAdCustomPlayer alloc] initWithContentURL:[NSURL URLWithString: [data objectForKey:@"media"]]];
    [(EcAdCustomPlayer *)self.moviePlayer setTargetURL:[self.responseDict objectForKey:@"targeturl"]];

    self.moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.moviePlayer.view.frame = self.view.bounds;
    [self.moviePlayer setControlStyle:MPMovieControlStyleNone];
    [self.view addSubview:self.moviePlayer.view];
    [self.moviePlayer prepareToPlay];
    [self.moviePlayer play];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackChanged:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:self.moviePlayer];
    
    [self.view bringSubviewToFront:self.spinner];
    
    
    self.closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"black_Close.png"]] forState:UIControlStateNormal];
    [self.closeBtn addTarget:self action:@selector(viewCloseBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeBtn];
    [self.closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    CGRect rect = self.view.bounds;
    rect.origin.x = rect.size.width - 40;
    rect.origin.y = 5;
    rect.size = CGSizeMake(40, 40);
    self.closeBtn.frame = rect;
    [self.view bringSubviewToFront:self.closeBtn];
}

- (void)viewCloseBtnClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"userAdClose"];

    if ([self.delegate respondsToSelector:@selector(adVideoDidFinishPlayback)])
        [self.delegate performSelector:@selector(adVideoDidFinishPlayback)];
    
}
- (void)createRollingdBtn {
    
    UIButton  *adBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [adBtn setTitle:@" " forState:UIControlStateNormal];
    [adBtn addTarget:self action:@selector(adBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    adBtn.frame = CGRectMake(self.moviePlayer.view.frame.origin.x+5, self.moviePlayer.view.frame.origin.y + self.moviePlayer.view.frame.size.height - 100, self.moviePlayer.view.frame.size.width-10, 100);
    [adBtn setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleBottomMargin| UIViewAutoresizingFlexibleTopMargin];
    [adBtn setBackgroundColor:[UIColor clearColor]];
    [self.moviePlayer.view addSubview:adBtn];
    if ([self.responseDict objectForKey:@"brand"] && (NSNull *)[self.responseDict objectForKey:@"brand"] != [NSNull null]) {
        NSString *brand = [self.responseDict objectForKey:@"brand"];
        brand = [[brand stringByReplacingOccurrencesOfString:@" " withString:@"_"] lowercaseString];
        RolloverImageView *img=[[RolloverImageView alloc]init];
//        [img setStartImage:[UIImage imageWithData:[self.delegate loadFile:[NSString stringWithFormat:@"%@_start.png",brand]]]];
        [img setStartImage:self.logoImage];
        
        //    [img setEndImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@_end.png",brand]]];
        [img setEndImage:[UIImage imageWithData:[self.delegate loadFile:@"rollover_bg.png"]]];
        
        img.frame = CGRectMake(self.moviePlayer.view.frame.origin.x+5, self.moviePlayer.view.frame.origin.y + self.moviePlayer.view.frame.size.height - 100, self.moviePlayer.view.frame.size.width-10, img.endImage.size.height);
        [img createLabel:@"Explore More !!!!" withColor:[UIColor colorWithRed:16.0/255.0 green:66.0/255.0 blue:147.0/255.0 alpha:1.0] withFont:[UIFont boldSystemFontOfSize:18.0]];
        [img.clickToExpand setBackgroundImage:[UIImage imageWithData:[self.delegate loadFile:@"buttonImage.png"]] forState:UIControlStateNormal];

        [img setBackgroundColor:[UIColor clearColor]];
        [img setContentMode:UIViewContentModeScaleAspectFit];
        [img setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleBottomMargin| UIViewAutoresizingFlexibleTopMargin];
        [self.moviePlayer.view addSubview:img];
        [img startAnimating];
        [self.moviePlayer.view bringSubviewToFront:img];
        
    }
    //    [self.moviePlayer.view bringSubviewToFront:adBtn];
}



- (void)adBtnClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"overlayClicked"];

    [self.moviePlayer pause];
    self.dummyView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.dummyView];
    [self.view bringSubviewToFront:self.dummyView];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            //956,546
            self.formSheetView = [[ECVideoPlaylistFormSheetView alloc] initWithFrame:CGRectMake(0, 0, 956, 546)];
        }
        else
            self.formSheetView = [[ECVideoPlaylistFormSheetView alloc] initWithFrame:CGRectMake(0, 0, 700, 800)];
    }
    else {
        self.formSheetView = [[ECVideoPlaylistFormSheetView alloc] initWithFrame:CGRectInset(self.moviePlayer.view.frame, 10, 10)];
        
    }
    [self.formSheetView setAutoresizesSubviews:YES];
    self.formSheetView.parentView = self;
    self.formSheetView.center =CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
    self.formSheetView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.dummyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.formSheetView setupTopView];
    [self.view addSubview:self.formSheetView];
    CGRect frame = self.formSheetView.frame;
    frame.origin.y = self.view.frame.origin.y + self.view.frame.size.height;
    self.formSheetView.frame = frame;
    
    frame = self.dummyView.frame;
    frame.origin.y =  self.view.frame.origin.y + self.view.frame.size.height;
    self.dummyView.frame = frame;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.formSheetView.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
        [self.dummyView setBackgroundColor:[UIColor whiteColor]];
        self.dummyView.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
        [self.dummyView setAlpha:0.3];
    }];
}

- (void)layoutFrames:(UIInterfaceOrientation)interfaceOrientation {
    
}
- (void)playbackFinished:(MPMoviePlayerController *)player {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if ([self.delegate respondsToSelector:@selector(adVideoDidFinishPlayback)])
        [self.delegate performSelector:@selector(adVideoDidFinishPlayback)];
}
- (void)playbackChanged:(MPMoviePlayerController *)player {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.adFormat == kECAdControlOverlay)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:self.moviePlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self.moviePlayer selector:@selector(play) name:@"AppDidEnterForeground" object:nil];
    
    
    //    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:player];
    [self.spinner stopAnimating];
    switch (self.adFormat) {
        case kECVideoPlaylist:
            [self performSelector:@selector(createRollingdBtn) withObject:nil afterDelay:2.0];
            break;
        case kECAdControlBar:
            [self performSelector:@selector(createAdControlBar) withObject:nil afterDelay:2.0];
            break;
        case kECAdSmartSkip:
            [self performSelector:@selector(createSkipBtn) withObject:nil afterDelay:2.0];
            break;
            case kECAdSmartSkipSurvey:
            [self performSelector:@selector(createSkipBtn) withObject:nil afterDelay:2.0];
            break;

        case kECAdControlOverlay:
            [self startTimerForOverlayCheck];
            break;
        default:
            break;
    }
}

- (void)createSkipBtn {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.moviePlayer.view addSubview: button];
    [button setTitle:@"Skip Ad >>" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]];
    if (self.adFormat == kECAdSmartSkip)
        [button addTarget:self action:@selector(controlBarGalleryClicked) forControlEvents:UIControlEventTouchUpInside];
    else
        [button addTarget:self action:@selector(skipForSurvey:) forControlEvents:UIControlEventTouchUpInside];
    
    [button setFrame:CGRectMake(self.moviePlayer.view.frame.size.width-200, self.moviePlayer.view.frame.size.height - 100, 150, 50)];
    [button setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin];
    [button.layer setBorderWidth:2.0];
    [button.layer setBorderColor:[UIColor whiteColor].CGColor];
    [button.layer setCornerRadius:12.0];
}

- (void)skipForSurvey:(UIButton *)btn {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (nil == self.surveyView) {
        [self.moviePlayer pause];
        self.surveyView = [[SurveyView alloc] init];
        self.surveyView.delegate = self;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            self.surveyView.frame = CGRectInset(self.moviePlayer.view.bounds, 100, 100);
        else
            self.surveyView.frame = CGRectInset(self.moviePlayer.view.bounds, 20, 20);
        
        [self.moviePlayer.view addSubview:self.surveyView];
        [self.surveyView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self.surveyView setBackgroundColor:[UIColor colorWithRed:133.0/255.0 green:195.0/255.0 blue:232.0/255.0 alpha:1.0]];
        [self.surveyView setAlpha:0.0];
        [self createDummyImageView];
        
        self.surveyView.layer.cornerRadius = 20.0;
        self.surveyView.layer.borderWidth = 4.0;
        self.surveyView.layer.borderColor = [UIColor whiteColor].CGColor;
        
        [self.surveyView setupSurveyView];
        [self.view bringSubviewToFront:self.moviePlayer.view];
        [self.moviePlayer.view bringSubviewToFront:self.surveyView];
        
        [UIView animateWithDuration:0.5 animations:^{
            [self.dummyView setBackgroundColor:[UIColor whiteColor]];
            [self.surveyView setAlpha:1.0];
        }];
    }
    else {
        [UIView animateWithDuration:0.5 animations:^{
            [self.surveyView setAlpha:0.0];
        } completion:^(BOOL finished) {
            [self.surveyView removeFromSuperview];
            self.surveyView = nil;
            [self.dummyView removeFromSuperview];
            self.dummyView = nil;
            [self.moviePlayer play];
        }];
        
    }
    
    self.surveyView.titleLabel.text = [[self.responseDict objectForKey:@"data"] objectForKey:@"skipfomat_title"];
    self.surveyView.questLabel.text = [[self.responseDict objectForKey:@"data"] objectForKey:@"skipfomat_quest"];
    [self loadSurveyScrollContent:[[self.responseDict objectForKey:@"data"] objectForKey:@"skipfomat"]];
}


- (void)loadSurveyScrollContent:(NSArray *)array {
        __block float x = 5;
    [array enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        if ([obj objectForKey:@"image"] &&[obj objectForKey:@"image"] != [NSNull null]) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, 5, 100, self.surveyView.scrollView.frame.size.height -5)];
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[obj objectForKey:@"image"]]];
            [imageView setImage:[UIImage imageWithData:data]];
            [imageView setContentMode:UIViewContentModeScaleAspectFit];
            [self.surveyView.scrollView addSubview:imageView];
            [imageView setTag:kSurveyTag+idx];
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(itemTapped:)];
            [imageView addGestureRecognizer:tap];
            [imageView setUserInteractionEnabled:YES];
            
            imageView.layer.borderColor = [UIColor blackColor].CGColor;
            imageView.layer.borderWidth = 2.0;

        }else {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x, 5, 100, self.surveyView.scrollView.frame.size.height -5)];
            label.text = [obj objectForKey:@"title"];
            [label setFont:[UIFont boldSystemFontOfSize:14]];
            [label setTextAlignment:NSTextAlignmentCenter];
            [label setTextColor:[UIColor blackColor]];
            label.numberOfLines = 0;
            label.textAlignment = NSTextAlignmentCenter;

            [label setBackgroundColor:[UIColor clearColor]];
            [label setAdjustsFontSizeToFitWidth:YES];
            [self.surveyView.scrollView addSubview:label];
            [label setTag:kSurveyTag+idx];
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(itemTapped:)];
            [label addGestureRecognizer:tap];
            [label setUserInteractionEnabled:YES];
            label.layer.borderColor = [UIColor blackColor].CGColor;
            label.layer.borderWidth = 2.0;


        }
        x += 105;
    }];
    self.surveyView.scrollView.contentSize  = CGSizeMake(x, self.surveyView.scrollView.frame.size.height);
}


- (void)itemTapped:(UIGestureRecognizer *)recognizer {
    
    UIView *view = recognizer.view;
    int tag = [view tag] - kSurveyTag;
    
    for (int i=0; i<[[[self.responseDict objectForKey:@"data"] objectForKey:@"skipfomat"] count];i++ ) {
        UIView *view_ = [self.surveyView.scrollView viewWithTag:i+kSurveyTag];
        if (view_ != view) {
            view_.layer.borderColor = [UIColor blackColor].CGColor;
        }
    }
    if (tag == [[[self.responseDict objectForKey:@"data"] objectForKey:@"choice"] intValue]) {
        view.layer.borderColor = [UIColor greenColor].CGColor;
        view.layer.borderWidth = 2.0;
        [self smartSkippableInteractionSuccess];
    } else {
        view.layer.borderColor = [UIColor redColor].CGColor;
        view.layer.borderWidth = 2.0;
    }
}
- (void)startTimerForOverlayCheck {//8 22
//    [NSTimer scheduledTimerWithTimeInterval:8 target:self selector:@selector(showFindMore) userInfo:nil repeats:NO];
//    [NSTimer scheduledTimerWithTimeInterval:22 target:self selector:@selector(showBuyNow) userInfo:nil repeats:NO];
    currentBannerImageIndex = -1;
    NSDictionary *dict = [self.responseDict objectForKey:@"data"];
    NSArray *array = [dict objectForKey:@"cta"];
    [array enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        if ([obj objectForKey:@"ctaTime"])
            [self.timeSlots addObject:[obj objectForKey:@"ctaTime"]];
    }];
    [self triggerPlaybackTimer];
}

- (void)triggerPlaybackTimer {
    self.overlayTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updatePlaybackProgressFromTimer:) userInfo:nil repeats:YES];
}

- (void) updatePlaybackProgressFromTimer:(NSTimer *)timer {
    if (([UIApplication sharedApplication].applicationState == UIApplicationStateActive) && (self.moviePlayer.playbackState == MPMoviePlaybackStatePlaying)) {
        
        //  NSTimeInterval progress = self.moviePlayer.currentPlaybackTime;
        if ( currentBannerImageIndex+1 >= [self.timeSlots count] /*&& currentBannerImageIndex >=0*/) {
            [self.overlayTimer invalidate];
            self.overlayTimer = nil;
            return;
        }
        
        float currentTime = ceil(self.moviePlayer.currentPlaybackTime);
        float playerTimer = [[self.timeSlots objectAtIndex:currentBannerImageIndex+1] doubleValue]/1000;
        if (currentTime >= playerTimer) {
            currentBannerImageIndex ++;
            if (currentBannerImageIndex>= [self.timeSlots count]) {
                [self.overlayTimer invalidate];
                self.overlayTimer = nil;
            }
            else {
                //[self scrollBanner];
                [self showFindMore];
            }
            
        }
    }
}
- (void)showFindMore {
    ECAdCustomButton *btn = (ECAdCustomButton *)[self.moviePlayer.view viewWithTag:kMoreBtnTag];
    if (![btn isKindOfClass:[ECAdCustomButton class]]) {
        btn = [ECAdCustomButton buttonWithType:UIButtonTypeCustom];
        [self.moviePlayer.view addSubview:btn];

    }
    NSDictionary *dict = [self.responseDict objectForKey:@"data"];
    NSArray *array = [dict objectForKey:@"cta"];

    [btn setBackgroundColor:[UIColor colorWithRed:65.0/255.0 green:144.0/255.0 blue:255.0/255.0 alpha:0.3]];
    [btn setTitle:[[array objectAtIndex:currentBannerImageIndex] objectForKey:@"ctaName"] forState:UIControlStateNormal];
    btn.tag = kMoreBtnTag;
    [btn setTargetURL:[[array objectAtIndex:currentBannerImageIndex] objectForKey:@"ctaTarget"]];
    [btn.titleLabel setTextColor:[UIColor whiteColor]];
    [btn addTarget:self action:@selector(customBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [btn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        btn.frame = CGRectMake(self.moviePlayer.view.frame.size.width - 250, 300, 200, 60);
        btn.titleLabel.font = [UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:20.0];
    }
    else{
        btn.frame = CGRectMake(self.moviePlayer.view.frame.size.width - 250, 200, 100, 30);
        btn.titleLabel.font = [UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:12.0];
        btn.center = self.moviePlayer.view.center;
    }
    
    btn.layer.borderWidth = 4;
    btn.layer.cornerRadius = 12.0;
    btn.alpha = 0.0;
    
    UIButton *closeBtn = (UIButton *)[self.moviePlayer.view viewWithTag:kMoreCloseTag];
    if (![closeBtn isKindOfClass:[UIButton class]]) {
        closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.moviePlayer.view addSubview:closeBtn];
    }
    [closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"close_Icon.png"]] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeMoreBtn:) forControlEvents:UIControlEventTouchUpInside];
    [closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin];
    [closeBtn setTag:kMoreCloseTag];
    closeBtn.frame = CGRectMake(btn.frame.origin.x+btn.frame.size.width-20, btn.frame.origin.y-20, 20, 20);
    closeBtn.alpha = 0.0;
    
    [UIView animateWithDuration:0.5 animations:^{
        btn.alpha = 1.0;
        closeBtn.alpha = 1.0;
        
    }];
    
}

- (void)customBtnClicked:(ECAdCustomButton *)btn {
    [[ECAdManager sharedManager] videoAdLandingPageOpened:btn.targetURL];

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:btn.targetURL]];
}
- (void)findMoreClicked {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.samsung.com/global/microsite/galaxys4/"]];
}

- (void)buyNowClicked {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.att.com/shop/wireless/devices/samsung/galaxy-s-4-16gb-white-frost.html#fbid=l-3ZIekl5kt"]];
    
}


- (void)showBuyNow {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setBackgroundColor:[UIColor colorWithRed:65.0/255.0 green:144.0/255.0 blue:255.0/255.0 alpha:0.3]];
    [btn setTitle:@"Buy this cool item - the next big thing!" forState:UIControlStateNormal];
    btn.tag = kBuyBtnTag;
    [btn.titleLabel setTextColor:[UIColor whiteColor]];
    [self.moviePlayer.view addSubview:btn];
    [btn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    [btn addTarget:self action:@selector(buyNowClicked) forControlEvents:UIControlEventTouchUpInside];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        btn.frame = CGRectMake(self.moviePlayer.view.frame.size.width - 400, 640, 350, 60);
        [btn.titleLabel setFont:[UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:20.0]];
        
    }
    else {
        btn.frame = CGRectMake(self.moviePlayer.view.frame.size.width - 250, 200, 200, 30);
        [btn.titleLabel setFont:[UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:10.0]];
        
    }
    
    btn.layer.borderWidth = 4;
    btn.layer.cornerRadius = 12.0;
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"close_Icon.png"]] forState:UIControlStateNormal];
    [self.moviePlayer.view addSubview:closeBtn];
    [closeBtn addTarget:self action:@selector(closeBuyBtn:) forControlEvents:UIControlEventTouchUpInside];
    [closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    
    closeBtn.frame = CGRectMake(btn.frame.origin.x+btn.frame.size.width-20, btn.frame.origin.y-20, 20, 20);
    closeBtn.alpha = 0.0;
    btn.alpha = 0.0;
    [self closeMoreBtn:(UIButton *)[self.view viewWithTag:kMoreCloseTag]];
    [UIView animateWithDuration:0.5 animations:^{
        btn.alpha = 1.0;
        closeBtn.alpha = 1.0;
        
    }];
}

- (void)closeBuyBtn:(UIButton *)closeBtn {
    UIButton *btn = (UIButton *)[self.view viewWithTag:kBuyBtnTag];
    [UIView animateWithDuration:0.5 animations:^{
        btn.alpha = 0;
        closeBtn.alpha = 0;
    }];
    
}

- (void)closeMoreBtn:(UIButton *)closeBtn {
    UIButton *btn = (UIButton *)[self.view viewWithTag:kMoreBtnTag];
    [UIView animateWithDuration:0.5 animations:^{
        btn.alpha = 0;
        closeBtn.alpha = 0;
    }];
}

#pragma mark - Control Bar Methods
- (void)createAdControlBar {
    if (nil == self.controlBarBase) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.controlBarBase = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 100)];
            [self.controlBarBase setImage:[UIImage imageWithData:[self.delegate loadFile:@"ControlBar_Tray.png"]]];
            [self.controlBarBase setContentMode:UIViewContentModeBottom];
        }
        else {
            self.controlBarBase = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 50)];
            [self.controlBarBase setImage:[UIImage imageWithData:[self.delegate loadFile:@"ControlBar_Tray_iPhone.png"]]];
            [self.controlBarBase setContentMode:UIViewContentModeBottom|UIViewContentModeScaleAspectFill];
        }
        [self.moviePlayer.view addSubview:self.controlBarBase];
        [self.moviePlayer.view bringSubviewToFront:self.controlBarBase];
        [self.controlBarBase setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin];
        [self.controlBarBase setUserInteractionEnabled:YES];
        UIButton *galleryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [galleryBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"ControlBar_Gallery.png"]] forState:UIControlStateNormal];
        [galleryBtn setTag:kECADControlBarItemTag+1];
        [galleryBtn addTarget:self action:@selector(controlBarGalleryClicked) forControlEvents:UIControlEventTouchUpInside];
        [self.controlBarBase addSubview:galleryBtn];
        [galleryBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        
        
        CGRect frame = self.controlBarBase.bounds;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            frame.origin.x += 150;
            frame.origin.y += 5;
            frame.size = CGSizeMake(80, 80);
        }else {
            frame.origin.x += 40;
            frame.origin.y += 1;
            frame.size = CGSizeMake(40, 40);
            
        }
        galleryBtn.frame = frame;
        
        UIButton *videoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [videoBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"ControlBar_Video.png"]] forState:UIControlStateNormal];
        [videoBtn setTag:kECADControlBarItemTag+2];
        [videoBtn addTarget:self action:@selector(controlBarVideoClicked) forControlEvents:UIControlEventTouchUpInside];
        [videoBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        
        [self.controlBarBase addSubview:videoBtn];
        
        frame = galleryBtn.frame;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            frame.origin.x += frame.size.width + 20;
        else
            frame.origin.x += frame.size.width + 10;
        
        videoBtn.frame = frame;
        
        UIButton *locatorBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [locatorBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"ControlBar_Locator.png"]] forState:UIControlStateNormal];
        [locatorBtn setTag:kECADControlBarItemTag+3];
        [locatorBtn addTarget:self action:@selector(controlBarLocatorClicked) forControlEvents:UIControlEventTouchUpInside];
        [locatorBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        
        [self.controlBarBase addSubview:locatorBtn];
        
        frame = videoBtn.frame;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            frame.origin.x += frame.size.width + 20;
        else
            frame.origin.x += frame.size.width + 10;
        locatorBtn.frame = frame;
        
        UIButton *fbBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [fbBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"ControlBar_Fb.png"]] forState:UIControlStateNormal];
        [fbBtn setTag:kECADControlBarItemTag+4];
        [fbBtn addTarget:self action:@selector(controlBarFbClicked) forControlEvents:UIControlEventTouchUpInside];
        [fbBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        
        [self.controlBarBase addSubview:fbBtn];
        
        frame = locatorBtn.frame;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            frame.origin.x += frame.size.width + 20;
        else
            frame.origin.x += frame.size.width + 10;
        fbBtn.frame = frame;
        
        UIButton *twitterBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [twitterBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"ControlBar_Twitter.png"]] forState:UIControlStateNormal];
        [twitterBtn setTag:kECADControlBarItemTag+5];
        [twitterBtn addTarget:self action:@selector(controlBarTwitterClicked) forControlEvents:UIControlEventTouchUpInside];
        [twitterBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        
        [self.controlBarBase addSubview:twitterBtn];
        
        frame = fbBtn.frame;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            frame.origin.x += frame.size.width + 20;
        else
            frame.origin.x += frame.size.width + 10;
        twitterBtn.frame = frame;
    }
    CGRect frame = self.controlBarBase.frame;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            frame.origin.y = 768;
            frame.size.width = 1024;
        }else {
            frame.origin.y = self.view.frame.size.width;
            frame.size.width = self.view.frame.size.height;
        }
        self.controlBarBase.frame = frame;
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        frame.origin.y -= 110;
    else
        frame.origin.y -= 60;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.controlBarBase.frame = frame;
        [self.moviePlayer.view bringSubviewToFront:self.controlBarBase];
    }];
    
    
    
}
- (void)createDummyImageView {
    if (nil == self.dummyView) {
        self.dummyView = [[UIView alloc] initWithFrame:self.view.bounds];
        [self.moviePlayer.view addSubview:self.dummyView];
        [self.view bringSubviewToFront:self.dummyView];
        [self.dummyView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        self.dummyView.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
        [self.dummyView setAlpha:0.3];
        [self.dummyView setUserInteractionEnabled:NO];
        [self createLogoImageView];
    }
}

- (void)createLogoImageView {
    if (![self logoImage]) {
        return;
    }
    
    UIImageView *logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 8, 100, 100)];
    [self.dummyView addSubview:logoImageView];
    [self.dummyView bringSubviewToFront:logoImageView];
    [logoImageView setContentMode:UIViewContentModeScaleAspectFit];
    [logoImageView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
    logoImageView.image = self.logoImage;
    logoImageView.hidden = NO;
    
}

- (UIImage *)imageForSkip {
    return [UIImage imageWithData:[self.delegate loadFile:@"dragImage.png"]];//[UIImage imageNamed:@"dragImage.png"];
}

- (CGRect)frameForSkip {
    return CGRectMake(72,97, 95, 125);
}

- (NSInteger)sequenceForSkip {
    return 7;
    
}

- (void)controlBarGalleryClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"controlBarGalleryClicked"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (nil == self.galleryView) {
        [self.moviePlayer pause];
        self.galleryView = [[ECAdControlBarGalleryView alloc] initWithControlBarFormat:kECControlBarGallery withDelegate:self];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            self.galleryView.frame = CGRectInset(self.moviePlayer.view.bounds, 100, 100);
        else
            self.galleryView.frame = CGRectInset(self.moviePlayer.view.bounds, 20, 20);
        
        [self.moviePlayer.view addSubview:self.galleryView];
        [self.galleryView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self.galleryView setBackgroundColor:[UIColor colorWithRed:133.0/255.0 green:195.0/255.0 blue:232.0/255.0 alpha:1.0]];
        [self.galleryView setAlpha:0.0];
        [self createDummyImageView];
        
        self.galleryView.layer.cornerRadius = 20.0;
        self.galleryView.layer.borderWidth = 4.0;
        self.galleryView.layer.borderColor = [UIColor whiteColor].CGColor;
        
        
        
        [self.galleryView initialize];
        [self.view bringSubviewToFront:self.moviePlayer.view];
        [self.moviePlayer.view bringSubviewToFront:self.galleryView];
        
        [UIView animateWithDuration:0.5 animations:^{
            [self.dummyView setBackgroundColor:[UIColor whiteColor]];
            [self.galleryView setAlpha:1.0];
        }];
    }
    else {
        [UIView animateWithDuration:0.5 animations:^{
            [self.galleryView setAlpha:0.0];
        } completion:^(BOOL finished) {
            [self.galleryView removeFromSuperview];
            self.galleryView = nil;
            [self.dummyView removeFromSuperview];
            self.dummyView = nil;
            [self.moviePlayer play];
        }];
        
    }
    
    
}
- (void)controlBarVideoClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"controlBarVideoClicked"];

    if (![self.videoThumbDict count]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Video Gallery Currently not available" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (nil == self.galleryView) {
        [self.moviePlayer pause];
        self.galleryView = [[ECAdControlBarGalleryView alloc] initWithControlBarFormat:kECControlBarVideo withDelegate:self];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            self.galleryView.frame = CGRectInset(self.moviePlayer.view.bounds, 100, 100);
        else
            self.galleryView.frame = CGRectInset(self.moviePlayer.view.bounds, 20, 20);
        [self.moviePlayer.view addSubview:self.galleryView];
        [self.galleryView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self.galleryView setBackgroundColor:[UIColor colorWithRed:133.0/255.0 green:195.0/255.0 blue:232.0/255.0 alpha:1.0]];
        [self.galleryView setAlpha:0.0];
        [self createDummyImageView];
        
        self.galleryView.layer.cornerRadius = 20.0;
        self.galleryView.layer.borderWidth = 4.0;
        self.galleryView.layer.borderColor = [UIColor whiteColor].CGColor;
        
        self.dummyView.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
        [self.dummyView setAlpha:0.3];
        [self.dummyView setUserInteractionEnabled:NO];
        [self.galleryView initialize];
        [self.view bringSubviewToFront:self.moviePlayer.view];
        [self.moviePlayer.view bringSubviewToFront:self.galleryView];
        
        [UIView animateWithDuration:0.5 animations:^{
            [self.dummyView setBackgroundColor:[UIColor whiteColor]];
            [self.galleryView setAlpha:1.0];
        }];
    }
    else {
        [UIView animateWithDuration:0.5 animations:^{
            [self.galleryView setAlpha:0.0];
        } completion:^(BOOL finished) {
            [self.galleryView removeFromSuperview];
            self.galleryView = nil;
            [self.dummyView removeFromSuperview];
            self.dummyView = nil;
            [self.moviePlayer play];
        }];
        
    }
    
    
}
- (void)controlBarLocatorClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"controlBarLocatorClicked"];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (![self.responseDict objectForKey:@"brand"] || [NSNull null] == [self.responseDict objectForKey:@"brand"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Stote Locator Currently not available" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        return;
        
    }
    if (nil == self.galleryView) {
        [self.moviePlayer pause];
        self.galleryView = [[ECAdControlBarGalleryView alloc] initWithControlBarFormat:kECControlBarLocator withDelegate:self];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            self.galleryView.frame = CGRectInset(self.moviePlayer.view.bounds, 100, 100);
        else
            self.galleryView.frame = CGRectInset(self.moviePlayer.view.bounds, 20, 20);
        [self.moviePlayer.view addSubview:self.galleryView];
        [self.galleryView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self.galleryView setBackgroundColor:[UIColor colorWithRed:133.0/255.0 green:195.0/255.0 blue:232.0/255.0 alpha:1.0]];
        [self.galleryView setAlpha:0.0];
        [self createDummyImageView];
        self.galleryView.layer.cornerRadius = 20.0;
        self.galleryView.layer.borderWidth = 4.0;
        self.galleryView.layer.borderColor = [UIColor whiteColor].CGColor;
        
        [self.galleryView initialize];
        [self.view bringSubviewToFront:self.moviePlayer.view];
        [self.moviePlayer.view bringSubviewToFront:self.galleryView];
        
        [UIView animateWithDuration:0.5 animations:^{
            [self.dummyView setBackgroundColor:[UIColor whiteColor]];
            [self.galleryView setAlpha:1.0];
        }];
    }
    else {
        [UIView animateWithDuration:0.5 animations:^{
            [self.galleryView setAlpha:0.0];
        } completion:^(BOOL finished) {
            [self.galleryView removeFromSuperview];
            self.galleryView = nil;
            [self.dummyView removeFromSuperview];
            self.dummyView = nil;
            [self.moviePlayer play];
        }];
        
    }
}
- (void)controlBarFbClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"controlBarFbClicked"];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (nil == self.galleryView) {
        [self.moviePlayer pause];
        self.galleryView = [[ECAdControlBarGalleryView alloc] initWithControlBarFormat:kECControlBarFacebook withDelegate:self];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            self.galleryView.frame = CGRectInset(self.moviePlayer.view.bounds, 100, 100);
        else
            self.galleryView.frame = CGRectInset(self.moviePlayer.view.bounds, 20, 20);
        [self.moviePlayer.view addSubview:self.galleryView];
        [self.galleryView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self.galleryView setBackgroundColor:[UIColor colorWithRed:133.0/255.0 green:195.0/255.0 blue:232.0/255.0 alpha:1.0]];
        [self.galleryView setAlpha:0.0];
        [self createDummyImageView];
        self.galleryView.layer.cornerRadius = 20.0;
        self.galleryView.layer.borderWidth = 4.0;
        self.galleryView.layer.borderColor = [UIColor whiteColor].CGColor;
        
        [self.galleryView initialize];
        [self.view bringSubviewToFront:self.moviePlayer.view];
        [self.moviePlayer.view bringSubviewToFront:self.galleryView];
        
        [UIView animateWithDuration:0.5 animations:^{
            [self.dummyView setBackgroundColor:[UIColor whiteColor]];
            [self.galleryView setAlpha:1.0];
        }];
    }
    else {
        [UIView animateWithDuration:0.5 animations:^{
            [self.galleryView setAlpha:0.0];
        } completion:^(BOOL finished) {
            [self.galleryView removeFromSuperview];
            self.galleryView = nil;
            [self.dummyView removeFromSuperview];
            self.dummyView = nil;
            [self.moviePlayer play];
        }];
        
    }
}
- (void)controlBarTwitterClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"controlBarTwitterClicked"];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (nil == self.galleryView) {
        [self.moviePlayer pause];
        self.galleryView = [[ECAdControlBarGalleryView alloc] initWithControlBarFormat:kECControlBarTwitter withDelegate:self];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            self.galleryView.frame = CGRectInset(self.moviePlayer.view.bounds, 100, 100);
        else
            self.galleryView.frame = CGRectInset(self.moviePlayer.view.bounds, 20, 20);
        [self.moviePlayer.view addSubview:self.galleryView];
        [self.galleryView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self.galleryView setBackgroundColor:[UIColor colorWithRed:133.0/255.0 green:195.0/255.0 blue:232.0/255.0 alpha:1.0]];
        [self.galleryView setAlpha:0.0];
        [self createDummyImageView];
        self.galleryView.layer.cornerRadius = 20.0;
        self.galleryView.layer.borderWidth = 4.0;
        self.galleryView.layer.borderColor = [UIColor whiteColor].CGColor;
        
        [self.galleryView initialize];
        [self.view bringSubviewToFront:self.moviePlayer.view];
        [self.moviePlayer.view bringSubviewToFront:self.galleryView];
        
        [UIView animateWithDuration:0.5 animations:^{
            [self.dummyView setBackgroundColor:[UIColor whiteColor]];
            [self.galleryView setAlpha:1.0];
        }];
    }
    else {
        [UIView animateWithDuration:0.5 animations:^{
            [self.galleryView setAlpha:0.0];
        } completion:^(BOOL finished) {
            [self.galleryView removeFromSuperview];
            self.galleryView = nil;
            [self.dummyView removeFromSuperview];
            self.dummyView = nil;
            [self.moviePlayer play];
        }];
        
    }
}

- (void)controlAdViewClosed {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"controlAdViewClosed"];

    [UIView animateWithDuration:0.5 animations:^{
        [self.galleryView setAlpha:0.0];
    } completion:^(BOOL finished) {
        [self.galleryView removeFromSuperview];
        self.galleryView = nil;
        [self.dummyView removeFromSuperview];
        self.dummyView = nil;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:self.moviePlayer];
        [self.moviePlayer play];
        [self.view bringSubviewToFront:self.closeBtn];
    }];
}

- (void)continueAd {
    [UIView animateWithDuration:0.5 animations:^{
        [self.galleryView setAlpha:0.0];
        [self.surveyView setAlpha:0.0];
    } completion:^(BOOL finished) {
        [self.galleryView removeFromSuperview];
        self.galleryView = nil;
        
        [self.surveyView removeFromSuperview];
        self.surveyView = nil;
        
        [self.dummyView removeFromSuperview];
        self.dummyView = nil;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:self.moviePlayer];
        [self.view bringSubviewToFront:self.closeBtn];
        [self.moviePlayer play];
    }];
}
- (void)smartSkippableInteractionSuccess {
    [UIView animateWithDuration:0.5 animations:^{
        [self.galleryView setAlpha:0.0];
        [self.surveyView setAlpha:0.0];
    } completion:^(BOOL finished) {
        [self.galleryView removeFromSuperview];
        self.galleryView = nil;
        
        [self.surveyView removeFromSuperview];
        self.surveyView = nil;

        [self.dummyView removeFromSuperview];
        self.dummyView = nil;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:self.moviePlayer];
        [self.view bringSubviewToFront:self.closeBtn];
    }];
    AdContinueView *view = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        view = [[AdContinueView alloc] initWithFrame:CGRectInset(self.moviePlayer.view.frame, 100, 200)];
        [view setupView:self];
        [self.moviePlayer.view addSubview:view];

    }
    else {
        view = [[AdContinueView alloc] initWithFrame:CGRectInset(self.moviePlayer.view.frame, 10, 50)];
        [view setupView:self];
        [self.moviePlayer.view addSubview:view];

    }
    [view setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin];
    [view setBackgroundColor:[UIColor colorWithRed:1.0/255.0 green:1.0/255.0 blue:1.0/255.0 alpha:0.3]];
    [view.layer setCornerRadius:12.0];
    [view.layer setBorderColor:[UIColor whiteColor].CGColor];
    [view.layer setBorderWidth:2.0];
    [view setAlpha:0.0];
    
    
    [UIView animateWithDuration:0.5 animations:^{
        view.alpha = 1.0;
    } completion:^(BOOL finished) {
    }];
    
    
}
- (void)smartSkipContinueAd:(AdContinueView *) view{
    [UIView animateWithDuration:0.5 animations:^{
        view.alpha=0.0;
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
        [self.moviePlayer play];
    }];
}
- (void)smartSkipAd:(AdContinueView *)view {
    [UIView animateWithDuration:0.5 animations:^{
        view.alpha=0.0;
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
        [self viewCloseBtnClicked];
    }];
}
#pragma mark - Form Sheet Methods

- (void)formSheetViewDidClose {
    CGRect frame = self.formSheetView.frame;
    frame.origin.y = self.view.frame.size.height;
    [UIView animateWithDuration:0.5 animations:^{
        self.formSheetView.frame = frame;
        self.dummyView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.formSheetView removeFromSuperview];
        [self.dummyView removeFromSuperview];
        self.formSheetView = nil;
        self.dummyView = nil;
        [self.moviePlayer play];
    }];
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.formSheetView layoutFrames];
    if (self.adFormat == kECAdControlBar || self.adFormat == kECAdSmartSkip)
        [self.galleryView showGalleryView];
    
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (self.adFormat == kECVideoPlaylist)
        [self.formSheetView willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    else
        [self.galleryView layoutFrames:toInterfaceOrientation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self.moviePlayer];
    
    [self.moviePlayer stop];
    self.moviePlayer = nil;
    
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self.moviePlayer];
    
    self.moviePlayer = nil;
}
@end
