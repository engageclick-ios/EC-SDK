//
//  ECModalVideoAdTimeSyncViewController.m
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/15/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import "ECModalVideoAdTimeSyncViewController.h"
#import "ECAdGalleryView.h"
#import "ECAdManager.h"
#import "EcAdCustomPlayer.h"
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>

#define ARTICLE_CONTENT_VIEW_TAG 1000
#define kBannerViewWidth 120

#define kBGColor [UIColor colorWithRed:76.0/255.0 green:76.0/255.0 blue:76.0/255.0 alpha:1.0]

@interface GalleryImageView : UIImageView {
    
}
@end
@interface ECModalVideoAdTimeSyncViewController () {
    BOOL isBannerRevealed;
    int currentImageIndex;
    int currentBannerImageIndex;
}

@property (nonatomic, strong) UIView *baseView;
@property (nonatomic, strong) UIView *bannerView;
@property (nonatomic, strong) ECAdGalleryView *galleryView;
@property (nonatomic, strong) UIView *leftPanelView;
@property (nonatomic, strong) EcAdCustomPlayer *moviePlayer;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIScrollView *bannerScrollView;
@property (nonatomic, strong) UILabel *bannerLabel;
@property (nonatomic, strong) UIButton *bannerBtn;

@property (nonatomic, strong) UIButton *leftBtn;
@property (nonatomic, strong) UIButton *rightBtn;
@property (nonatomic, strong) NSMutableArray *timeSlots;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSMutableDictionary *bannerDict;

@end

@implementation ECModalVideoAdTimeSyncViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (CGFloat )getBannerWidth {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return kBannerViewWidth;
    else
        return 50;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor lightGrayColor]];
    
    //    self.view.backgroundColor = [UIColor grayColor];
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.spinner setCenter:self.view.center];
    [self.view addSubview:self.spinner];
    [self.spinner setHidesWhenStopped:YES];
    [self.spinner startAnimating];
    self.spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    
    self.timeSlots = [NSMutableArray array];
    
    self.imageDict = [NSMutableDictionary dictionary];
    self.bannerDict = [NSMutableDictionary dictionary];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(playbackFinished:)
                                                name:UIApplicationDidEnterBackgroundNotification
                                              object:nil];
}
- (void)viewDidAppear:(BOOL)animated {
    if (self.responseDict == nil)
        [self fetchData];
    else {
        [self fetchGalleryImages];
        [self setupBaseView];
    }
}
- (NSData *)loadFile:(NSString *)name {
    return [[ECAdManager sharedManager] loadFile:name];
}

- (void)fetchData {
    //    NSString *path = [NSString stringWithFormat:@"http://api.geonames.org/citiesJSON?north=44.1&south=-9.9&east=-22.4&west=55.2&lang=de&username=demo"];
   if (nil == self.basePath)
        self.basePath = [NSString stringWithFormat:@"http://devefence.engageclick.com/ecadserve/ecvideoFlash?mediaIdExternal=16&mediaSystemId=1&flashFormat=FSALL"];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.basePath]] ;
    
    
    [request setHTTPMethod:@"GET"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        responseString = [self trimResponse:responseString];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        //ECLog(@"responseString = %@ and response statusCode = %d",responseString, [httpResponse statusCode]);
        data=[responseString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (responseDictionary)
            self.responseDict = [NSMutableDictionary dictionaryWithDictionary:responseDictionary];
        
        if ([httpResponse statusCode] == 200) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self fetchGalleryImages];
                [self setupBaseView];
                
            });
            
        } else {
        }
    }];
}

- (void)setupBaseView {
    self.baseView = [[UIView alloc] initWithFrame:CGRectInset(self.view.bounds, 0, 0)];
    [self.view addSubview: self.baseView];
    [self.baseView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    [self.baseView setBackgroundColor:kBGColor];
    
    [self setupLeftPanelView];
    [self setupVideoPlayer];
    
    //    self.baseView.layer.cornerRadius = 20.0;
    //    self.baseView.layer.borderWidth = 4.0;
    //    self.baseView.layer.borderColor = [UIColor whiteColor].CGColor;
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"black_Close.png"]] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(viewCloseBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.baseView addSubview:closeBtn];
    [closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    CGRect rect = self.baseView.bounds;
    rect.origin.x = rect.size.width - 40;
    rect.origin.y = 5;
    rect.size = CGSizeMake(40, 40);
    closeBtn.frame = rect;
    [self.baseView bringSubviewToFront:closeBtn];
    [self.baseView setClipsToBounds:YES];
    [self.baseView setHidden:YES];
    rect = CGRectZero;
    self.baseView.frame = rect;
    self.baseView.center = self.view.center;
    [self.baseView setHidden:NO];
    [UIView animateWithDuration:0.5 animations:^{
        self.baseView.frame = CGRectInset(self.view.bounds, 0, 0);
    } completion:^(BOOL finished) {
        [self.spinner stopAnimating];
        [self.moviePlayer play];
    }];
}

- (void)viewCloseBtnClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"userAdClose"];

    if ([self.delegate respondsToSelector:@selector(adVideoDidFinishPlayback)])
        [self.delegate performSelector:@selector(adVideoDidFinishPlayback)];
    
}

- (void)setupLeftPanelView {
    self.leftPanelView = [[UIView alloc] initWithFrame:CGRectMake(self.baseView.bounds.origin.x - (self.baseView.frame.size.width - [self getBannerWidth]), self.baseView.bounds.origin.y, self.baseView.frame.size.width, self.baseView.frame.size.height)];
    [self.baseView addSubview:self.leftPanelView];
    [self.leftPanelView setBackgroundColor:kBGColor];
    [self.leftPanelView setAutoresizingMask:UIViewAutoresizingFlexibleHeight |UIViewAutoresizingFlexibleRightMargin];
    UIButton *rightArrow = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.leftPanelView addSubview:rightArrow];
    [rightArrow setImage:[UIImage imageWithData:[self.delegate loadFile:@"RightArrow.png"]] forState:UIControlStateNormal];
    [rightArrow addTarget:self action:@selector(revealFullBanner:) forControlEvents:UIControlEventTouchUpInside];
    
    [rightArrow setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    CGRect rect = self.leftPanelView.bounds;
    rect.origin.x = rect.size.width - 40;
    rect.origin.y = 5;
    rect.size = CGSizeMake(40, 20);
    rightArrow.frame = rect;
    
    
    self.bannerView = [[UIView alloc] initWithFrame:CGRectMake(self.leftPanelView.frame.size.width -[self getBannerWidth], 0, [self getBannerWidth], self.leftPanelView.frame.size.height)];
    [self.bannerView setAutoresizingMask:UIViewAutoresizingFlexibleHeight |UIViewAutoresizingFlexibleLeftMargin];
    [self.leftPanelView addSubview:self.bannerView];
    [self.bannerView setBackgroundColor:kBGColor];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        self.bannerScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 20, self.bannerView.frame.size.width, 305)];
    else
        self.bannerScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 20, self.bannerView.frame.size.width, 150)];
    
    [self.bannerView addSubview:self.bannerScrollView];
    [self.bannerScrollView setBackgroundColor:kBGColor];
    [self.bannerScrollView setScrollEnabled:NO];
    
    self.bannerLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, self.bannerScrollView.frame.size.height, self.bannerScrollView.frame.size.width-2, self.bannerView.frame.size.height - self.bannerScrollView.frame.size.height-100)];
    [self.bannerLabel setTextColor:[UIColor whiteColor]];
    [self.bannerLabel setBackgroundColor:[UIColor clearColor]];
    self.bannerLabel.textAlignment = NSTextAlignmentCenter;
    [self.bannerView addSubview: self.bannerLabel];
    NSDictionary *data =  [self.responseDict objectForKey:@"data"];
    NSString *baseURL = [self.responseDict objectForKey:@"apiserver"];
    if (![baseURL length])
        return;
    NSArray *imagesArray = [data objectForKey:@"fois"];
    NSDictionary *slots = [data objectForKey:@"foidata"];
    NSString *desc =    [[slots objectForKey:[imagesArray objectAtIndex:0]] objectForKey:@"desc"];
    self.bannerLabel.text = desc;//@"DIAGONAL SEQUIN PANEL CHEMISE DRESS\n$199.50 $159.99\ntake an additional 40% off. discount at checkout.";
    self.bannerLabel.numberOfLines = 0;
    UIFont *font = [UIFont fontWithName:@"Georgia-Bold" size:20.0];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        font = [UIFont systemFontOfSize:8.0];
        [self.bannerLabel setAdjustsFontSizeToFitWidth:YES];
        self.bannerLabel.frame = CGRectMake(2, self.bannerScrollView.frame.origin.y+ self.bannerScrollView.frame.size.height, self.bannerScrollView.frame.size.width-2, self.bannerView.frame.size.height - self.bannerScrollView.frame.size.height-70);
        
    }
    [self.bannerLabel setFont:font];
    
    
    [self.leftPanelView bringSubviewToFront:rightArrow];
    
    self.bannerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.bannerBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"Buynow.png"]] forState:UIControlStateNormal];
    [self.bannerBtn addTarget:self action:@selector(bannerBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        self.bannerBtn.frame = CGRectMake(0, self.bannerLabel.frame.origin.y + self.bannerLabel.frame.size.height, 50,50);
    else
        self.bannerBtn.frame = CGRectMake(0, self.bannerLabel.frame.origin.y + self.bannerLabel.frame.size.height, self.bannerLabel.frame.size.width, 100);
    
    [self.bannerView addSubview:self.bannerBtn];
    
    
    self.galleryView = [[ECAdGalleryView alloc] initWithDelegate:self];
    [self.galleryView setGalleryType:kECAdGalleryTypeTimeSync];
    [self.leftPanelView addSubview:self.galleryView];
    self.galleryView.frame = CGRectMake(0, 0, self.leftPanelView.frame.size.width - self.bannerView.frame.size.width, self.leftPanelView.frame.size.height);
    [self.galleryView setBackgroundColor:[UIColor lightGrayColor]];
    
    
    self.leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.leftBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"LeftArrow.png"]] forState:UIControlStateNormal];
    [self.leftBtn addTarget:self action:@selector(leftBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.leftPanelView addSubview:self.leftBtn];
    
    CGRect frame = self.galleryView.bounds;
    frame.size = CGSizeMake(30, 30);
    frame.origin.y = (self.galleryView.frame.size.height/2) - (frame.size.height/2);
    self.leftBtn.frame = frame;
    self.leftBtn.enabled = NO;
    self.rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rightBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"RightArrow.png"]] forState:UIControlStateNormal];
    [self.rightBtn addTarget:self action:@selector(rightBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    frame.origin.x = self.galleryView.frame.size.width - (frame.size.width);
    self.rightBtn.frame  =frame;
    
    [self.leftPanelView addSubview:self.rightBtn];
    
    self.rightBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    self.leftBtn.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    
    /*
    UIButton *newArrivalBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [newArrivalBtn setTitle:@"New Arrivals" forState:UIControlStateNormal];
    [newArrivalBtn setBackgroundColor:[UIColor grayColor]];
    [self.leftPanelView addSubview:newArrivalBtn];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        newArrivalBtn.frame = CGRectMake(30, self.galleryView.frame.size.height - 100, 250, 60);
    else
        newArrivalBtn.frame = CGRectMake(self.leftPanelView.frame.size.width/2 - 50, self.galleryView.frame.size.height - 30, 100, 30);
    
    newArrivalBtn.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
    [newArrivalBtn addTarget:self action:@selector(newArrivalsClicked) forControlEvents:UIControlEventTouchUpInside];
    font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:26.0];
    
    UIButton *bestSeller = [UIButton buttonWithType:UIButtonTypeCustom];
    [bestSeller setTitle:@"Best Sellers" forState:UIControlStateNormal];
    [newArrivalBtn.titleLabel setFont:font];
    
    [bestSeller setBackgroundColor:[UIColor grayColor]];
    [bestSeller addTarget:self action:@selector(bestSellersClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.leftPanelView addSubview:bestSeller];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        bestSeller.frame = CGRectMake(newArrivalBtn.frame.origin.x + newArrivalBtn.frame.size.width + 50, self.galleryView.frame.size.height - 100, 250, 60);
    else {
        bestSeller.frame = CGRectMake(newArrivalBtn.frame.origin.x + newArrivalBtn.frame.size.width +30, newArrivalBtn.frame.origin.y, 100, 30);
        font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:12.0];
        
    }
    [bestSeller.titleLabel setFont:font];
    [newArrivalBtn.titleLabel setFont:font];
    bestSeller.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;*/
    [self loadBannerScrollViewContents];
    currentBannerImageIndex = 0;
    [self triggerPlaybackTimer];
    //    [self.galleryView setupGallery];
}

- (void)triggerPlaybackTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updatePlaybackProgressFromTimer:) userInfo:nil repeats:YES];
}

- (void) updatePlaybackProgressFromTimer:(NSTimer *)timer {
    
    if (([UIApplication sharedApplication].applicationState == UIApplicationStateActive) && (self.moviePlayer.playbackState == MPMoviePlaybackStatePlaying)) {
        
        //  NSTimeInterval progress = self.moviePlayer.currentPlaybackTime;
        if ( currentBannerImageIndex+1 >= [self.timeSlots count] /*&& currentBannerImageIndex >=0*/) {
            [self.timer invalidate];
            self.timer = nil;
            return;
        }
        
        float currentTime = ceil(self.moviePlayer.currentPlaybackTime);
        //        if (currentBannerImageIndex == -1) {
        //            float timeToCheck = [[self.timeSlots objectAtIndex:0] doubleValue]/1000;
        //            if (currentTime >= timeToCheck) {
        //                currentBannerImageIndex ++;
        //                [self scrollBanner];
        //            }
        //        }
        //        else {
        float playerTimer = [[self.timeSlots objectAtIndex:currentBannerImageIndex+1] doubleValue]/1000;
        if (currentTime >= playerTimer) {
            currentBannerImageIndex ++;
            if (currentBannerImageIndex>= [self.timeSlots count]) {
                [self.timer invalidate];
                self.timer = nil;
            }
            else {
                [self scrollBanner];
            }
            
        }
        //      }
        
        
        
        /*
         NSString *currentObj = [self.timeSlots objectAtIndex:currentBannerImageIndex];
         NSTimeInterval currentSlot = ([currentObj doubleValue]/1000);
         
         NSString *prevObj = [self.timeSlots objectAtIndex:currentBannerImageIndex-1];
         NSTimeInterval prevSlot = ([prevObj doubleValue]/1000);
         
         if (progress >= prevSlot) {
         if (progress >= currentSlot) {
         ECLog(@"Current Time: %f  Slot Time: %f index: %d",progress,currentSlot,currentBannerImageIndex);
         [self scrollBanner];
         currentBannerImageIndex ++;
         }
         }*/
    }
}
- (void)scrollBanner {
    NSDictionary *data =  [self.responseDict objectForKey:@"data"];
    NSString *baseURL = [self.responseDict objectForKey:@"apiserver"];
    if (![baseURL length])
        return;
    NSArray *imagesArray = [data objectForKey:@"fois"];
    NSDictionary *slots = [data objectForKey:@"foidata"];
    if (currentBannerImageIndex >= [imagesArray count]) {
        [self.timer invalidate];
        self.timer = nil;
        return;
    }
    NSString *desc =    [[slots objectForKey:[imagesArray objectAtIndex:currentBannerImageIndex]] objectForKey:@"desc"];
    
    [UIView animateWithDuration:2.0 animations:^{
        self.bannerLabel.text = desc;
        [self.bannerScrollView setContentOffset:CGPointMake(0, currentBannerImageIndex * self.bannerScrollView.frame.size.height) animated:NO];
    }];
    
}
- (void)loadBannerScrollViewContents {
    CGRect frame = self.bannerScrollView.bounds;
    for (int i=0; i <[self.timeSlots count]; i++) {
        GalleryImageView *imageView = [[GalleryImageView alloc] initWithFrame:frame];
        [imageView setBackgroundColor:[UIColor clearColor]];
        [self.bannerScrollView addSubview:imageView];
        [imageView setTag:ARTICLE_CONTENT_VIEW_TAG + i];
        [imageView setContentMode:UIViewContentModeScaleAspectFit];
        if ([self.bannerDict objectForKey:[NSString stringWithFormat:@"%d",i]])
            imageView.image = [self.bannerDict objectForKey:[NSString stringWithFormat:@"%d",i]];
        //        [imageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Banner%d.jpg",i]]];
        frame.origin.y += frame.size.height;
    }
    [self.bannerScrollView setContentSize:CGSizeMake(self.bannerScrollView.frame.size.width, 4*self.bannerScrollView.frame.size.height)];
    [self.bannerScrollView setPagingEnabled:YES];
    [self.bannerScrollView setShowsVerticalScrollIndicator:NO];
}

- (void)newArrivalsClicked {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.calvinklein.com/family/index.jsp?categoryId=3249851"]];
}
- (void)bestSellersClicked {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.calvinklein.com/family/index.jsp?categoryId=11688592"]];
    
}
- (void)toggleDirectionBtn {
    NSMutableDictionary *imageDict = self.imageDict;
    
    if (currentImageIndex >= [imageDict count]-1) {
        self.rightBtn.enabled = NO;
    }
    else
        self.rightBtn.enabled = YES;
    
    if (currentImageIndex < 0) {
        self.leftBtn.enabled = NO;
    }
    else
        self.leftBtn.enabled = YES;
}
- (void)leftBtnClicked {
    currentImageIndex = [self.galleryView getPageIndex];
    if (currentImageIndex <= 0) {
        self.leftBtn.enabled = NO;
        self.rightBtn.enabled = YES;
        return;
    }
    currentImageIndex --;
    [self toggleDirectionBtn];
    
    [self.galleryView moveToOffset:CGPointMake(currentImageIndex*self.galleryView.frame.size.width, 0)];
}
- (void)rightBtnClicked {
    NSMutableDictionary *imageDict = self.imageDict;
    currentImageIndex = [self.galleryView getPageIndex];
    if (currentImageIndex >= imageDict.count-1) {
        self.leftBtn.enabled = YES;
        self.rightBtn.enabled = NO;
        return;
    }
    
    currentImageIndex ++;
    [self toggleDirectionBtn];
    
    
    
    [self.galleryView moveToOffset:CGPointMake(currentImageIndex*self.galleryView.frame.size.width, 0)];
    
}

- (void)scrollViewDidEndDecelerating {
    currentImageIndex = [self.galleryView getPageIndex];
    [self toggleDirectionBtn];
    
}
- (NSMutableDictionary *)getImageDict {
    return self.imageDict;
}
- (void)bannerBtnClicked:(UIButton *)button {
    CGFloat pageWidth = self.bannerScrollView.frame.size.height;
	int pageIndex = floor((self.bannerScrollView.contentOffset.y - pageWidth / 2) / pageWidth) + 2;
    if (pageIndex == 0)
        pageIndex = 1;
    
    
    NSDictionary *data =  [self.responseDict objectForKey:@"data"];
    NSString *baseURL = [self.responseDict objectForKey:@"apiserver"];
    if (![baseURL length])
        return;
    NSArray *imagesArray = [data objectForKey:@"fois"];
    NSDictionary *slots = [data objectForKey:@"foidata"];
    NSString *url =    [[slots objectForKey:[imagesArray objectAtIndex:pageIndex]] objectForKey:@"framelink"];
    [[ECAdManager sharedManager] videoAdLandingPageOpened:[NSURL URLWithString:url]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (void)revealFullBanner:(UIButton *)button {
    [self.moviePlayer pause];
    CGRect rect = self.leftPanelView.frame;
    rect.origin.x = 0;
    rect.size = self.baseView.frame.size;
    [self.baseView bringSubviewToFront:self.leftPanelView];
    [UIView animateWithDuration:0.5 animations:^{
        self.leftPanelView.frame = rect;
        [self layoutFrames:self.interfaceOrientation];
        
    } completion:^(BOOL finished) {
        [button setImage:[UIImage imageWithData:[self.delegate loadFile:@"LeftArrow.png"]] forState:UIControlStateNormal];
        [button removeTarget:self action:@selector(revealFullBanner:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:@selector(hideFullBanner:) forControlEvents:UIControlEventTouchUpInside];
        isBannerRevealed = YES;
        
    }];
}

- (void)hideFullBanner:(UIButton *)button {
    CGRect rect = self.leftPanelView.frame;
    rect.origin.x = self.baseView.bounds.origin.x - (self.baseView.frame.size.width - [self getBannerWidth]);
    rect.size = self.baseView.frame.size;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.leftPanelView.frame = rect;
        [self layoutFrames:self.interfaceOrientation];
        
    } completion:^(BOOL finished) {
        [self.moviePlayer play];
        [button setImage:[UIImage imageWithData:[self.delegate loadFile:@"RightArrow.png"]] forState:UIControlStateNormal];
        [button removeTarget:self action:@selector(hideFullBanner:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:@selector(revealFullBanner:) forControlEvents:UIControlEventTouchUpInside];
        isBannerRevealed = NO;
    }];
}

- (void)setupVideoPlayer {
    [[NSNotificationCenter defaultCenter] addObserver:self.moviePlayer selector:@selector(play) name:@"AppDidEnterForeground" object:nil];
    
    NSDictionary *data =  [self.responseDict objectForKey:@"data"];
    self.moviePlayer = [[EcAdCustomPlayer alloc] initWithContentURL:[NSURL URLWithString:[data objectForKey:@"media"]]];
    [(EcAdCustomPlayer *)self.moviePlayer setTargetURL:[self.responseDict objectForKey:@"targeturl"]];
    self.moviePlayer.view.frame = CGRectMake([self getBannerWidth], 0, self.baseView.frame.size.width - [self getBannerWidth] , self.baseView.frame.size.height);
    [self.moviePlayer setControlStyle:MPMovieControlStyleNone];
    [self.baseView addSubview:self.moviePlayer.view];
    self.moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.moviePlayer setShouldAutoplay:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.moviePlayer];
}

- (void)playbackFinished:(MPMoviePlayerController *)player {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if ([self.delegate respondsToSelector:@selector(adVideoDidFinishPlayback)])
        [self.delegate performSelector:@selector(adVideoDidFinishPlayback)];
}


- (void)fetchGalleryImages {
    NSDictionary *data =  [self.responseDict objectForKey:@"data"];
    NSString *baseURL = [self.responseDict objectForKey:@"apiserver"];
    if (![baseURL length])
        return;
    NSArray *imagesArray = [data objectForKey:@"fois"];
    NSDictionary *slots = [data objectForKey:@"foidata"];
    
    
    [imagesArray enumerateObjectsUsingBlock:^(NSString *imgUrl, NSUInteger idx, BOOL *stop) {
        NSDictionary *dict = [slots objectForKey:imgUrl];
        double time = [[dict objectForKey:@"displayTime"] doubleValue];
        [self.timeSlots addObject:[NSNumber numberWithDouble:time]];
        NSString *imageURL = [baseURL stringByAppendingString:imgUrl];
        [self downloadGalleryImages:imageURL forIndexPath:idx];
        [self downloadBannerImage:[dict objectForKey:@"picture"] forIndexPath:idx];

    }];
}
- (void)downloadBannerImage:(NSString *)urlStr forIndexPath:(int)index {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlStr]] ;
    
    
    [request setHTTPMethod:@"GET"];
    //	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if ([httpResponse statusCode] == 200) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                UIImage *image = [UIImage imageWithData:data];
                if (image) {
                    [self.bannerDict setObject:[UIImage imageWithData:data] forKey:[NSString stringWithFormat:@"%d",index]];
                    UIImageView *imgV = (UIImageView *)[self.bannerScrollView viewWithTag:ARTICLE_CONTENT_VIEW_TAG+index];
                    if ([imgV isKindOfClass:[UIImageView class]])
                        [imgV setImage:image];
                }
            });
        } else {
        }
    }];
    
}
- (NSString *)trimResponse:(NSString *)response {
    NSString *trimmedStr = [[response componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    
    NSRange urlStart = [trimmedStr rangeOfString: @"{"];
    NSRange urlEnd = [trimmedStr rangeOfString: @"};"];
    NSRange resultedMatch = NSMakeRange(urlStart.location, urlEnd.location - urlStart.location + urlEnd.length-1);
    
    trimmedStr = [trimmedStr substringWithRange:resultedMatch];
    return trimmedStr;
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
                
                NSDictionary *data =  [self.responseDict objectForKey:@"data"];
                NSString *baseURL = [self.responseDict objectForKey:@"apiserver"];
                if (![baseURL length])
                    return;
                NSArray *imagesArray = [data objectForKey:@"fois"];
                
                if (self.imageDict.count == imagesArray.count)
                    [self.galleryView setupGallery];
                
                
            });
        } else {
        }
    }];
    
}

- (BOOL)shouldAutorotate{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return YES;
    }
    else {
        return self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight;
    }
}

-(NSUInteger)supportedInterfaceOrientations{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    else
        return UIInterfaceOrientationMaskLandscape;
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return self.interfaceOrientation;
    }
    else
        return UIInterfaceOrientationLandscapeLeft;
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return YES;
    else
        return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self layoutFrames:toInterfaceOrientation];
    
}

- (void)layoutFrames:(UIInterfaceOrientation)toInterfaceOrientation {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        return;
    CGRect rect = self.leftPanelView.frame;
    if (isBannerRevealed) {
        rect.size = self.baseView.frame.size;
        self.leftPanelView.frame = rect;
    }
    
    rect = self.bannerScrollView.frame;
    rect.size.height = 305;//self.bannerView.frame.size.height - 200;
    self.bannerScrollView.frame = rect;
    
    self.bannerLabel.frame = CGRectMake(2, self.bannerScrollView.frame.size.height, self.bannerScrollView.frame.size.width-2, self.bannerView.frame.size.height - self.bannerScrollView.frame.size.height-100);
    
    self.bannerBtn.frame = CGRectMake(0, self.bannerLabel.frame.origin.y + self.bannerLabel.frame.size.height, self.bannerLabel.frame.size.width, 100);
    
    self.galleryView.frame = CGRectMake(0, 0, self.leftPanelView.frame.size.width - self.bannerView.frame.size.width, self.leftPanelView.frame.size.height);
    
    [self.galleryView willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:0];
    
    NSArray *subViews = [self.bannerScrollView subviews];
	for (id object in subViews) {
		if ([object isKindOfClass:[GalleryImageView class]]) {
			GalleryImageView *contentView = (GalleryImageView *)object;
			CGRect frame = contentView.frame;
			frame.origin.y = (contentView.tag - ARTICLE_CONTENT_VIEW_TAG)*self.bannerScrollView.frame.size.height;
			frame.size = self.bannerScrollView.frame.size;
			contentView.frame = frame;
		}
	}
    if (currentBannerImageIndex >= [self.timeSlots count])
        currentBannerImageIndex = [self.timeSlots count]-1;
    
    [self.bannerScrollView setContentSize:CGSizeMake(self.bannerScrollView.frame.size.width,4* self.bannerScrollView.frame.size.height)];
    [self.bannerScrollView setContentOffset:CGPointMake(0,currentBannerImageIndex*self.bannerScrollView.frame.size.height) animated:NO];
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
    [self.timer invalidate];
    self.timer = nil;
    
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self.moviePlayer];
    
    self.moviePlayer = nil;
}

@end
