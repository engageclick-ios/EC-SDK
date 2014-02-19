//
//  ECModalVideoInlineSocialViewController.m
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 6/7/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import "ECModalVideoInlineSocialViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import "ECAdManager.h"
#import "EcAdCustomPlayer.h"

@interface SocialView : UIView
@property (nonatomic, strong) UIButton *iconBtn;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, strong) NSString *linkURL;

- (void)setDescriptionText:(NSString *)text forContent:(BOOL)isFB link:(NSString *)linkURL_;

@end

@implementation SocialView

- (void)setupContent:(id)delegate_ {
    self.delegate = delegate_;
    self.iconBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        self.iconBtn.frame = CGRectMake(0, 0, 50, self.frame.size.height);
    else
        self.iconBtn.frame = CGRectMake(0, 0, 30, self.frame.size.height);
    
    [self addSubview:self.iconBtn];
    [self.iconBtn addTarget:self action:@selector(linkClicked) forControlEvents:UIControlEventTouchUpInside];
    self.descLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.iconBtn.frame.origin.x+self.iconBtn.frame.size.width+5, 0, self.frame.size.width-(self.iconBtn.frame.size.width+5), self.frame.size.height)];
    [self addSubview:self.descLabel];
    [self.descLabel setTextAlignment:NSTextAlignmentLeft];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        [self.descLabel setFont:[UIFont systemFontOfSize:18.0]];
    else
        [self.descLabel setFont:[UIFont systemFontOfSize:12.0]];
    
    [self.descLabel setNumberOfLines:0.0];
    [self.descLabel setAdjustsFontSizeToFitWidth:YES];
    [self.descLabel setTextColor:[UIColor whiteColor]];
    [self.descLabel setBackgroundColor:[UIColor clearColor]];
    [self.descLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self addSubview:self.descLabel];
    [self setBackgroundColor:[UIColor colorWithRed:1.0/255.0 green:1.0/255.0  blue:1.0/255.0  alpha:0.3]];
    
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
}

- (void)setDescriptionText:(NSString *)text forContent:(BOOL)isFB link:(NSString *)linkURL_ {
    self.linkURL = linkURL_;
    self.descLabel.text = text;
    if (isFB)
        [self.iconBtn setImage:[UIImage imageWithData:[[ECAdManager sharedManager] loadFile:@"fb_Icon.png"]] forState:UIControlStateNormal];
    else
        [self.iconBtn setImage:[UIImage imageWithData:[[ECAdManager sharedManager] loadFile:@"twitter_Icon.png"]] forState:UIControlStateNormal];
    
}

- (void)linkClicked {
    [[ECAdManager sharedManager] videoAdLandingPageOpened:self.linkURL];

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.linkURL]];
}

- (void)dealloc {
    self.iconBtn = nil;
    self.linkURL = nil;
    self.descLabel = nil;
    self.delegate = nil;
}
@end

@interface ECModalVideoInlineSocialViewController () {
    NSTimer *flipTimer;
}
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;

@property (nonatomic, strong) NSMutableDictionary *responseDict;

@property (nonatomic, strong) NSMutableDictionary *socialContentDict;
@property (nonatomic, strong) SocialView *socialView;
@property int currentSocialIndex;


@end

@implementation ECModalVideoInlineSocialViewController

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
	// Do any additional setup after loading the view.
    [self.view setBackgroundColor:[UIColor blackColor]];
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.spinner setCenter:self.view.center];
    [self.view addSubview:self.spinner];
    [self.spinner setHidesWhenStopped:YES];
    [self.spinner startAnimating];
    self.spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    self.socialContentDict = [NSMutableDictionary dictionary];
    
    self.currentSocialIndex  = -1;
    if (nil == self.responseDict) {
        self.responseDict = [NSMutableDictionary dictionary];
        [self fetchData];
    }
    else {
        [self fetchSocialFeeds];
        [self setupVideoPlayer];
        [self.view bringSubviewToFront:self.spinner];
    }
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
    
    trimmedStr = [trimmedStr substringWithRange:resultedMatch];
    return trimmedStr;
}
- (void)fetchData {
    //    NSString *path = [NSString stringWithFormat:@"http://api.geonames.org/citiesJSON?north=44.1&south=-9.9&east=-22.4&west=55.2&lang=de&username=demo"];
    if (nil == self.basePath)
        self.basePath = [NSString stringWithFormat:@"http://devefence.engageclick.com/ecadserve/ecvideoFlash?mediaIdExternal=2&mediaSystemId=1&flashFormat=FSALL"];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.basePath]] ;
    
    
    [request setHTTPMethod:@"GET"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        responseString = [self trimResponse:responseString];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        ECLog(@"responseString = %@ and response statusCode = %d",responseString, [httpResponse statusCode]);
        data=[responseString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (responseDictionary)
            self.responseDict = [NSMutableDictionary dictionaryWithDictionary:responseDictionary];
        
        if ([httpResponse statusCode] == 200) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self fetchSocialFeeds];
                [self setupVideoPlayer];
                [self.view bringSubviewToFront:self.spinner];
            });
            
        } else {
        }
    }];
}

- (void)fetchSocialFeeds {
    NSDictionary *data =  [self.responseDict objectForKey:@"socialData"];
    NSArray *keys =[data allKeys];
    NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
    keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
    if (![keys count])
        return;
    
    [keys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        NSDictionary *socialFeed = [data objectForKey:key];
        //[self.socialData addObject:socialFeed];
//        BOOL isTwitter = [[socialFeed objectForKey:@"source"] isEqualToString:@"Twitter"] ? YES : NO;
            [self.socialContentDict setObject:socialFeed forKey:key];
    }];
}

- (void)setupVideoPlayer {
    NSDictionary *data =  [self.responseDict objectForKey:@"data"];

    self.moviePlayer = [[EcAdCustomPlayer alloc] initWithContentURL:[NSURL URLWithString: [data objectForKey:@"media"]]];
    [(EcAdCustomPlayer *)self.moviePlayer setTargetURL:[self.responseDict objectForKey:@"targeturl"]];
    [self.moviePlayer setControlStyle:MPMovieControlStyleNone];
    self.moviePlayer.view.frame = self.view.bounds;
    self.moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:self.moviePlayer.view];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackChanged:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:self.moviePlayer];
    [self.moviePlayer setShouldAutoplay:YES];
    [self.moviePlayer prepareToPlay];
    [self.moviePlayer play];
    [self.spinner stopAnimating];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn setImage:[UIImage imageWithData:[[ECAdManager sharedManager] loadFile:@"black_Close.png"]] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(playbackFinished:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];
    [closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    CGRect rect = self.view.bounds;
    rect.origin.x = rect.size.width - 40;
    rect.origin.y = 5;
    rect.size = CGSizeMake(40, 40);
    closeBtn.frame = rect;
}
- (void)playbackChanged:(MPMoviePlayerController *)player {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.moviePlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self.moviePlayer selector:@selector(play) name:@"AppDidEnterForeground" object:nil];
    
    [self.spinner stopAnimating];
    if (nil == self.socialView) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            self.socialView = [[SocialView alloc] initWithFrame:CGRectMake(0, self.moviePlayer.view.frame.size.height - 60, self.moviePlayer.view.frame.size.width, 60)];
        else
            self.socialView = [[SocialView alloc] initWithFrame:CGRectMake(0, self.moviePlayer.view.frame.size.height - 30, self.moviePlayer.view.frame.size.width, 30)];
        
        [self.socialView setupContent:self];
        [self.moviePlayer.view addSubview:self.socialView];
        [self.moviePlayer.view bringSubviewToFront:self.socialView];
    }
    flipTimer =  [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(verticalFlip) userInfo:nil repeats:YES];
//    [self verticalFlip];
}

- (void)playbackFinished:(MPMoviePlayerController *)player {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if ([self.delegate respondsToSelector:@selector(adVideoDidFinishPlayback)])
        [self.delegate performSelector:@selector(adVideoDidFinishPlayback)];
}

- (void)slideSocialContent {
    if ([self.socialContentDict count]) {

        NSArray *keys =[self.socialContentDict allKeys];
        NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
        keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
        
        if (self.currentSocialIndex == -1)
            self.currentSocialIndex = [[keys objectAtIndex:0] integerValue];
        else {
            int index = [keys indexOfObject:[NSString stringWithFormat:@"%d",self.currentSocialIndex]]+1;
            if (index >= [keys count])
                index = 0;
            self.currentSocialIndex = [[keys objectAtIndex:index] integerValue];
        }
        
        NSDictionary *fbContent = [self.socialContentDict objectForKey:[NSString stringWithFormat:@"%d",self.currentSocialIndex]];
        BOOL isTwitter = [[fbContent objectForKey:@"source"] isEqualToString:@"Twitter"] ? YES : NO;
        NSString *link;
        if (isTwitter) {
            if ([[fbContent objectForKey:@"message"] length])
                link = [self getTwitterLink:[fbContent objectForKey:@"message"]];
        }
        else {
            if ([[fbContent objectForKey:@"clickurl"] length])
                link = [fbContent objectForKey:@"clickurl"];
        }
        [self.socialView setDescriptionText:[NSString stringWithFormat:@"%@: %@",[fbContent objectForKey:@"username"],[fbContent objectForKey:@"message"]] forContent:!isTwitter link:link];
    }
    
}

- (NSString *)getTwitterLink:(NSString *)str {
    NSString *trimmedStr = str;
    NSArray *arrString = [str componentsSeparatedByString:@" "];
    
    for(int i=0; i<arrString.count;i++){
        if([[arrString objectAtIndex:i] rangeOfString:@"http://"].location != NSNotFound) {
            trimmedStr = [arrString objectAtIndex:i];
            break;
        }
    }
    
    return trimmedStr;
}


- (void)verticalFlip{
    CATransition *animation = [CATransition animation];
    animation.delegate = self;
    animation.duration =  0.3f;
    animation.type = kCATransitionPush;
    if (self.ECInlineFormat == kECInlineFormatSocialHorizontal)
        animation.subtype = kCATransitionFromLeft;
    else if (self.ECInlineFormat == kECInlineFormatSocialVertical)
        animation.subtype = kCATransitionFromTop;
    
        
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [[self.socialView layer] addAnimation:animation forKey:@"animation"];
    [self slideSocialContent];
    return;
    
    
    
    [UIView animateWithDuration:1.0 animations:^{
        self.socialView.layer.transform = CATransform3DMakeRotation(M_PI,1.0,0.0,0.0); //flip halfway
    } completion:^(BOOL finished) {
        //        while ([self.socialView.subviews count] > 0)
        //            [[self.socialView.subviews lastObject] removeFromSuperview]; // remove all subviews
        
        [UIView animateWithDuration:1.0 animations:^{
            [self slideSocialContent];
            self.socialView.layer.transform = CATransform3DMakeRotation(M_PI,0.0,0.0,0.0); //
            // self.socialView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
        }];
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
    self.socialView.delegate = nil;
    [self.socialView removeFromSuperview];
    self.socialView = nil;
    self.delegate = nil;
    [flipTimer invalidate];
    flipTimer = nil;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self.moviePlayer];
    self.socialContentDict = nil;
    self.basePath = nil;
    self.responseDict = nil;
    self.socialView = nil;
    self.moviePlayer = nil;
    self.spinner = nil;
}
@end
