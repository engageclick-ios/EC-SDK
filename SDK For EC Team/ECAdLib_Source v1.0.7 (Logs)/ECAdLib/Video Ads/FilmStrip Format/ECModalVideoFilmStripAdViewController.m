//
//  ECModalVideoFilmStripAdViewController.m
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/16/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import "ECModalVideoFilmStripAdViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import "ECAdManager.h"
#import "EcAdCustomPlayer.h"

#define kGalleryImageViewTag 9000
#define kGallerySocialImageViewTag 90000

#pragma mark - GalleryImageView

typedef enum
{
    kECAdFilmStripFormatGallery,
    kECAdFilmStripFormatSocial,
} kECAdFilmStripFormat;

@interface FilmStripGalleryImageView : UIImageView {
    BOOL isBottomVisible;
}
@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, strong) UILabel *bottomView;
@property (nonatomic) kECAdFilmStripFormat filmStripFormat;
- (void)setupGalleryView;
- (id)initWithDelegate:(id)delegate_;
@end

@implementation FilmStripGalleryImageView

- (id)initWithDelegate:(id)delegate_ {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.delegate = delegate_;
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor blackColor];
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)setFBContentViewForContent:(NSDictionary *)fbContent {
    [self setupGalleryView];
    self.image =  [[self.delegate socialImages ] objectForKey:[fbContent objectForKey:@"picture"]];
    
    self.bottomView.text = [fbContent objectForKey:@"message"];
}

- (void)setTwitterContentViewForContent:(NSDictionary *)tweetDict {
    [self setupGalleryView];
    self.image =  [[self.delegate socialImages ] objectForKey:[tweetDict objectForKey:@"iconurl"]];
    
    self.bottomView.text = [tweetDict objectForKey:@"message"];
    
}
- (void)setupGalleryView {
    if (nil == self.bottomView) {
        self.bottomView = [[UILabel alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 120, self.bounds.size.width, 120)];
        [self.bottomView setBackgroundColor:[UIColor colorWithRed:1.0/255.0 green:1.0/255.0 blue:1.0/255.0 alpha:0.3]];
        [self addSubview:self.bottomView];
        [self.bottomView setTextAlignment:NSTextAlignmentCenter];
        [self.bottomView setTextColor:[UIColor whiteColor]];
        [self.bottomView setNumberOfLines:0];
        [self.bottomView setContentMode:UIViewContentModeTop];
        [self.bottomView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        UIFont  *font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:18];
        [self.bottomView setFont:font];
        
    }
    
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.filmStripFormat == kECAdFilmStripFormatGallery) {
        if ([self.delegate respondsToSelector:@selector(filmStrimGalleryViewDidselectItem:)])
            [self.delegate performSelector:@selector(filmStrimGalleryViewDidselectItem:) withObject:self];
    }
    else {
        [super touchesEnded:touches withEvent:event];
        return;
        CGRect rect = self.bottomView.frame;
        if (isBottomVisible) {
            rect.origin.y = self.frame.size.height - 60;
        }
        else {
            rect.origin.y = self.frame.size.height - 120;
        }
        
        isBottomVisible = !isBottomVisible;
        
        [UIView animateWithDuration:0.5 animations:^{
            self.bottomView.frame = rect;
        }];
    }
}

@end


#pragma mark - GalleryScrollView
@interface GalleryScrollView : UIScrollView {
    
}
@property (nonatomic, assign) id scrollDelegate;
@property (nonatomic, strong) NSTimer *timer;

- (void)setupGalleryView;
- (id)initWithDelegate:(id)delegate_;
- (void)relayoutGallery;

@end
@implementation GalleryScrollView
- (id)initWithDelegate:(id)delegate_ {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.scrollDelegate = delegate_;
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}


- (void)setupGalleryView {
    int padding = 5;
    for (int i = 0 ; i < [self.scrollDelegate getImageDict].count ; i++) {
        //        GalleryImageView *view = [[GalleryImageView alloc] initWithDelegate:self.scrollDelegate ];
        FilmStripGalleryImageView *view = [[FilmStripGalleryImageView alloc] initWithDelegate:self.scrollDelegate];
        [view setFilmStripFormat:kECAdFilmStripFormatGallery];
        view.frame = CGRectMake(padding, 0, 200, self.bounds.size.height);
        [view setTag:kGalleryImageViewTag+i];
        [self addSubview:view];
        [view setImage:[[self.scrollDelegate getImageDict] objectForKey:[NSString stringWithFormat:@"%d",i]]];
        //        [view setupGalleryView];
        padding += 220;
    }
    self.contentSize = CGSizeMake(padding, self.frame.size.height);
    self.showsHorizontalScrollIndicator = NO;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(startSliding) userInfo:nil repeats:YES];
}

- (void)relayoutGallery {
    NSArray *subViews = [self subviews];
    int padding = 5;
	for (id object in subViews) {
		if ([object isKindOfClass:[FilmStripGalleryImageView class]]) {
			FilmStripGalleryImageView *contentView = (FilmStripGalleryImageView *)object;
            contentView.frame = CGRectMake(padding, 0, 200, self.bounds.size.height);
            padding += 220;
		}
	}
    self.contentSize = CGSizeMake(padding, self.frame.size.height);
}

- (void)startSliding {
    if (nil == self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(startSliding) userInfo:nil repeats:YES];
        return;
    }
    CGPoint offset = self.contentOffset;
    if (offset.x >= self.contentSize.width - self.frame.size.width)
        offset.x = 0;
    offset.x += 1.0;
    self.contentOffset = offset;
    return;
    [UIView animateWithDuration:0.3 animations:^{
        self.contentOffset = offset;
    }];
}
- (void)stopSliding {
    [self.timer invalidate];
    self.timer = nil;
}
@end

#pragma mark - Pulldown View

@interface PulldownView : UIButton {
    BOOL isDragging;
    UIImageView *animationImage;
    BOOL isRotating;
    
}
- (void)animateImage;

@property (nonatomic, assign) id delegate;
@property (nonatomic) CGRect home;
@end

@implementation PulldownView
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    isDragging = NO;
    
}

- (void)setAnimationFrame {
    animationImage.frame = self.bounds;
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state {
    [super setImage:nil forState:state];
    if (animationImage == nil) {
        animationImage = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:animationImage];
        [animationImage setContentMode:UIViewContentModeScaleAspectFit];
    }
    if (image)
        [animationImage setImage:image];
    else {
        [self rotateImage];
    }
}

- (void)rotateImage {
    isRotating = YES;
    [UIView animateWithDuration:0.5 animations:^{
        animationImage.layer.anchorPoint = CGPointMake(0.5f, 0.0f);
        animationImage.transform =CGAffineTransformMakeRotation(0.5*M_PI);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 animations:^{
            animationImage.layer.anchorPoint = CGPointMake(0.5f, 0.0f);
            animationImage.transform =CGAffineTransformMakeRotation(-0.5*M_PI);
        } completion:^(BOOL finished) {
            isRotating = NO;
            [self animateImage];
        }];
    }];
    
}
- (void)animateImage {
    [self animateLeft];
}

- (void)animateLeft {
    if (isRotating)
        return;
    [UIView animateWithDuration:1.0 animations:^{
        animationImage.layer.anchorPoint = CGPointMake(0.5f, 0.0f);
        animationImage.transform =CGAffineTransformMakeRotation(0.1*M_PI);
    } completion:^(BOOL finished) {
        [self animateRight];
    }];
}

- (void)animateRight {
    if (isRotating)
        return;
    
    [UIView animateWithDuration:1.0 animations:^{
        animationImage.layer.anchorPoint = CGPointMake(0.5f, 0.0f);
        animationImage.transform =CGAffineTransformMakeRotation(-0.1*M_PI);
    } completion:^(BOOL finished) {
        [self animateLeft];
    }];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    isDragging = YES;
    CGPoint newTouchLocation = [[touches anyObject] locationInView:self];
    CGPoint newTouch = [self convertPoint:newTouchLocation toView:[(UIViewController *)self.delegate view]];
    CGRect rect = self.frame;
    rect.origin.y = newTouch.y;
    self.frame = rect;
    if ([self.delegate respondsToSelector:@selector(pullDownViewMoved:)]) {
        [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"socialViewPulledDown"];

        [(ECModalVideoFilmStripAdViewController *)self.delegate pullDownViewMoved:newTouch];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    
    if (isDragging) {
        [UIView animateWithDuration:0.3 animations:^{
            self.frame = self.home;
        }];
        if ([self.delegate respondsToSelector:@selector(pulDownViewCanceled:)]) {
            [(ECModalVideoFilmStripAdViewController *)self.delegate pulDownViewCanceled:CGPointZero];
        }
    }
    
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    if (isDragging) {
        [UIView animateWithDuration:0.3 animations:^{
            self.frame = self.home;
        }];
        if ([self.delegate respondsToSelector:@selector(pullDownViewEnded:)]) {
            [(ECModalVideoFilmStripAdViewController *)self.delegate pullDownViewEnded:CGPointZero];
        }
    }
}
@end

#pragma mark - ECModalVideoFilmStripAdViewController

@interface ECModalVideoFilmStripAdViewController () {
    int currentImageIndex;
    BOOL isSocialVisible;
    
}
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) GalleryScrollView *galleryScrollView;
@property (nonatomic, strong) UITableView *socialTableView;
@property (nonatomic, strong) PulldownView *pullDownBtn;
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) UIImageView *fullImage;


@end

@implementation ECModalVideoFilmStripAdViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSMutableDictionary *)getImageDict {
    return self.imageDict;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.spinner setCenter:self.view.center];
    [self.view addSubview:self.spinner];
    [self.spinner setHidesWhenStopped:YES];
    [self.spinner startAnimating];
    self.spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    
    
    self.imageDict = [NSMutableDictionary dictionary];
    self.socialImages = [NSMutableDictionary dictionary];
    self.socialFBImages = [NSMutableDictionary dictionary];
    self.fbContentDict = [NSMutableDictionary dictionary];
    self.twitterContentDict = [NSMutableDictionary dictionary];
    if (nil == self.responseDict)
        [self fetchData];
    else {
        [self fetchGalleryImages];
        [self setupVideoPlayer];
    }

    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(playbackFinished:)
                                                name:UIApplicationDidEnterBackgroundNotification
                                              object:nil];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
        
        ECLog(@"responseString = %@ and response statusCode = %d",responseString, [httpResponse statusCode]);
        data=[responseString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (responseDictionary)
            self.responseDict = [NSMutableDictionary dictionaryWithDictionary:responseDictionary];
        
        if ([httpResponse statusCode] == 200) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                //                [self setupVideoPlayerForiPad];
                //                [self setupGalleryTableViewForiPad];
                //                [self setupSocialViewForiPad];
                //                [self layoutTableViewFrame:self.interfaceOrientation];
                //                [self.view bringSubviewToFront:self.spinner];
                [self fetchGalleryImages];
                [self setupVideoPlayer];
                
            });
            
        } else {
        }
    }];
}

- (void)setupVideoPlayer {
    [[NSNotificationCenter defaultCenter] addObserver:self.moviePlayer selector:@selector(play) name:@"AppDidEnterForeground" object:nil];
    
    NSDictionary *data =  [self.responseDict objectForKey:@"data"];
    self.moviePlayer = [[EcAdCustomPlayer alloc] initWithContentURL:[NSURL URLWithString: [data objectForKey:@"media"]]];
    [(EcAdCustomPlayer *)self.moviePlayer setTargetURL:[self.responseDict objectForKey:@"targeturl"]];

    [self.moviePlayer setControlStyle:MPMovieControlStyleNone];
    self.moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
        self.moviePlayer.view.frame = CGRectMake(0, 0, self.view.frame.size.height , self.view.frame.size.width-200);
    else
        self.moviePlayer.view.frame = CGRectMake(0, 0, self.view.frame.size.width , self.view.frame.size.height-200);
    
    
    [self.view addSubview:self.moviePlayer.view];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.moviePlayer];
    [self.moviePlayer prepareToPlay];
    [self.moviePlayer play];
    [self.spinner stopAnimating];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"black_Close.png"]] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(playbackFinished:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];
    [closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    CGRect rect = self.view.bounds;
    rect.origin.x = rect.size.width - 40;
    rect.origin.y = 5;
    rect.size = CGSizeMake(40, 40);
    closeBtn.frame = rect;
    
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
    
    
    [imagesArray enumerateObjectsUsingBlock:^(NSString *imgUrl, NSUInteger idx, BOOL *stop) {
        NSString *imageURL = [baseURL stringByAppendingString:imgUrl];
        [self downloadGalleryImages:imageURL forIndexPath:idx];
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
                
                if (self.imageDict.count == imagesArray.count) {
                    //                    [self.galleryView setupGallery];
                    [self setupGalleryView];
                    [self fetchSocialImages];
                }
                
            });
        } else {
        }
    }];
    
}

- (void)setupGalleryView {
    self.galleryScrollView = [[GalleryScrollView alloc] initWithDelegate:self];
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
        [self.galleryScrollView setFrame:CGRectMake(self.moviePlayer.view.frame.origin.x, self.moviePlayer.view.frame.origin.y + self.moviePlayer.view.frame.size.height, self.view.frame.size.height, 200)];
    else
        [self.galleryScrollView setFrame:CGRectMake(self.moviePlayer.view.frame.origin.x, self.moviePlayer.view.frame.origin.y + self.moviePlayer.view.frame.size.height, self.view.frame.size.width, 200)];
    
    [self.galleryScrollView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    [self.view addSubview:self.galleryScrollView];
    [self.galleryScrollView setupGalleryView];
    
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
    self.pullDownBtn = [PulldownView buttonWithType:UIButtonTypeCustom];
    self.pullDownBtn.delegate = self;
    [self.pullDownBtn addTarget:self action:@selector(pullDownClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.pullDownBtn setImage:[UIImage imageWithData:[[ECAdManager sharedManager] loadFile:@"pull3.png"]] forState:UIControlStateNormal];
    [self.view addSubview:self.pullDownBtn];
    [self.view bringSubviewToFront:self.pullDownBtn];
    [self.pullDownBtn animateImage];
    
    [self.pullDownBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    CGRect rect = self.view.bounds;
    rect.origin.x = rect.size.width - 80;
    rect.origin.y = 0;
    rect.size = CGSizeMake(35, 115);
    self.pullDownBtn.frame = rect;
    self.pullDownBtn.home = rect;
    [self.pullDownBtn setAnimationFrame];
    if (nil == self.socialTableView) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            self.socialTableView = [[UITableView alloc] initWithFrame:CGRectMake(self.pullDownBtn.frame.origin.x -220,self.pullDownBtn.frame.origin.y - self.moviePlayer.view.frame.size.height, 250, self.moviePlayer.view.frame.size.height)];
        else
            self.socialTableView = [[UITableView alloc] initWithFrame:CGRectMake(self.pullDownBtn.frame.origin.x -300,self.pullDownBtn.frame.origin.y - self.moviePlayer.view.frame.size.height, 340, self.moviePlayer.view.frame.size.height)];
        [self.view addSubview: self.socialTableView];
        self.socialTableView.delegate = self;
        self.socialTableView.dataSource = self;
        [self.socialTableView setBackgroundColor:[UIColor blackColor]];
        self.socialTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin;
        [self.socialTableView setShowsHorizontalScrollIndicator:NO];
        [self.socialTableView setShowsVerticalScrollIndicator:NO];
        self.socialTableView.layer.borderWidth = 2.0;
        self.socialTableView.layer.borderColor = [UIColor whiteColor].CGColor;
        self.socialTableView.hidden = YES;
        
        
        
        
    }
    [self.view bringSubviewToFront:self.socialTableView];
    [self.socialTableView reloadData];
    
}


# pragma mark - Puller Methods
- (void)pullUpClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"socialViewPullUpClicked"];

    [self.socialTableView setHidden:NO];
    [self.pullDownBtn removeTarget:self action:@selector(pullUpClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.pullDownBtn addTarget:self action:@selector(pullDownClicked) forControlEvents:UIControlEventTouchUpInside];
    //    [self.pullDownBtn setImage:[UIImage imageNamed:@"pullDown.png"] forState:UIControlStateNormal];
    [self.pullDownBtn setImage:nil forState:UIControlStateNormal];
    
    [self.moviePlayer play];
    isSocialVisible = NO;
    [self.pullDownBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    
    [UIView animateWithDuration:1.0 animations:^{
        CGRect pullFrame = self.pullDownBtn.home;
        pullFrame.origin.x = self.pullDownBtn.frame.origin.x;
        pullFrame.origin.y = 0;//self.moviePlayer.view.frame.size.height;
        self.pullDownBtn.frame = pullFrame;
        self.pullDownBtn.home = pullFrame;
        //        self.socialTableView.frame = CGRectMake(self.pullDownBtn.frame.origin.x -300, self.pullDownBtn.frame.origin.y - self.moviePlayer.view.frame.size.height, 340, self.moviePlayer.view.frame.size.height);
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            self.socialTableView.frame = CGRectMake(self.pullDownBtn.frame.origin.x -220,self.pullDownBtn.frame.origin.y - self.moviePlayer.view.frame.size.height, 250, self.moviePlayer.view.frame.size.height);
        else
            self.socialTableView.frame = CGRectMake(self.pullDownBtn.frame.origin.x -300, self.pullDownBtn.frame.origin.y - self.moviePlayer.view.frame.size.height, 340, self.moviePlayer.view.frame.size.height);
    }];
    
}
- (void)pullDownClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"socialViewPullDownClicked"];

    [self.socialTableView setHidden:NO];

    [self.pullDownBtn removeTarget:self action:@selector(pullDownClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.pullDownBtn addTarget:self action:@selector(pullUpClicked) forControlEvents:UIControlEventTouchUpInside];
    //    [self.pullDownBtn setImage:[UIImage imageNamed:@"pullUp.png"] forState:UIControlStateNormal];
    [self.pullDownBtn setImage:nil forState:UIControlStateNormal];
    
    if (nil == self.socialTableView) {
        self.socialTableView = [[UITableView alloc] initWithFrame:CGRectMake(self.pullDownBtn.frame.origin.x -300, self.pullDownBtn.frame.origin.y - self.moviePlayer.view.frame.size.height, 340, self.moviePlayer.view.frame.size.height)];
        [self.view addSubview: self.socialTableView];
        self.socialTableView.delegate = self;
        self.socialTableView.dataSource = self;
        [self.socialTableView setBackgroundColor:[UIColor blackColor]];
        self.socialTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin;
        [self.socialTableView setShowsHorizontalScrollIndicator:NO];
        [self.socialTableView setShowsVerticalScrollIndicator:NO];
        
    }
    
    [self.pullDownBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin];
    
    
    [self.view bringSubviewToFront:self.socialTableView];
    [self.moviePlayer pause];
    isSocialVisible = YES;
    [UIView animateWithDuration:1.0 animations:^{
        CGRect pullFrame = self.pullDownBtn.home;
        pullFrame.origin.x = self.pullDownBtn.frame.origin.x;
        pullFrame.origin.y += self.moviePlayer.view.frame.size.height;
        self.pullDownBtn.frame = pullFrame;
        self.pullDownBtn.home = pullFrame;
        //        self.socialTableView.frame = CGRectMake(self.pullDownBtn.frame.origin.x -300, self.pullDownBtn.frame.origin.y - self.moviePlayer.view.frame.size.height, 340, self.moviePlayer.view.frame.size.height);
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            self.socialTableView.frame = CGRectMake(self.pullDownBtn.frame.origin.x -220,self.pullDownBtn.frame.origin.y - self.moviePlayer.view.frame.size.height, 250, self.moviePlayer.view.frame.size.height);
        else
            self.socialTableView.frame = CGRectMake(self.pullDownBtn.frame.origin.x -300, self.pullDownBtn.frame.origin.y - self.moviePlayer.view.frame.size.height, 340, self.moviePlayer.view.frame.size.height);
        
    }];
    
    
}


#pragma mark -
#pragma mark TableView Data Source
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *view = [[UILabel alloc] init];
    [view setTextColor:[UIColor whiteColor]];
    view.font =  [UIFont fontWithName:@"Georgia-Bold" size:20.0];
    [view setBackgroundColor:[UIColor blackColor]];
    if(section == 0 )
        view.text = @"Facebook Feeds";
    else
        view.text = @"Twitter Feeds";
    return view;
}
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    
    return(section == 0 ? [self.fbContentDict count] : [self.twitterContentDict count]);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 220;
}

#pragma mark - TableView Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FBIdentifier"];
    NSArray *keys = [self.fbContentDict allKeys];
    
    NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
    keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
    NSDictionary *fbContent = [self.fbContentDict objectForKey:[keys objectAtIndex:indexPath.row]];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    if (indexPath.section == 0) {
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"FBIdentifier"];
        [cell setBackgroundColor:tableView.backgroundColor];
        [cell addSubview:[self getFBContentViewForContent:fbContent forRow:indexPath.row forCell:cell]];
    }
    else
        [self getFBContentViewForContent:fbContent forRow:indexPath.row forCell:cell];
    }
    else {
        keys = [[self.twitterContentDict allKeys] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];

        fbContent = [self.twitterContentDict objectForKey:[keys objectAtIndex:indexPath.row]];
        if (!cell) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"FBIdentifier"];
            [cell setBackgroundColor:tableView.backgroundColor];
            [cell addSubview:[self getTwitterContentViewForContent:fbContent forRow:indexPath.row forCell:cell]];
        }
        else
            [self getTwitterContentViewForContent:fbContent forRow:indexPath.row forCell:cell];
        
    }
    
    //        UIButton *btn = (UIButton *)[cell viewWithTag:1234+indexPath.row];
    //
    //        [cell bringSubviewToFront:btn];
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSArray *keys = [[self fbContentDict] allKeys];
        NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
        keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
        
        NSDictionary *fbContent = [[self fbContentDict] objectForKey:[keys objectAtIndex:indexPath.row]];
        if ([[fbContent objectForKey:@"clickurl"] length]) {
            [[ECAdManager sharedManager] videoAdLandingPageOpened:[fbContent objectForKey:@"clickurl"]];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[fbContent objectForKey:@"clickurl"]]];
        }
        else if ([[self.responseDict objectForKey:@"fbtargeturl"] length]) {
            [[ECAdManager sharedManager] videoAdLandingPageOpened:[self.responseDict objectForKey:@"fbtargeturl"]];

            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[self.responseDict objectForKey:@"fbtargeturl"]]];
        }

    }
    else {
        NSArray *keys = [[self twitterContentDict] allKeys];
        NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
        keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
        
        NSDictionary *fbContent = [[self twitterContentDict] objectForKey:[keys objectAtIndex:indexPath.row]];
        if ([[fbContent objectForKey:@"twtargeturl"] length]) {
            [[ECAdManager sharedManager] videoAdLandingPageOpened:[fbContent objectForKey:@"twtargeturl"]];

            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[fbContent objectForKey:@"twtargeturl"]]];
        }
        else if ([[self.responseDict objectForKey:@"twtargeturl"] length]) {
            [[ECAdManager sharedManager] videoAdLandingPageOpened:[self.responseDict objectForKey:@"twtargeturl"]];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[self.responseDict objectForKey:@"twtargeturl"]]];
        }
    }
}

- (void)fbButtonClicked:(UIButton *)button {
    int index = button.tag - 1234;
    
    NSArray *keys = [[self fbContentDict] allKeys];
    NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
    keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
    
    NSDictionary *fbContent = [[self fbContentDict] objectForKey:[keys objectAtIndex:index]];
    if ([[fbContent objectForKey:@"clickurl"] length]) {
        [[ECAdManager sharedManager] videoAdLandingPageOpened:[fbContent objectForKey:@"clickurl"]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[fbContent objectForKey:@"clickurl"]]];
    }
    //
    //    NSString *fbURL = [[self responseDict] objectForKey:@"fbtargeturl"];
    //    if ([fbURL length])
    //        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbURL]];
}

- (void)twitterButtonClicked:(UIButton *)button {
    int index = button.tag - 1234;
    
    NSArray *keys = [[self twitterContentDict] allKeys];
    NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
    keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
    
    NSDictionary *fbContent = [[self twitterContentDict] objectForKey:[keys objectAtIndex:index]];
    if ([[fbContent objectForKey:@"clickurl"] length]) {
        [[ECAdManager sharedManager] videoAdLandingPageOpened:[fbContent objectForKey:@"clickurl"]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[fbContent objectForKey:@"clickurl"]]];
    }
    
}

- (UIView *)getFBContentViewForContent:(NSDictionary *)fbContent forRow:(int)row forCell:(UITableViewCell *)cell {
    
    FilmStripGalleryImageView *imageView = (FilmStripGalleryImageView *)[cell viewWithTag:kGallerySocialImageViewTag + row];
    if (nil == imageView) {
        imageView = [[FilmStripGalleryImageView alloc] initWithDelegate:self];
        [imageView setTag:kGallerySocialImageViewTag + row];
        imageView.frame = CGRectMake(0, 0, cell.frame.size.width, 200);
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [imageView setFilmStripFormat:kECAdFilmStripFormatSocial];
        
//        UIButton *fbButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        [fbButton setImage:[UIImage imageWithData:[self.delegate loadFile:@"fb_Icon.png"]] forState:UIControlStateNormal];
//        fbButton.tag = 1234+row;
//        [fbButton addTarget:self action:@selector(fbButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
//        // [baseView addSubview:fbButton];
//        fbButton.frame = CGRectMake(imageView.frame.size.width - 40, 5, 25, 25);
//        [imageView addSubview:fbButton];
        
    }
    [imageView setFBContentViewForContent:fbContent];
    return imageView;
    
}
- (UIView *)getTwitterContentViewForContent:(NSDictionary *)fbContent forRow:(int)row forCell:(UITableViewCell *)cell {
    
    FilmStripGalleryImageView *imageView = (FilmStripGalleryImageView *)[cell viewWithTag:kGallerySocialImageViewTag + row];
    if (nil == imageView) {
        imageView = [[FilmStripGalleryImageView alloc] initWithDelegate:self];
        [imageView setTag:kGallerySocialImageViewTag + row];
        imageView.frame = CGRectMake(0, 0, cell.frame.size.width, 200);
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [imageView setFilmStripFormat:kECAdFilmStripFormatSocial];
        
//        UIButton *fbButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        [fbButton setImage:[UIImage imageWithData:[self.delegate loadFile:@"twitter_Icon.png"]] forState:UIControlStateNormal];
//        fbButton.tag = 1234+row;
//        [fbButton addTarget:self action:@selector(twitterButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
//        // [baseView addSubview:fbButton];
//        fbButton.frame = CGRectMake(imageView.frame.size.width - 40, 5, 25, 25);
//        [imageView addSubview:fbButton];
//        
    }
    [imageView setTwitterContentViewForContent:fbContent];
    return imageView;
    
}

#pragma mark -
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

- (void)filmStrimGalleryViewDidselectItem:(FilmStripGalleryImageView *)view {
    for (FilmStripGalleryImageView *subView in [self.galleryScrollView subviews]) {
        if ([subView isKindOfClass:[FilmStripGalleryImageView class]]) {
            if (subView == view) {
                [subView setAlpha:1.0];
                [self displayFullImage:view];
            }else {
                [subView setAlpha:0.3];
            }
        }
    }
}

- (void)resetAlphaForGallery {
    for (FilmStripGalleryImageView *subView in [self.galleryScrollView subviews]) {
        if ([subView isKindOfClass:[FilmStripGalleryImageView class]]) {
            [subView setAlpha:1.0];
        }
    }
}

- (void)displayFullImage:(FilmStripGalleryImageView *)view {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"filmStripFullScreenClicked"];

    if (nil == self.fullImage) {
        self.fullImage = [[UIImageView alloc] initWithFrame:self.moviePlayer.view.bounds];
        [self.moviePlayer.view addSubview:self.fullImage];
        self.fullImage.autoresizingMask = self.moviePlayer.view.autoresizingMask;
        [self.fullImage setContentMode:UIViewContentModeScaleAspectFit];
        [self.fullImage setUserInteractionEnabled:YES];
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"close_Icon.png"]] forState:UIControlStateNormal];
        [closeBtn addTarget:self action:@selector(closeLargeImage) forControlEvents:UIControlEventTouchUpInside];
        [self.fullImage addSubview:closeBtn];
        [closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin];
        CGRect rect = self.fullImage.bounds;
        rect.origin.x = 0;//rect.size.width - 40;
        rect.origin.y = 5;
        rect.size = CGSizeMake(40, 40);
        closeBtn.frame = rect;
        
        [self.view bringSubviewToFront:self.pullDownBtn];
        
    }
    [self.moviePlayer pause];
    self.fullImage.image = view.image;
    [self.galleryScrollView stopSliding];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.fullImage.alpha = 1.0;
    }];
}

- (void)closeLargeImage {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"filmStripFullScreenClosed"];

    [UIView animateWithDuration:0.5 animations:^{
        self.fullImage.alpha = 0.0;
        [self resetAlphaForGallery];
    } completion:^(BOOL finished) {
        [self.galleryScrollView startSliding];
        if (!isSocialVisible)
            [self.moviePlayer play];
    }];
}

#pragma mark - Pulldown delagate

- (void)pullDownViewMoved:(CGPoint)offset {
    [self.socialTableView setHidden:NO];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        self.socialTableView.frame = CGRectMake(self.pullDownBtn.frame.origin.x -220,self.pullDownBtn.frame.origin.y - self.moviePlayer.view.frame.size.height, 250, self.moviePlayer.view.frame.size.height);
    else
        self.socialTableView.frame = CGRectMake(self.pullDownBtn.frame.origin.x -300, self.pullDownBtn.frame.origin.y - self.moviePlayer.view.frame.size.height, 340, self.moviePlayer.view.frame.size.height);
    [self.socialTableView reloadData];
}
- (void)pullDownViewEnded:(CGPoint)offset {
    [UIView animateWithDuration:0.5 animations:^{
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            self.socialTableView.frame = CGRectMake(self.pullDownBtn.frame.origin.x -220,self.pullDownBtn.frame.origin.y - self.moviePlayer.view.frame.size.height, 250, self.moviePlayer.view.frame.size.height);
        else
            self.socialTableView.frame = CGRectMake(self.pullDownBtn.frame.origin.x -300, self.pullDownBtn.frame.origin.y - self.moviePlayer.view.frame.size.height, 340, self.moviePlayer.view.frame.size.height);
    }];
    [self.socialTableView reloadData];
    
}
- (void)pulDownViewCanceled:(CGPoint)offset {
    [UIView animateWithDuration:0.5 animations:^{
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            self.socialTableView.frame = CGRectMake(self.pullDownBtn.frame.origin.x -220,self.pullDownBtn.frame.origin.y - self.moviePlayer.view.frame.size.height, 250, self.moviePlayer.view.frame.size.height);
        else
            self.socialTableView.frame = CGRectMake(self.pullDownBtn.frame.origin.x -300, self.pullDownBtn.frame.origin.y - self.moviePlayer.view.frame.size.height, 340, self.moviePlayer.view.frame.size.height);
    }];
    [self.socialTableView reloadData];
    
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    //    [self.galleryScrollView setFrame:CGRectMake(self.moviePlayer.view.frame.origin.x, self.moviePlayer.view.frame.origin.y + self.moviePlayer.view.frame.size.height, self.view.frame.size.width, 200)];
    CGRect homeRect =  self.pullDownBtn.home;
    homeRect.origin.x = self.pullDownBtn.frame.origin.x;
    self.pullDownBtn.home = homeRect;
    
    
    if (!isSocialVisible) {
        self.socialTableView.frame = CGRectMake(self.socialTableView.frame.origin.x, -self.socialTableView.frame.size.height, self.socialTableView.frame.size.width, self.socialTableView.frame.size.height);
    }
    else {
        self.socialTableView.frame = CGRectMake(self.socialTableView.frame.origin.x, 0, self.socialTableView.frame.size.width, self.socialTableView.frame.size.height);
        
    }
    [self.view bringSubviewToFront:self.pullDownBtn];
    [self.galleryScrollView relayoutGallery];
}

- (void)layoutFrames:(UIInterfaceOrientation)toInterfaceOrientation {
    
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
    self.socialTableView.hidden = YES;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.moviePlayer = nil;
}

@end
