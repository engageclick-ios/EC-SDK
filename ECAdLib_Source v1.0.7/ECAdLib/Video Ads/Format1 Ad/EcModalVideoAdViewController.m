//
//  ViewController.m
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/3/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import "EcModalVideoAdViewController.h"
#import "PopOverMenuViewController.h"
#import "ECAdManager.h"
#import "EcAdCustomPlayer.h"

#import <QuartzCore/QuartzCore.h>

#define ECAdGalleryImageTag 3000
#define ECADGallerySelectionWidth 4
#define ECADMaxHotSpots 10
#define ECADHotSpotTag 4000
#define ECADHotSpotViewTag 5000

@interface EcModalVideoAdViewController () <UITableViewDataSource, UITableViewDelegate> {
    int selectedImage;
    int selectedHotspot;
    NSTimer *socialTimer;
    
}
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) UITableView *galleryTableView;
@property (nonatomic, strong) UIImageView *galleryImageView;
@property (nonatomic, strong) UIButton  *closeButton;
@property (nonatomic, strong) UIView *socialView;
@property (nonatomic, strong) UIImageView *socialImageView;
@property (nonatomic, strong) UILabel *socialUserName;
@property (nonatomic, strong) UILabel *recentTweetLbl;
@property (nonatomic, strong) UITextView *socialDescTextView;

@property (nonatomic, strong) UIImageView *socialFBImageView;
@property (nonatomic, strong) UILabel *socialFBUserName;
@property (nonatomic, strong) UILabel *recentFBLbl;
@property (nonatomic, strong) UITextView *socialFBDescTextView;

@property (nonatomic, strong) UIButton *fbButton;
@property (nonatomic, strong) UIButton *twitterButton;
@property (nonatomic, strong) UILabel *thugLabel;
@property (nonatomic, strong) NSTimer *thugTimer;

@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@property (nonatomic, strong) NSMutableDictionary *imageDict;
@property (nonatomic, strong) NSMutableDictionary *socialImages;
@property (nonatomic, strong) NSMutableDictionary *socialFBImages;

@property (nonatomic, strong) NSMutableDictionary *fbContentDict;
@property (nonatomic, strong) NSMutableDictionary *twitterContentDict;

@property (nonatomic, strong)  NSMutableDictionary *hotSpotRect;
@property (nonatomic, strong) UIPopoverController *hotSpotPopover;
@property (nonatomic, strong) NSMutableArray *popoverOptions;
@property int currentFBIndex;
@property int currentTwitterIndex;

@end

@implementation EcModalVideoAdViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.spinner setCenter:self.view.center];
    [self.view addSubview:self.spinner];
    [self.spinner setHidesWhenStopped:YES];
    [self.spinner startAnimating];
    self.imageDict = [NSMutableDictionary dictionary];
    self.socialImages = [NSMutableDictionary dictionary];
    self.fbContentDict = [NSMutableDictionary dictionary];
    self.twitterContentDict = [NSMutableDictionary dictionary];
    self.hotSpotRect = [NSMutableDictionary dictionary];
    self.currentFBIndex = self.currentFBIndex = selectedImage = -1;
    // To Parse the JSON response
    if (nil == self.responseDict) {
        [self fetchData];
    }
    else {
        [self setupVideoPlayerForiPad];
        [self setupGalleryTableViewForiPad];
        [self setupSocialViewForiPad];
        [self layoutTableViewFrame:self.interfaceOrientation];
        [self.view bringSubviewToFront:self.spinner];
        [self fetchGelleryImages];
    }
    [self generateHotSpotFrames];
    //     self.popoverOptions = [NSMutableArray arrayWithObjects:@"Like us on Twitter",@"Like us on Facebook",@"Special Offers",@"Find a Dealer", nil];
    self.popoverOptions = [NSMutableArray arrayWithObjects:@"Find Out More", nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(playbackFinished:)
                                                name:UIApplicationDidEnterBackgroundNotification
                                              object:nil];

}

- (void)fetchGelleryImages {
    NSDictionary *data =  [self.responseDict objectForKey:@"data"];
    NSString *baseURL = [self.responseDict objectForKey:@"apiserver"];
    
    if (![baseURL length])
        return;
    NSArray *imagesArray = [data objectForKey:@"fois"];
    NSDictionary *foiData = [data objectForKey:@"foidata"];
    
    [imagesArray enumerateObjectsUsingBlock:^(NSString *imgUrl, NSUInteger idx, BOOL *stop) {
        NSString *imageURL = [baseURL stringByAppendingString:imgUrl];
        [self downloadGalleryImages:imageURL forIndexPath:idx];
        NSMutableArray *hotspots = [self getHotspots:[[foiData objectForKey:imgUrl] objectForKey:@"hotspots"]];
        if ([hotspots count]) {
            [self.hotSpotRect setObject:hotspots forKey:[NSString stringWithFormat:@"%d",idx]];
        }
    }];
    [self fetchSocialImages];
    __unsafe_unretained id target = self;
    socialTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:target selector:@selector(slideSocialContent) userInfo:nil repeats:YES];
}

- (NSMutableArray *)getHotspots:(NSString *)str {
    if (![str length])
        return nil;
    NSMutableArray *hotspots = [NSMutableArray array];
    NSArray *spots = [str componentsSeparatedByString:@":"];
    for (NSString *str in spots) {
        NSMutableArray *spots = [NSMutableArray arrayWithArray: [str componentsSeparatedByString:@","]];
        if ([spots count] >4) {
            [spots removeLastObject];
            [spots removeLastObject];
        }
        CGRect rect = CGRectMake([[spots objectAtIndex:0] floatValue], [[spots objectAtIndex:1] floatValue], [[spots objectAtIndex:2] floatValue], [[spots objectAtIndex:3] floatValue]);
        [hotspots addObject:[NSValue valueWithCGRect:rect]];
    }
    
    return hotspots;
    
    
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
        
        //ECLog(@"responseString = %@ and response statusCode = %d",responseString, [httpResponse statusCode]);
        data=[responseString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (responseDictionary)
            self.responseDict = [NSMutableDictionary dictionaryWithDictionary:responseDictionary];
        
        if ([httpResponse statusCode] == 200) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self setupVideoPlayerForiPad];
                [self setupGalleryTableViewForiPad];
                [self setupSocialViewForiPad];
                [self layoutTableViewFrame:self.interfaceOrientation];
                [self.view bringSubviewToFront:self.spinner];
                
                [self fetchGelleryImages];
            });
            
        } else {
        }
    }];
}

- (NSData *)loadFile:(NSString *)name {
    return [[ECAdManager sharedManager] loadFile:name];
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
                [self.galleryTableView reloadData];
                
            });
        } else {
        }
    }];
    
}

- (void) setupVideoPlayerForiPad {
    
    NSDictionary *data =  [self.responseDict objectForKey:@"data"];
    self.moviePlayer = [[EcAdCustomPlayer alloc] initWithContentURL:[NSURL URLWithString: [data objectForKey:@"media"]]];
    [(EcAdCustomPlayer *)self.moviePlayer setTargetURL:[self.responseDict objectForKey:@"targeturl"]];
    self.moviePlayer.view.frame = CGRectMake(10, 50, 750, 500);
    [self.moviePlayer setControlStyle:MPMovieControlStyleNone];
    [self.view addSubview:self.moviePlayer.view];
    [self.moviePlayer prepareToPlay];
    [self.moviePlayer play];
    
    // Gallery ImageView
    
    self.galleryImageView = [[UIImageView alloc] initWithFrame:self.moviePlayer.view.frame];
    [self.view addSubview:self.galleryImageView];
    [self.galleryImageView setHidden:YES];
    [self.galleryImageView setClipsToBounds:NO];
    [self.galleryImageView setUserInteractionEnabled:YES];
    [self.galleryImageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.galleryImageView setBackgroundColor:[UIColor blackColor]];
    // Close Icon
    
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeButton addTarget:self action:@selector(closeButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.closeButton setImage:[UIImage imageWithData:[self.delegate loadFile:@"close_Icon.png"]] forState:UIControlStateNormal];
    [self.galleryImageView addSubview:self.closeButton];
    
    CGRect frame = self.galleryImageView.bounds;
    frame.size = CGSizeMake(24, 24);
    frame.origin.x = self.galleryImageView.frame.size.width - frame.size.width;
    self.closeButton.frame = frame;
    
    
    // Thug Label - To DIsplay seconds
    
    self.thugLabel = [[UILabel alloc] init];
    //    self.thugLabel.text = [NSString stringWithFormat:@"Your Ad will end in %.0f seconds",ceil((self.moviePlayer.duration -  self.moviePlayer.currentPlaybackTime))];
    self.thugLabel.textColor = [UIColor whiteColor];
    [self.thugLabel setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:self.thugLabel];
    
    frame = self.view.frame;
    frame.origin.x = 10;
    frame.origin.y = 10;
    frame.size = CGSizeMake(self.view.frame.size.width, 20);
    self.thugLabel.frame = frame;
    
    // Create a Timer To Check for the time
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackChanged:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:self.moviePlayer];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"black_Close.png"]] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(viewCloseBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];
    [closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    CGRect rect = self.view.bounds;
    rect.origin.x = rect.size.width - 40;
    rect.origin.y = 5;
    rect.size = CGSizeMake(40, 40);
    closeBtn.frame = rect;
    [self.view bringSubviewToFront:closeBtn];
}

- (void)viewCloseBtnClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"userAdClose"];

    if ([self.delegate respondsToSelector:@selector(adVideoDidFinishPlayback)])
        [self.delegate performSelector:@selector(adVideoDidFinishPlayback)];
    
}
- (void)playbackFinished:(MPMoviePlayerController *)player {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if ([self.delegate respondsToSelector:@selector(adVideoDidFinishPlayback)])
        [self.delegate performSelector:@selector(adVideoDidFinishPlayback)];
}

- (void)playbackChanged:(MPMoviePlayerController *)player {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.moviePlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self.moviePlayer selector:@selector(play) name:@"AppDidEnterForeground" object:nil];
    
    if (![self.thugTimer isValid])
        self.thugTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    [self.spinner stopAnimating];
    
}
- (void)updateTime {
    //    if ((self.moviePlayer.duration -  self.moviePlayer.currentPlaybackTime) == 0) {
    //        [self dismissViewControllerAnimated:YES completion:nil];
    //    }
    if (self.galleryImageView.isHidden) {
        self.thugLabel.text = [NSString stringWithFormat:@"Your Ad will end in %.0f seconds",ceil((self.moviePlayer.duration -  self.moviePlayer.currentPlaybackTime))];
    }
}

- (void)setupGalleryTableViewForiPad {
    CGRect tableFrame = self.moviePlayer.view.frame;
    tableFrame.origin.y += tableFrame.size.height+40;
    
    tableFrame.size.width = 400;
    tableFrame.size.height = 300;
    self.galleryTableView = [[UITableView alloc] initWithFrame:tableFrame];
    [self.view addSubview:self.galleryTableView];
    self.galleryTableView.delegate = self;
    self.galleryTableView.dataSource = self;
    [self.galleryTableView setBackgroundColor:[UIColor blackColor]];
    [self.galleryTableView setSeparatorColor:[UIColor blackColor]];
    [self.galleryTableView setShowsVerticalScrollIndicator:NO];
    [self.galleryTableView setShowsHorizontalScrollIndicator:NO];
    
}


#pragma mark - Social Content

- (void)setupSocialViewForiPad {
    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y = self.view.frame.size.height - 200;
    viewFrame.size.width = self.moviePlayer.view.frame.size.width;
    viewFrame.size.height = 100;
    viewFrame.origin.x = self.moviePlayer.view.frame.origin.x;
    self.socialView = [[UIView alloc] initWithFrame:viewFrame];
    [self.view addSubview:self.socialView];
    [self.socialView setBackgroundColor:[UIColor blackColor]];
    [self setupInnerContentForSocialView];
    [self setupInnerContentForFBSocialView];
    [self.socialView setAlpha:0.0];
    [self.socialView setHidden:YES];
}

- (void)slideSocialContent {
    if ([self.fbContentDict count]) {
        if ([self.socialView isHidden]) {
            [self.socialView setHidden:NO];
            [UIView animateWithDuration:0.5 animations:^{
                [self.socialView setAlpha:1.0];
            }];
        }
        NSArray *keys =[self.fbContentDict allKeys];
        NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
        keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
        
        if (self.currentFBIndex == -1)
            self.currentFBIndex = [[keys objectAtIndex:0] integerValue];
        else {
            int index = [keys indexOfObject:[NSString stringWithFormat:@"%d",self.currentFBIndex]]+1;
            if (index >= [keys count])
                index = 0;
            self.currentFBIndex = [[keys objectAtIndex:index] integerValue];
        }
        
        NSDictionary *fbContent = [self.fbContentDict objectForKey:[NSString stringWithFormat:@"%d",self.currentFBIndex]];
        self.socialFBUserName.text = [fbContent objectForKey:@"username"];
        self.socialFBDescTextView.text = [fbContent objectForKey:@"message"];
        self.socialFBImageView.image = [self.socialImages objectForKey:[fbContent objectForKey:@"picture"]];
        
    }
    if ([self.twitterContentDict count]) {
        NSArray *keys =[self.twitterContentDict allKeys];
        NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
        keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
        
        if (self.currentTwitterIndex == -1)
            self.currentTwitterIndex = [[keys objectAtIndex:0] integerValue];
        else {
            int index = [keys indexOfObject:[NSString stringWithFormat:@"%d",self.currentTwitterIndex]]+1;
            if (index >= [keys count])
                index = 0;
            self.currentTwitterIndex = [[keys objectAtIndex:index] integerValue];
        }
        
        NSDictionary *fbContent = [self.twitterContentDict objectForKey:[NSString stringWithFormat:@"%d",self.currentTwitterIndex]];
        self.socialUserName.text = [fbContent objectForKey:@"username"];
        self.socialDescTextView.text = [fbContent objectForKey:@"message"];
        self.socialImageView.image = [self.socialImages objectForKey:[fbContent objectForKey:@"iconurl"]];
    }
}
- (void)setupInnerContentForFBSocialView {
    // Initialize User ImageView
    self.socialFBImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:[self.delegate loadFile:@"Sample.jpg"]]];
    [self.socialView addSubview:self.socialFBImageView];
    CGRect frame = self.socialImageView.frame;
    frame.origin.y += frame.size.height +5;
    self.socialFBImageView.frame = frame;
    
    // User Name Label
    
    self.socialFBUserName = [[UILabel alloc] init];
    self.socialFBUserName.text = @"User Name";
    [self.socialView addSubview:self.socialFBUserName];
    [self.socialFBUserName setBackgroundColor:[UIColor clearColor]];
    [self.socialFBUserName setFont:[UIFont boldSystemFontOfSize:20]];
    frame = self.socialFBImageView.frame;
    frame.origin.x += frame.size.width + 5;
    frame.size.width = 300;
    frame.size.height = 20;
    self.socialFBUserName.frame = frame;
    
    [self.socialFBUserName setTextColor:[UIColor whiteColor]];
    
    //Recent Post
    
    self.recentFBLbl = [[UILabel alloc] init];
    self.recentFBLbl.text = @"Recent Post";
    [self.socialView addSubview:self.recentFBLbl];
    
    CGRect lblFrame = self.socialFBUserName.frame;
    lblFrame.origin.x += lblFrame.size.width;
    lblFrame.size.width = 120;
    self.recentFBLbl.frame = lblFrame;
    [self.recentFBLbl setBackgroundColor:[UIColor blackColor]];
    [self.recentFBLbl setTextColor:[UIColor whiteColor]];
    [self.recentFBLbl setFont:[UIFont italicSystemFontOfSize:20]];
    
    // Fb Icon
    
    self.fbButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.fbButton setImage:[UIImage imageWithData:[self.delegate loadFile:@"fb_Icon.png"]] forState:UIControlStateNormal];
    [self.fbButton addTarget:self action:@selector(fbButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.socialView addSubview:self.fbButton];
    self.fbButton.frame = CGRectMake(self.recentFBLbl.frame.origin.x+self.recentFBLbl.frame.size.width, self.recentFBLbl.frame.origin.y, 30, 30);
    
    // Descrition TextView
    
    self.socialFBDescTextView = [[UITextView alloc] init];
    [self.socialFBDescTextView setBackgroundColor:[UIColor clearColor]];
    self.socialFBDescTextView.dataDetectorTypes = UIDataDetectorTypeLink;
    [self.socialFBDescTextView setText:@"Speeding ticket for a CLA in Switzerland? @caseyneistat, do you know anything about this? http://t.co/rOltiKP8wT"];
    
    frame = self.socialFBImageView.frame;
    frame.size.width = self.socialView.frame.size.width - 80;
    frame.origin.x = self.socialFBUserName.frame.origin.x-3;
    frame.origin.y = self.socialFBUserName.frame.origin.y + self.socialFBUserName.frame.size.height+3;
    frame.size.height = 100;
    self.socialFBDescTextView.frame = frame;
    [self.socialView addSubview:self.socialFBDescTextView];
    [self.socialFBDescTextView setEditable:NO];
    [self.socialFBDescTextView setFont:[UIFont systemFontOfSize:20]];
    [self.socialFBDescTextView setTextColor:[UIColor whiteColor]];
}

- (void)setupInnerContentForSocialView {
    // Initialize User ImageView
    self.socialImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:[self.delegate loadFile:@"Sample.jpg"]]];
    [self.socialView addSubview:self.socialImageView];
    CGRect frame = self.socialView.bounds;
    frame.size.width = 100;
    self.socialImageView.frame = frame;
    
    // User Name Label
    
    self.socialUserName = [[UILabel alloc] init];
    self.socialUserName.text = @"User Name";
    [self.socialView addSubview:self.socialUserName];
    [self.socialUserName setBackgroundColor:[UIColor clearColor]];
    [self.socialUserName setFont:[UIFont boldSystemFontOfSize:20]];
    frame = self.socialImageView.frame;
    frame.origin.x += frame.size.width + 5;
    frame.size.width = 300;
    frame.size.height = 20;
    self.socialUserName.frame = frame;
    
    [self.socialUserName setTextColor:[UIColor whiteColor]];
    
    //Recent Tweet
    
    self.recentTweetLbl = [[UILabel alloc] init];
    self.recentTweetLbl.text = @"Recent Tweet";
    [self.socialView addSubview:self.recentTweetLbl];
    
    CGRect lblFrame = self.socialUserName.frame;
    lblFrame.origin.x += lblFrame.size.width;
    lblFrame.size.width = 140;
    self.recentTweetLbl.frame = lblFrame;
    [self.recentTweetLbl setBackgroundColor:[UIColor clearColor]];
    [self.recentTweetLbl setTextColor:[UIColor whiteColor]];
    [self.recentTweetLbl setFont:[UIFont italicSystemFontOfSize:20]];
    
    
    // Twitter Icon
    
    self.twitterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.twitterButton setImage:[UIImage imageWithData:[self.delegate loadFile:@"twitter_Icon.png"]] forState:UIControlStateNormal];
    [self.twitterButton addTarget:self action:@selector(twitterButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.socialView addSubview:self.twitterButton];
    self.twitterButton.frame = CGRectMake(self.recentTweetLbl.frame.origin.x+self.recentTweetLbl.frame.size.width, self.recentTweetLbl.frame.origin.y, 30, 30);
    
    // Descrition TextView
    
    self.socialDescTextView = [[UITextView alloc] init];
    [self.socialDescTextView setBackgroundColor:[UIColor clearColor]];
    self.socialDescTextView.dataDetectorTypes = UIDataDetectorTypeLink;
    [self.socialDescTextView setText:@"Speeding ticket for a CLA in Switzerland? @caseyneistat, do you know anything about this? http://t.co/rOltiKP8wT"];
    
    frame = self.socialImageView.frame;
    frame.size.width = self.socialView.frame.size.width - 80;
    frame.origin.x = self.socialUserName.frame.origin.x-3;
    frame.origin.y = self.socialUserName.frame.origin.y + self.socialUserName.frame.size.height+3;
    self.socialDescTextView.frame = frame;
    [self.socialView addSubview:self.socialDescTextView];
    [self.socialDescTextView setEditable:NO];
    [self.socialDescTextView setFont:[UIFont systemFontOfSize:20]];
    [self.socialDescTextView setTextColor:[UIColor whiteColor]];
}


- (void)twitterButtonClicked {
    NSString *twitterURL = [self.responseDict objectForKey:@"twtargeturl"];
    if ([twitterURL length]) {
        [[ECAdManager sharedManager] videoAdLandingPageOpened:twitterURL];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:twitterURL]];
    }
    
}

- (void)fbButtonClicked {
    NSString *fbURL = [self.responseDict objectForKey:@"fbtargeturl"];
    if ([fbURL length]) {
        [[ECAdManager sharedManager] videoAdLandingPageOpened:fbURL];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbURL]];
    }
}
#pragma mark - Orientation Methods
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self layoutTableViewFrame:toInterfaceOrientation];
    [self.galleryTableView reloadData];
    for (int i = 0 ; i < ECADMaxHotSpots ; i++) {
        UIButton *hotspotView = (UIButton *) [self.galleryImageView viewWithTag:ECADHotSpotViewTag+i];
        CGRect frame = hotspotView.frame;
        frame.origin.y = self.galleryImageView.frame.size.height;
        [UIView animateWithDuration:0.5 animations:^{
            hotspotView.frame = frame;
        }];
    }
    
}


- (void)layoutTableViewFrame:(UIInterfaceOrientation)interfaceOrientation {
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
    {
        CGRect tableFrame = self.moviePlayer.view.frame;
        tableFrame.origin.x = 326;
        tableFrame.origin.y += tableFrame.size.height-240;
        tableFrame.size.width = 120;//400;
        tableFrame.size.height = 750;//tableFrame.size.width;//300;
        //        tableFrame.size.width = 400;
        //        tableFrame.size.height = 300;
        self.galleryTableView.frame = tableFrame;
        self.galleryTableView.transform = CGAffineTransformMakeRotation(-M_PI * 0.5);
        
        CGRect viewFrame = self.view.frame;
        viewFrame.origin.y = self.view.frame.size.height - 250;
        viewFrame.size.width = self.moviePlayer.view.frame.size.width;
        viewFrame.size.height = 220;
        viewFrame.origin.x = self.moviePlayer.view.frame.origin.x;
        self.socialView.frame = viewFrame;
        
    }
    
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation))    {
        CGRect tableFrame = self.moviePlayer.view.frame;
        tableFrame.origin.x += tableFrame.size.width+10;
        tableFrame.size.width = 250;
        tableFrame.size.height = 500;
        self.galleryTableView.transform = CGAffineTransformIdentity;
        self.galleryTableView.frame = tableFrame;
        
        
        CGRect viewFrame = self.view.frame;
        viewFrame.origin.y = self.galleryTableView.frame.size.height+10;
        viewFrame.size.width = self.moviePlayer.view.frame.size.width;
        viewFrame.size.height = 190;
        viewFrame.origin.x = self.moviePlayer.view.frame.origin.x;
        self.socialView.frame = viewFrame;
        
        
        
    }
    
    CGRect frame = self.socialFBImageView.frame;
    frame.size.width = self.socialView.frame.size.width - 80;
    frame.origin.x = self.socialFBUserName.frame.origin.x-3;
    frame.origin.y = self.socialFBUserName.frame.origin.y + self.socialFBUserName.frame.size.height+3;
    frame.size.height = 60;
    self.socialFBDescTextView.frame = frame;
    
    self.spinner.center = self.view.center;
    self.spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    
    [self.view bringSubviewToFront:self.socialView];
}
- (void)closeButtonClicked {
    [self.moviePlayer.view setHidden:NO];
    [UIView animateWithDuration:0.5 animations:^{
        [self.galleryImageView setAlpha:0.0];
    } completion:^(BOOL finished) {
        [self.galleryImageView setAlpha:1.0];
        [self.galleryImageView setHidden:YES];
        [self.moviePlayer play];
    }];
}

#pragma mark -
#pragma mark TableView Data Source
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 10.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor clearColor]];
    return view;
}
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [self.imageDict count];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

#pragma mark - TableView Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Identifier"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Identifier"];
        [cell setBackgroundColor:tableView.backgroundColor];
    }
    [cell.contentView addSubview:[self getSelectedBGView]];
    [cell setBackgroundView:[self getContentViewForIndexpath:indexPath]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        cell.transform = CGAffineTransformMakeRotation(M_PI * 0.5);
    else
        cell.transform = CGAffineTransformIdentity;
    
    
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == selectedImage) {
        return;
    }
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (selectedImage >= 0) {
        UITableViewCell *prevCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedImage inSection:0]];
        UIImageView *prevImage = (UIImageView *)[prevCell viewWithTag:selectedImage + ECAdGalleryImageTag];
        [prevImage.layer setBorderWidth:0.0];
    }
    
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:indexPath.row + ECAdGalleryImageTag];
    
    [imageView.layer setBorderWidth:ECADGallerySelectionWidth];
    [imageView.layer setBorderColor:[UIColor orangeColor].CGColor];
    selectedImage = indexPath.row;
    [self.moviePlayer pause];
    [self.galleryImageView setImage:imageView.image];
    [self.galleryImageView setHidden:NO];
    [self.galleryImageView setAlpha:0.0];
    [self.galleryImageView bringSubviewToFront:self.closeButton];
    //[self.view bringSubviewToFront:self.galleryImageView];
    [self.thugLabel setText:@"Paused"];
    [self.moviePlayer.view setHidden:YES];
    [self generateHotSpots];
    [UIView animateWithDuration:0.5 animations:^{
        [self.galleryImageView setAlpha:1.0];
    } completion:^(BOOL finished) {
    }];
}
- (UIView *)getSelectedBGView {
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor orangeColor]];
    return view;
}
- (UIImageView *)getContentViewForIndexpath:(NSIndexPath *)indexPath {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.image = [self.imageDict objectForKey:[NSString stringWithFormat:@"%d",indexPath.row]];
    [imageView setTag:indexPath.row + ECAdGalleryImageTag];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    if (selectedImage >= 0) {
        if (indexPath.row == selectedImage) {
            [imageView.layer setBorderWidth:ECADGallerySelectionWidth];
            [imageView.layer setBorderColor:[UIColor orangeColor].CGColor];
        }
        else {
            [imageView.layer setBorderWidth:0.0];
            //            [imageView.layer setBorderColor:[UIColor orangeColor].CGColor];
            
        }
    }
    
    return imageView;
    
}


#pragma mark - Hot Spot Views

- (void)removeHotspotBtns {
    //    CGFloat xOffset = 5;
    //    CGFloat padding = 0;
    
    for (int i = 0 ; i < ECADMaxHotSpots ; i++) {
        UIButton *btn = (UIButton *) [self.galleryImageView viewWithTag:ECADHotSpotTag+i];
        if (nil == btn)
            return;
        [btn removeFromSuperview];
        btn = nil;
        
        
        /*
         UIButton *hotspotView = (UIButton *) [self.galleryImageView viewWithTag:ECADHotSpotViewTag+i];
         if (nil == hotspotView) {
         hotspotView = [[UIButton alloc] initWithFrame:CGRectMake(xOffset, self.galleryImageView.frame.size.height, 100, 100)];
         [hotspotView setBackgroundColor:[UIColor lightGrayColor]];
         [hotspotView setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
         [hotspotView setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
         [hotspotView addTarget:self action:@selector(hotspotViewClicked:) forControlEvents:UIControlEventTouchUpInside];
         [self.galleryImageView addSubview:hotspotView];
         [self.galleryImageView setClipsToBounds:YES];
         }
         [hotspotView setTitle:[self.popoverOptions objectAtIndex:i] forState:UIControlStateNormal];
         
         hotspotView.frame = CGRectMake(xOffset+padding, self.galleryImageView.frame.size.height, 200, 50);
         [hotspotView setTag:ECADHotSpotViewTag+i];
         [hotspotView.layer setCornerRadius:12.0];
         padding += 50;
         xOffset += 200;
         */
    }
}

- (void)hotspotViewClicked:(UIButton *)sender {
    int index =    sender.tag - ECADHotSpotViewTag;
    switch (index) {
        case 0:
            [self twitterButtonClicked];
            break;
        case 1:
            [self fbButtonClicked];
            break;
        case 2:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.mbusa.com/mercedes/special_offers/current#"]];
            break;
        case 3:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.mbusa.com/mercedes/index"]];
            break;
            
        default:
            break;
    }
    
}
- (void)generateHotSpotFrames {
    
    
    //    [self.hotSpotRect addObject:[NSValue valueWithCGRect:CGRectMake(677,345,30,30)]];
    //    [self.hotSpotRect addObject:[NSValue valueWithCGRect:CGRectMake(243,278,30,30)]];
    //    [self.hotSpotRect addObject:[NSValue valueWithCGRect:CGRectMake(569,189,30,30)]];
    
    //    CGRect someRect = [[array objectAtIndex:0] CGRectValue];
    
}
- (void)generateHotSpots {
    [self removeHotspotBtns];
    if (![self.hotSpotRect objectForKey:[NSString stringWithFormat:@"%d",selectedImage]])
        return;
    
    NSMutableArray *hotspots = [self.hotSpotRect objectForKey:[NSString stringWithFormat:@"%d",selectedImage]];
    
    int randomNo = [hotspots count] ;//arc4random() % ECADMaxHotSpots;
    
    
    for (int i = 0; i < randomNo; i ++) {
        UIButton *hotSpot = [UIButton buttonWithType:UIButtonTypeContactAdd];
        [hotSpot setTag:ECADHotSpotTag+i];
        [hotSpot addTarget:self action:@selector(hotSpotBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        hotSpot.frame =[self getCroppedRect:[[hotspots objectAtIndex:i] CGRectValue] forImage:self.galleryImageView] ;//[[self.hotSpotRect objectAtIndex:arc4random() % (ECADMaxHotSpots-1)] CGRectValue];
        [self.galleryImageView addSubview:hotSpot];
        
    }
}

- (CGRect)getCroppedRect:(CGRect )originalRect forImage:(UIImageView *)imageView {
    CGSize imageSize = imageView.image.size;
    CGFloat imageScale = fminf(CGRectGetWidth(imageView.bounds)/imageSize.width, CGRectGetHeight(imageView.bounds)/imageSize.height);
    CGSize scaledImageSize = CGSizeMake(imageSize.width*imageScale, imageSize.height*imageScale);
    CGRect imageFrame = CGRectMake(roundf(0.5f*(CGRectGetWidth(imageView.bounds)-scaledImageSize.width)), roundf(0.5f*(CGRectGetHeight(imageView.bounds)-scaledImageSize.height)), roundf(scaledImageSize.width), roundf(scaledImageSize.height));
    
    CGRect correctFrame = originalRect;//CGRectMake(770, 205, 275, 380);
    
    CGSize imageSize1 = correctFrame.size;
    CGSize scaledImageSize1 = CGSizeMake(imageSize1.width*imageScale, imageSize1.height*imageScale);
    CGRect imageFrame1 = CGRectMake(roundf(0.5f*(CGRectGetWidth(imageFrame)-scaledImageSize1.width)), roundf(0.5f*(CGRectGetHeight(imageFrame)-scaledImageSize1.height)), roundf(scaledImageSize1.width), roundf(scaledImageSize1.height));
    
    imageFrame1.origin.x = imageFrame.origin.x + (roundf(imageScale*correctFrame.origin.x));
    imageFrame1.origin.y = imageFrame.origin.y + (roundf(imageScale*correctFrame.origin.y));
    
    return imageFrame1;
}

- (void)hotSpotBtnClicked:(UIButton *)sender {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"hotSpotClicked"];

    int idx = sender.tag - ECADHotSpotTag;
    selectedHotspot = idx;
    NSDictionary *data =  [self.responseDict objectForKey:@"data"];
    NSArray *imagesArray = [data objectForKey:@"fois"];
    NSDictionary *foiData = [data objectForKey:@"foidata"];
    
    NSArray *spots = [[foiData objectForKey:[imagesArray objectAtIndex:selectedImage]] objectForKey:@"linkurls"];
    NSMutableArray *array = [NSMutableArray array];
    if ([spots lastObject]) {
        NSArray *arr = [spots objectAtIndex:idx];
        [arr enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
            [array addObject:[obj objectForKey:@"displayname"]];
        }];
    }
    if ([array lastObject]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        [array enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
            [actionSheet addButtonWithTitle:obj];
        }];
        [actionSheet addButtonWithTitle:@"Later"];
        [actionSheet setCancelButtonIndex:[array count]];
        actionSheet.actionSheetStyle=UIActionSheetStyleBlackTranslucent;
        [actionSheet showFromRect:self.view.bounds inView:self.view animated:YES];
    }

}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex ==  [actionSheet cancelButtonIndex])
        return;
    NSDictionary *data =  [self.responseDict objectForKey:@"data"];
    NSArray *imagesArray = [data objectForKey:@"fois"];
    NSDictionary *foiData = [data objectForKey:@"foidata"];
    
    NSArray *spots = [[foiData objectForKey:[imagesArray objectAtIndex:selectedImage]] objectForKey:@"linkurls"];
    NSString *url;
    if ([spots lastObject]) {
        NSArray *arr = [spots objectAtIndex:selectedHotspot];
        url = [[arr objectAtIndex:buttonIndex] objectForKey:@"link"];
    }
    if ([url length]) {
        [[ECAdManager sharedManager] videoAdLandingPageOpened:url];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
}


- (void)popoverDidSelectOption:(PopOverMenuViewController *)vc {
    int index =    [self.popoverOptions indexOfObject:[vc.contentArray objectAtIndex:vc.selectedItem]];
    switch (index) {
        case 0:
            [self twitterButtonClicked];
            break;
        case 1:
            [self fbButtonClicked];
            break;
        case 2:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.mbusa.com/mercedes/special_offers/current#"]];
            break;
        case 3:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.mbusa.com/mercedes/index"]];
            break;
            
        default:
            break;
    }
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
    [socialTimer invalidate];
    socialTimer = nil;
    [self.thugTimer invalidate];
    self.thugTimer = nil;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self.moviePlayer];
    
    self.moviePlayer = nil;
}
@end
