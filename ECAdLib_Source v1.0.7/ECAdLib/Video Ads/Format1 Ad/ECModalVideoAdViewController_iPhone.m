//
//  ECModalVideoAdViewController_iPhone.m
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/7/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import "ECModalVideoAdViewController_iPhone.h"
#import "SideSwipeTableViewCell.h"

#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "ECAdManager.h"
#import "EcAdCustomPlayer.h"


#define ECAdGalleryImageTag 3000
#define ECADGallerySelectionWidth 4
#define ECADMaxHotSpots 10
#define ECADHotSpotTag 4000
#define ECADHotSpotViewTag 5000

#define BUTTON_LEFT_MARGIN 10.0
#define BUTTON_SPACING 5.0

// By setting this to YES, you'll use gesture recognizers under 4.x and use the table's swipe to delete under 3.x
// By setting it to NO, you'll be using the table's swipe to delete under both 3.x and 4.x. This is what version 3 of the Twitter app does
// Swipe to delete on a table doesn't expose the direction of the swipe, so the animation will always be left to right
#define USE_GESTURE_RECOGNIZERS YES
// Bounce pixels define how many pixels the view is moved during the bounce animation
#define BOUNCE_PIXELS 5.0
// The first implemenation of this animated both the cell and the sideSwipeView.
// But this isn't exactly how the Twitter app does it. Instead it keeps the sideSwipeView behind the cell at x-offset of 0
// then animates in and out the cell content. The code has been updated to do it this way. If you preferred the old way
// set PUSH_STYLE_ANIMATION to YES and you'll get the older push style animation
#define PUSH_STYLE_ANIMATION NO

@interface ECModalVideoAdViewController_iPhone () <UITableViewDataSource, UITableViewDelegate> {
    int selectedImage;
    int currentHotspot;
    BOOL animatingSideSwipe;
    NSArray* buttonData;
    NSMutableArray* buttons;
}
@property (nonatomic, strong) UIButton *viewCloseBtn;
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) UITableView *galleryTableView;
@property (nonatomic, strong) UITableView *socialTableView;
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
@property (nonatomic, strong) UIButton *socialButton;
@property (nonatomic, strong) UILabel *thugLabel;
@property (nonatomic, strong) NSTimer *thugTimer;

@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@property (nonatomic, strong) NSMutableDictionary *imageDict;
@property (nonatomic, strong) NSMutableDictionary *socialImages;
@property (nonatomic, strong) NSMutableDictionary *socialFBImages;

@property (nonatomic, strong) NSMutableDictionary *fbContentDict;
@property (nonatomic, strong) NSMutableDictionary *twitterContentDict;
@property (nonatomic, strong) NSMutableArray *socialData;

@property (nonatomic, strong)  NSMutableDictionary *hotSpotRect;
@property (nonatomic, strong) UIPopoverController *hotSpotPopover;
@property (nonatomic, strong) NSMutableArray *popoverOptions;
@property int currentFBIndex;
@property int currentSocialIndex;

@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@property (nonatomic, retain) IBOutlet UIView* sideSwipeView;
@property (nonatomic, retain) UITableViewCell* sideSwipeCell;
@property (nonatomic) UISwipeGestureRecognizerDirection sideSwipeDirection;
@property (nonatomic,retain) NSMutableArray *sharedPost;
@property (nonatomic,retain) NSMutableArray *sharedTweet;

@end

@implementation ECModalVideoAdViewController_iPhone

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
    self.socialData = [NSMutableArray array];
    self.hotSpotRect = [NSMutableDictionary dictionary];
    self.currentFBIndex = self.currentFBIndex = selectedImage = -1;
    // To Parse the JSON response
    if (nil == self.responseDict)
        [self fetchData];
    else {
        [self setupVideoPlayerForiPhone];
        [self setupGalleryTableView];
        [self setupSocialViewForLandscape];
        [self layoutTableViewFrame:self.interfaceOrientation];
        [self.view bringSubviewToFront:self.spinner];
        
        [self fetchGalleryImages];
    }
     [self generateHotSpotFrames];
    self.popoverOptions = [NSMutableArray arrayWithObjects:@"Like us on Twitter",@"Like us on Facebook",@"Special Offers",@"Find a Dealer", nil];
    
    animatingSideSwipe = NO;
    
    self.sharedPost = [NSMutableArray array];
    self.sharedTweet = [NSMutableArray array];
    //    buttonData = [[NSArray alloc] initWithObjects:
    //                   [NSDictionary dictionaryWithObjectsAndKeys:@"Post", @"title", @"post.png", @"image", nil],
    //                   [NSDictionary dictionaryWithObjectsAndKeys:@"Retweet", @"title", @"tweet.png", @"image", nil],
    //                   nil];
    //    buttons = [[NSMutableArray alloc] initWithCapacity:buttonData.count];
    
	// Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(playbackFinished:)
                                                name:UIApplicationDidEnterBackgroundNotification
                                              object:nil];

}

- (void)fetchGalleryImages {
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
    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(slideSocialContent) userInfo:nil repeats:YES];
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
        [self.socialData addObject:socialFeed];
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
    
    NSString *path = [NSString stringWithFormat:@"http://devefence.engageclick.com/ecadserve/ecvideoFlash?mediaIdExternal=2&mediaSystemId=1&flashFormat=FSALL"];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:path]] ;
    
    
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
                [self setupVideoPlayerForiPhone];
                [self setupGalleryTableView];
                [self setupSocialViewForLandscape];
                [self layoutTableViewFrame:self.interfaceOrientation];
                [self.view bringSubviewToFront:self.spinner];
                
                [self fetchGalleryImages];
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



- (void) setupVideoPlayerForiPhone {
    
    NSDictionary *data =  [self.responseDict objectForKey:@"data"];
    self.moviePlayer = [[EcAdCustomPlayer alloc] initWithContentURL:[NSURL URLWithString: [data objectForKey:@"media"]]];
    [(EcAdCustomPlayer *)self.moviePlayer setTargetURL:[self.responseDict objectForKey:@"targeturl"]];

    self.moviePlayer.view.frame = CGRectMake(10, 20, 300, 200);
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
    [self.closeButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin| UIViewAutoresizingFlexibleBottomMargin];
    [self.closeButton setImage:[UIImage imageWithData:[self.delegate loadFile:@"close_Icon.png"]] forState:UIControlStateNormal];
    [self.galleryImageView addSubview:self.closeButton];
    
    CGRect frame = self.galleryImageView.bounds;
    frame.size = CGSizeMake(30, 30);
    frame.origin.x = self.galleryImageView.frame.size.width - frame.size.width;
    frame.origin.y = 0;
    self.closeButton.frame = frame;
    
    
    // Thug Label - To DIsplay seconds
    
    self.thugLabel = [[UILabel alloc] init];
    //    self.thugLabel.text = [NSString stringWithFormat:@"Your Ad will end in %.0f seconds",ceil((self.moviePlayer.duration -  self.moviePlayer.currentPlaybackTime))];
    self.thugLabel.textColor = [UIColor whiteColor];
    [self.thugLabel setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.thugLabel];
    
    frame = self.view.frame;
    frame.origin.x = 10;
    frame.origin.y = 5;
    frame.size = CGSizeMake(250, 20);
    self.thugLabel.frame = frame;
    
    // Create a Timer To Check for the time
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackChanged:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:self.moviePlayer];
    
    NSArray *itemArray = [NSArray arrayWithObjects: @"Gallery", @"Facebook", @"Twitter", nil];
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    self.segmentedControl.frame = CGRectMake(self.moviePlayer.view.frame.origin.x, self.moviePlayer.view.frame.origin.y+self.moviePlayer.view.frame.size.height+2, self.moviePlayer.view.frame.size.width, 30);
    self.segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    self.segmentedControl.selectedSegmentIndex = 0;
    [self.segmentedControl setTintColor:[UIColor orangeColor]];
    [self.segmentedControl addTarget:self action:@selector(segmentSelected) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.segmentedControl];
    
    
    self.viewCloseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.viewCloseBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"black_Close.png"]] forState:UIControlStateNormal];
    [self.viewCloseBtn addTarget:self action:@selector(viewCloseBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.viewCloseBtn];
    [self.viewCloseBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    CGRect rect = self.view.bounds;
    rect.origin.x = rect.size.width - 40;
    rect.origin.y = 5;
    rect.size = CGSizeMake(30, 30);
    self.viewCloseBtn.frame = rect;
    [self.view bringSubviewToFront:self.viewCloseBtn];
}

- (void)viewCloseBtnClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"userAdClose"];

    if ([self.delegate respondsToSelector:@selector(adVideoDidFinishPlayback)])
        [self.delegate performSelector:@selector(adVideoDidFinishPlayback)];
    
}
- (void)segmentSelected {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case 0: {
            self.socialTableView.hidden = YES;
            self.galleryTableView.hidden = NO;
        }
            break;
        default:
            [self revealSocialTableView];
            break;
    }
}

- (void)revealSocialTableView {
    if (nil == self.socialTableView) {
        self.socialTableView = [[UITableView alloc] initWithFrame:self.galleryTableView.frame];
        self.socialTableView.delegate = self;
        self.socialTableView.dataSource = self;
        [self.view addSubview:self.socialTableView];
        [self.socialTableView setSeparatorColor:[UIColor orangeColor]];
        [self.socialTableView setBackgroundColor:[UIColor blackColor]];
        [self.socialTableView setShowsHorizontalScrollIndicator:NO];
        [self.socialTableView setShowsVerticalScrollIndicator:NO];
        
    }
    self.sideSwipeView = [[UIView alloc] initWithFrame:CGRectMake(self.socialTableView.frame.origin.x, self.socialTableView.frame.origin.y, self.socialTableView.frame.size.width, self.socialTableView.rowHeight)];
    [self setupSideSwipeView];
    [self setupGestureRecognizers];
    
    self.socialTableView.frame = self.galleryTableView.frame;
    self.galleryTableView.hidden = YES;
    self.socialTableView.hidden = NO;
    [self.socialTableView reloadData];
    
}
- (void) setupSideSwipeView
{
    // Add the background pattern
    self.sideSwipeView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithData:[self.delegate loadFile:@"dotted-pattern.png"]]];
    
    // Overlay a shadow image that adds a subtle darker drop shadow around the edges
    UIImage *shadow = [[UIImage imageWithData:[self.delegate loadFile:@"inner-shadow.png"] ] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    UIImageView* shadowImageView = [[UIImageView alloc] initWithFrame:self.sideSwipeView.frame];
    shadowImageView.alpha = 0.6;
    shadowImageView.image = shadow;
    shadowImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.sideSwipeView addSubview:shadowImageView];
    // Iterate through the button data and create a button for each entry
    CGFloat leftEdge = BUTTON_LEFT_MARGIN;
    CGRect frame = CGRectMake(5, 20, 20, 20);
    for (NSDictionary* buttonInfo in buttonData)
    {
        // Create the button
        UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        // Make sure the button ends up in the right place when the cell is resized
        button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        
        // Get the button image
        UIImage* buttonImage = [UIImage imageNamed:[buttonInfo objectForKey:@"image"]];
        
        // Set the button's frame
        button.frame = frame;//CGRectMake(leftEdge, self.sideSwipeView.center.y - buttonImage.size.height/2.0, buttonImage.size.width, buttonImage.size.height);
        //button.frame = CGRectMake(5, 0, 20, 20);
        
        // Add the image as the button's background image
        // [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
        UIImage* grayImage = [self imageFilledWith:[UIColor colorWithWhite:0.9 alpha:1.0] using:buttonImage];
        [button setImage:grayImage forState:UIControlStateNormal];
        
        // Add a touch up inside action
        [button addTarget:self action:@selector(touchUpInsideAction:) forControlEvents:UIControlEventTouchUpInside];
        
        // Keep track of the buttons so we know the proper text to display in the touch up inside action
        [buttons addObject:button];
        
        // Add the button to the side swipe view
        [self.sideSwipeView addSubview:button];
        
        // Move the left edge in prepartion for the next button
        leftEdge = leftEdge + buttonImage.size.width + BUTTON_SPACING;
        frame = CGRectMake(5, 5, 20, 20);
    }
}

#pragma mark - Social Sharing
- (void) touchUpInsideAction:(UIButton*)button {
    [self.moviePlayer pause];
    NSIndexPath* indexPath = [self.socialTableView indexPathForCell:self.sideSwipeCell];
    NSMutableDictionary *content = [NSMutableDictionary dictionary];
    NSUInteger index = self.segmentedControl.selectedSegmentIndex;//[buttons indexOfObject:button];
    //NSDictionary* buttonInfo = [buttonData objectAtIndex:index];
    
    switch (index) {
        case 1: {
            NSArray *keys = [self.fbContentDict allKeys];
            NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
            keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
            
            NSDictionary *fbContent = [self.fbContentDict objectForKey:[keys objectAtIndex:indexPath.row]];
            NSString *fbURL = [fbContent objectForKey:@"clickurl"] ;
            if ([fbURL length])
                [content setObject:fbURL forKey:@"link"];
            [content setObject:[self.socialImages objectForKey:[fbContent objectForKey:@"picture"]] forKey:@"image"];
            [content setObject:[fbContent objectForKey:@"message"] forKey:@"title"];
            [self postFeed:SLServiceTypeFacebook content:content];
        }
            break;
        case 2: {
            NSArray *keys = [self.twitterContentDict allKeys];
            NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
            keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
            
            NSDictionary *fbContent = [self.twitterContentDict objectForKey:[keys objectAtIndex:indexPath.row]];
            NSString *fbURL = [self getTwitterLink:[fbContent objectForKey:@"message"]] ;
            if ([fbURL length])
                [content setObject:fbURL forKey:@"link"];
            [content setObject:[self.socialImages objectForKey:[fbContent objectForKey:@"iconurl"]] forKey:@"image"];
            [content setObject:[fbContent objectForKey:@"message"] forKey:@"title"];
            
            [self postFeed:SLServiceTypeTwitter content:content];
        }
            break;
        default:
            break;
    }
    
}

- (void)postFeed:(NSString *)serviceType content:(NSMutableDictionary *)contentDict {
    if([SLComposeViewController isAvailableForServiceType:serviceType]) {
        
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:serviceType];
        
        SLComposeViewControllerCompletionHandler myBlock = ^(SLComposeViewControllerResult result){
            if (result == SLComposeViewControllerResultCancelled) {
                ECLog(@"ResultCancelled");
            } else
            {
                NSIndexPath* indexPath = [self.socialTableView indexPathForCell:self.sideSwipeCell];
                if (serviceType == SLServiceTypeFacebook)
                    [self.sharedPost addObject:[NSString stringWithFormat:@"%d",indexPath.row]];
                else
                    [self.sharedTweet addObject:[NSString stringWithFormat:@"%d",indexPath.row]];
                
                ECLog(@"Success");
            }
            if (self.sideSwipeView) {
                [UIView animateWithDuration:0.3 animations:^{
                    [self.sideSwipeView removeFromSuperview];
                    self.sideSwipeCell.frame = CGRectMake(0,self.sideSwipeCell.frame.origin.y,self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
                    self.sideSwipeCell = nil;
                    [self.socialTableView reloadData];
                }];
            }
            [self.moviePlayer play];
            [controller dismissViewControllerAnimated:YES completion:nil];
        };
        controller.completionHandler =myBlock;
        
        //        [controller setInitialText:@"Learn iOS6 Social Framework integration"];
        //        [controller addURL:[NSURL URLWithString:@"http://www.yashesh87.wordpress.com"]];
        //        [controller addImage:[UIImage imageNamed:@"salmantiger.jpeg"]];
        [controller setInitialText:[contentDict objectForKey:@"title"]];
        [controller addURL:[NSURL URLWithString:[contentDict objectForKey:@"link"]]];
        [controller addImage:[contentDict objectForKey:@"image"]];
        
        [self presentViewController:controller animated:YES completion:Nil];
        
    }
    else{
        
        ECLog(@"UnAvailable");
    }
    
    
}


#pragma Media Player Notification

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

- (void)setupGalleryTableView {
    CGRect tableFrame = self.moviePlayer.view.frame;
    tableFrame.origin.y += tableFrame.size.height+40;
    
    //    tableFrame.size.width = 400;
    tableFrame.size.height = 300;
    self.galleryTableView = [[UITableView alloc] initWithFrame:tableFrame];
    [self.view addSubview:self.galleryTableView];
    self.galleryTableView.delegate = self;
    self.galleryTableView.dataSource = self;
    [self.galleryTableView setBackgroundColor:[UIColor blackColor]];
    [self.galleryTableView setSeparatorColor:[UIColor blackColor]];
    [self.galleryTableView setShowsVerticalScrollIndicator:NO];
    [self.galleryTableView setShowsHorizontalScrollIndicator:NO];
    [self.galleryTableView setShowsVerticalScrollIndicator:NO];
    
}


#pragma mark - Social Content

- (void)setupSocialViewForLandscape {
    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y = self.view.frame.size.height - 200;
    viewFrame.size.width = self.moviePlayer.view.frame.size.width;
    viewFrame.size.height = 100;
    viewFrame.origin.x = self.moviePlayer.view.frame.origin.x;
    self.socialView = [[UIView alloc] initWithFrame:viewFrame];
    [self.view addSubview:self.socialView];
    [self.socialView setBackgroundColor:[UIColor blackColor]];
    [self setupInnerContentForSocialView];
    //[self setupInnerContentForFBSocialView];
    [self.socialView setAlpha:0.0];
    [self.socialView setHidden:YES];
}

- (void)slideSocialContent {
    if ([self.socialData count]) {
        if ([self.socialView isHidden] && UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            [self.socialView setHidden:NO];
            [UIView animateWithDuration:0.5 animations:^{
                [self.socialView setAlpha:1.0];
            }];
        }
        
        if (self.currentSocialIndex == -1)
            self.currentSocialIndex = 0;
        else {
            int index = self.currentSocialIndex+1;
            if (index >= [self.socialData count])
                index = 0;
            self.currentSocialIndex = index;
        }
        
        NSDictionary *fbContent = [self.socialData objectAtIndex:self.currentSocialIndex];
        self.socialUserName.text = [fbContent objectForKey:@"username"];
        self.socialDescTextView.text = [fbContent objectForKey:@"message"];
        BOOL isTwitter = [[fbContent objectForKey:@"source"] isEqualToString:@"Twitter"] ? YES : NO;
        
        if (isTwitter) {
            self.socialImageView.image = [self.socialImages objectForKey:[fbContent objectForKey:@"iconurl"]];
            self.recentTweetLbl.text = @"Recent Tweet";
            [self.socialButton removeTarget:self action:@selector(fbButtonClicked) forControlEvents:UIControlEventTouchUpInside];
            [self.socialButton setImage:[UIImage imageWithData:[self.delegate loadFile:@"twitter_Icon.png"]] forState:UIControlStateNormal];
            [self.socialButton addTarget:self action:@selector(twitterButtonClicked) forControlEvents:UIControlEventTouchUpInside];
            
        }
        else {
            self.socialImageView.image = [self.socialImages objectForKey:[fbContent objectForKey:@"picture"]];
            self.recentTweetLbl.text = @"Recent Post";
            [self.socialButton removeTarget:self action:@selector(twitterButtonClicked) forControlEvents:UIControlEventTouchUpInside];
            [self.socialButton setImage:[UIImage imageWithData:[self.delegate loadFile:@"fb_Icon.png"]] forState:UIControlStateNormal];
            [self.socialButton addTarget:self action:@selector(fbButtonClicked) forControlEvents:UIControlEventTouchUpInside];
            
            
        }
        [self.socialButton setHidden:NO];
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
    self.socialImageView = [[UIImageView alloc] init];
    [self.socialView addSubview:self.socialImageView];
    CGRect frame = self.socialView.bounds;
    frame.size.width = 50;
    frame.size.height = 50;
    self.socialImageView.frame = frame;
    [self.socialImageView setContentMode:UIViewContentModeScaleAspectFit];
    
    // User Name Label
    
    self.socialUserName = [[UILabel alloc] init];
    //self.socialUserName.text = @"User Name";
    [self.socialView addSubview:self.socialUserName];
    [self.socialUserName setBackgroundColor:[UIColor clearColor]];
    //    [self.socialUserName setFont:[UIFont boldSystemFontOfSize:20]];
    UIFont *font = [UIFont fontWithName:@"Georgia-Bold" size:14.0];
    self.socialUserName.font = font;
    frame = self.socialImageView.frame;
    frame.origin.x += frame.size.width + 5;
    frame.size.width = 230;
    frame.size.height = 20;
    self.socialUserName.frame = frame;
    
    [self.socialUserName setTextColor:[UIColor whiteColor]];
    
    //Recent Tweet
    
    self.recentTweetLbl = [[UILabel alloc] init];
    //self.recentTweetLbl.text = @"Recent Tweet";
    [self.recentTweetLbl setTextAlignment:NSTextAlignmentLeft];
    [self.socialView addSubview:self.recentTweetLbl];
    
    CGRect lblFrame = self.socialUserName.frame;
    lblFrame.origin.x += lblFrame.size.width;
    lblFrame.size.width = 140;
    self.recentTweetLbl.frame = lblFrame;
    [self.recentTweetLbl setBackgroundColor:[UIColor clearColor]];
    [self.recentTweetLbl setTextColor:[UIColor whiteColor]];
    
    font = [UIFont fontWithName:@"Georgia-Italic" size:12];
    self.recentTweetLbl.font = font;
    //    [self.recentTweetLbl setFont:[UIFont italicSystemFontOfSize:20]];
    
    
    // Twitter Icon
    
    self.socialButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.socialButton setImage:[UIImage imageWithData:[self.delegate loadFile:@"twitter_Icon.png"]] forState:UIControlStateNormal];
    [self.socialButton addTarget:self action:@selector(twitterButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.socialView addSubview:self.socialButton];
    self.socialButton.frame = CGRectMake(self.recentTweetLbl.frame.origin.x+self.recentTweetLbl.frame.size.width, self.recentTweetLbl.frame.origin.y, 25, 25);
    [self.socialButton setHidden:YES];
    // Descrition TextView
    
    self.socialDescTextView = [[UITextView alloc] init];
    [self.socialDescTextView setBackgroundColor:[UIColor clearColor]];
    self.socialDescTextView.dataDetectorTypes = UIDataDetectorTypeLink;
    font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:12];
    self.socialDescTextView.font = font;
    //[self.socialDescTextView setText:@"Speeding ticket for a CLA in Switzerland? @caseyneistat, do you know anything about this? http://t.co/rOltiKP8wT"];
    [self.socialDescTextView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    frame = self.socialImageView.frame;
    frame.size.width = self.socialView.frame.size.width-30;
    frame.origin.x = self.socialUserName.frame.origin.x-3;
    frame.origin.y = self.socialUserName.frame.origin.y + self.socialUserName.frame.size.height+3;
    self.socialDescTextView.frame = frame;
    [self.socialView addSubview:self.socialDescTextView];
    [self.socialDescTextView setEditable:NO];
    //  [self.socialDescTextView setFont:[UIFont systemFontOfSize:16]];
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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.galleryTableView reloadData];
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self layoutTableViewFrame:toInterfaceOrientation];
    //    [self.galleryTableView reloadData];
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
        self.segmentedControl.hidden =  NO;
        self.socialView.hidden = YES;
        CGRect rect = [[UIScreen mainScreen] bounds];
        if (rect.size.height > 480) {
            rect = self.moviePlayer.view.frame;
            rect.size.width = 300;
            self.moviePlayer.view.frame = rect;
        }
        
        
        CGRect tableFrame = self.moviePlayer.view.frame;
        tableFrame.origin.y += tableFrame.size.height+40;
        
        //tableFrame.size.width = 100;
        tableFrame.size.height = self.view.frame.size.height - tableFrame.origin.y;
        self.galleryTableView.frame = tableFrame;
        
        CGRect viewFrame = self.view.frame;
        viewFrame.origin.y = self.view.frame.size.height - 250;
        viewFrame.size.width = self.moviePlayer.view.frame.size.width;
        viewFrame.size.height = 220;
        viewFrame.origin.x = self.moviePlayer.view.frame.origin.x;
        self.socialView.frame = viewFrame;
        [self.view bringSubviewToFront:self.segmentedControl];
        
        
    }
    
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation))    {
        self.segmentedControl.hidden = YES;
        self.galleryTableView.hidden = NO;
        self.socialTableView.hidden = YES;
        
        [self.segmentedControl setSelectedSegmentIndex:0];
        CGRect rect = [[UIScreen mainScreen] bounds];
        CGRect viewFrame ;
        if (rect.size.height > 480) {
            rect = self.moviePlayer.view.frame;
            rect.size.width = 568 - 100 - 20;
            self.moviePlayer.view.frame = rect;
            
            CGRect tableFrame = self.moviePlayer.view.frame;
            tableFrame.origin.x += tableFrame.size.width+5;
            tableFrame.size.width = 100;
            //        tableFrame.size.height = 500;
            self.galleryTableView.frame = tableFrame;
            viewFrame = CGRectMake(0, 0, 568, 320);
        } else {
            CGRect tableFrame = self.moviePlayer.view.frame;
            tableFrame.origin.x += tableFrame.size.width+60;
            tableFrame.size.width = 100;
            //        tableFrame.size.height = 500;
            self.galleryTableView.frame = tableFrame;
            viewFrame = CGRectMake(0, 0, 480, 320);
            
        }
        
        
        viewFrame.origin.y = self.moviePlayer.view.frame.size.height+self.moviePlayer.view.frame.origin.y+2;
        viewFrame.size.width -= 20;
        viewFrame.size.height -= viewFrame.origin.y;
        viewFrame.origin.x = self.moviePlayer.view.frame.origin.x;
        self.socialView.frame = viewFrame;
        if ([self.socialData count]) {
            self.socialView.hidden = NO;
            self.socialView.alpha = 1.0;
            
        }
        //        if (self.socialView.alpha != 0) {
        //
        //            self.socialView.hidden = NO;
        //            self.socialView.alpha = 1.0;
        //        }
        
        
        
    }
    
    CGRect frame = self.socialFBImageView.frame;
    frame.size.width = self.socialView.frame.size.width - 80;
    frame.origin.x = self.socialFBUserName.frame.origin.x-3;
    frame.origin.y = self.socialFBUserName.frame.origin.y + self.socialFBUserName.frame.size.height+3;
    frame.size.height = 60;
    self.socialFBDescTextView.frame = frame;
    self.galleryImageView.frame = self.moviePlayer.view.frame;
    
    self.spinner.center = self.view.center;
    self.spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    
    [self.view bringSubviewToFront:self.socialView];
    
    frame = self.galleryImageView.bounds;
    frame.size = CGSizeMake(30, 30);
    frame.origin.x = self.galleryImageView.frame.size.width - frame.size.width;
    self.closeButton.frame = frame;
    
    [self.view bringSubviewToFront:self.viewCloseBtn];
}
- (void)closeButtonClicked {
    [self.moviePlayer.view setHidden:NO];
    [UIView animateWithDuration:0.5 animations:^{
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            [self.galleryImageView setAlpha:0.0];
        }
        else {
            self.galleryImageView.frame = self.moviePlayer.view.frame;
            [self.galleryImageView setAlpha:0.0];
        }
    } completion:^(BOOL finished) {
        [self.galleryImageView setAlpha:1.0];
        [self.galleryImageView setHidden:YES];
        [self.moviePlayer play];
    }];
}


#pragma mark - Swipe Methods

#pragma mark Side Swiping under iOS 4.x
- (BOOL) gestureRecognizersSupported
{
    if (!USE_GESTURE_RECOGNIZERS) return NO;
    
    // Apple's docs: Although this class was publicly available starting with iOS 3.2, it was in development a short period prior to that
    // check if it responds to the selector locationInView:. This method was not added to the class until iOS 3.2.
    return [[[UISwipeGestureRecognizer alloc] init] respondsToSelector:@selector(locationInView:)];
}

- (void) setupGestureRecognizers
{
    // Do nothing under 3.x
    if (![self gestureRecognizersSupported]) return;
    
    // Setup a right swipe gesture recognizer
    UISwipeGestureRecognizer* rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.socialTableView addGestureRecognizer:rightSwipeGestureRecognizer];
    
    // Setup a left swipe gesture recognizer
    UISwipeGestureRecognizer* leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.socialTableView addGestureRecognizer:leftSwipeGestureRecognizer];
}

// Called when a left swipe occurred
- (void)swipeLeft:(UISwipeGestureRecognizer *)recognizer
{
    [self swipe:recognizer direction:UISwipeGestureRecognizerDirectionLeft];
}

// Called when a right swipe ocurred
- (void)swipeRight:(UISwipeGestureRecognizer *)recognizer
{
    [self swipe:recognizer direction:UISwipeGestureRecognizerDirectionRight];
}

// Handle a left or right swipe
- (void)swipe:(UISwipeGestureRecognizer *)recognizer direction:(UISwipeGestureRecognizerDirection)direction
{
    if (recognizer && recognizer.state == UIGestureRecognizerStateEnded)
    {
        // Get the table view cell where the swipe occured
        CGPoint location = [recognizer locationInView:self.socialTableView];
        NSIndexPath* indexPath = [self.socialTableView indexPathForRowAtPoint:location];
        UITableViewCell* cell = [self.socialTableView cellForRowAtIndexPath:indexPath];
        
        // If we are already showing the swipe view, remove it
        if (cell.frame.origin.x != 0)
        {
            [self removeSideSwipeView:YES];
            return;
        }
        
        // Make sure we are starting out with the side swipe view and cell in the proper location
        [self removeSideSwipeView:NO];
        
        // If this isn't the cell that already has thew side swipe view and we aren't in the middle of animating
        // then start animating in the the side swipe view
        if (cell!= self.sideSwipeCell && !animatingSideSwipe && direction == UISwipeGestureRecognizerDirectionRight)
            [self addSwipeViewTo:cell direction:direction];
        
        if (direction == UISwipeGestureRecognizerDirectionRight)
            [self performSelector:@selector(touchUpInsideAction:) withObject:nil afterDelay:0.2];
        
    }
}

#pragma mark Adding the side swipe view
- (void) addSwipeViewTo:(UITableViewCell*)cell direction:(UISwipeGestureRecognizerDirection)direction
{
    // Change the frame of the side swipe view to match the cell
    self.sideSwipeView.frame = cell.frame;
    
    // Add the side swipe view to the table below the cell
    [self.socialTableView insertSubview:self.sideSwipeView belowSubview:cell];
    
    // Remember which cell the side swipe view is displayed on and the swipe direction
    self.sideSwipeCell = cell;
    self.sideSwipeDirection = direction;
    
    CGRect cellFrame = cell.frame;
    if (PUSH_STYLE_ANIMATION)
    {
        // Move the side swipe view offscreen either to the left or the right depending on the swipe direction
        self.sideSwipeView.frame = CGRectMake(direction == UISwipeGestureRecognizerDirectionRight ? -cellFrame.size.width : cellFrame.size.width, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
    }
    else
    {
        // Move the side swipe view to offset 0
        self.sideSwipeView.frame = CGRectMake(0, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
    }
    
    // Animate in the side swipe view
    animatingSideSwipe = YES;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStopAddingSwipeView:finished:context:)];
    if (PUSH_STYLE_ANIMATION)
    {
        // Move the side swipe view to offset 0
        // While simultaneously moving the cell's frame offscreen
        // The net effect is that the side swipe view is pushing the cell offscreen
        self.sideSwipeView.frame = CGRectMake(0, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
    }
    //    cell.frame = CGRectMake(direction == UISwipeGestureRecognizerDirectionRight ? cellFrame.size.width : -cellFrame.size.width, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
    cell.frame = CGRectMake(direction == UISwipeGestureRecognizerDirectionRight ? 30 : -30, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
    [UIView commitAnimations];
}

// Note that the animation is done
- (void)animationDidStopAddingSwipeView:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    animatingSideSwipe = NO;
}

#pragma mark Removing the side swipe view
// UITableViewDelegate
// When a row is selected, animate the removal of the side swipe view
- (NSIndexPath *)tableView:(UITableView *)theTableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self removeSideSwipeView:YES];
    return indexPath;
}

// UIScrollViewDelegate
// When the table is scrolled, animate the removal of the side swipe view
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self removeSideSwipeView:YES];
}

// When the table is scrolled to the top, remove the side swipe view
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    [self removeSideSwipeView:NO];
    return YES;
}

// Remove the side swipe view.
// If animated is YES, then the removal is animated using a bounce effect
- (void) removeSideSwipeView:(BOOL)animated
{
    // Make sure we have a cell where the side swipe view appears and that we aren't in the middle of animating
    if (!self.sideSwipeCell || animatingSideSwipe) return;
    
    if (animated)
    {
        // The first step in a bounce animation is to move the side swipe view a bit offscreen
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        if (self.sideSwipeDirection == UISwipeGestureRecognizerDirectionRight)
        {
            if (PUSH_STYLE_ANIMATION)
                self.sideSwipeView.frame = CGRectMake(-self.sideSwipeView.frame.size.width + BOUNCE_PIXELS,self.sideSwipeView.frame.origin.y,self.sideSwipeView.frame.size.width, self.sideSwipeView.frame.size.height);
            self.sideSwipeCell.frame = CGRectMake(BOUNCE_PIXELS, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
        }
        else
        {
            if (PUSH_STYLE_ANIMATION)
                self.sideSwipeView.frame = CGRectMake(self.sideSwipeView.frame.size.width - BOUNCE_PIXELS,self.sideSwipeView.frame.origin.y,self.sideSwipeView.frame.size.width, self.sideSwipeView.frame.size.height);
            self.sideSwipeCell.frame = CGRectMake(-BOUNCE_PIXELS, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
        }
        animatingSideSwipe = YES;
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStopOne:finished:context:)];
        [UIView commitAnimations];
    }
    else
    {
        [self.sideSwipeView removeFromSuperview];
        self.sideSwipeCell.frame = CGRectMake(0,self.sideSwipeCell.frame.origin.y,self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
        self.sideSwipeCell = nil;
    }
}

#pragma mark Bounce animation when removing the side swipe view
// The next step in a bounce animation is to move the side swipe view a bit on screen
- (void)animationDidStopOne:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    if (self.sideSwipeDirection == UISwipeGestureRecognizerDirectionRight)
    {
        if (PUSH_STYLE_ANIMATION)
            self.sideSwipeView.frame = CGRectMake(-self.sideSwipeView.frame.size.width + BOUNCE_PIXELS*2,self.sideSwipeView.frame.origin.y,self.sideSwipeView.frame.size.width, self.sideSwipeView.frame.size.height);
        self.sideSwipeCell.frame = CGRectMake(BOUNCE_PIXELS*2, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
    }
    else
    {
        if (PUSH_STYLE_ANIMATION)
            self.sideSwipeView.frame = CGRectMake(self.sideSwipeView.frame.size.width - BOUNCE_PIXELS*2,self.sideSwipeView.frame.origin.y,self.sideSwipeView.frame.size.width, self.sideSwipeView.frame.size.height);
        self.sideSwipeCell.frame = CGRectMake(-BOUNCE_PIXELS*2, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
    }
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStopTwo:finished:context:)];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView commitAnimations];
}

// The final step in a bounce animation is to move the side swipe completely offscreen
- (void)animationDidStopTwo:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    [UIView commitAnimations];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    if (self.sideSwipeDirection == UISwipeGestureRecognizerDirectionRight)
    {
        if (PUSH_STYLE_ANIMATION)
            self.sideSwipeView.frame = CGRectMake(-self.sideSwipeView.frame.size.width ,self.sideSwipeView.frame.origin.y,self.sideSwipeView.frame.size.width, self.sideSwipeView.frame.size.height);
        self.sideSwipeCell.frame = CGRectMake(0, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
    }
    else
    {
        if (PUSH_STYLE_ANIMATION)
            self.sideSwipeView.frame = CGRectMake(self.sideSwipeView.frame.size.width ,self.sideSwipeView.frame.origin.y,self.sideSwipeView.frame.size.width, self.sideSwipeView.frame.size.height);
        self.sideSwipeCell.frame = CGRectMake(0, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
    }
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStopThree:finished:context:)];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView commitAnimations];
}

// When the bounce animation is completed, remove the side swipe view and reset some state
- (void)animationDidStopThree:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    animatingSideSwipe = NO;
    self.sideSwipeCell = nil;
    [self.sideSwipeView removeFromSuperview];
}


#pragma mark -
#pragma mark TableView Data Source
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.segmentedControl.selectedSegmentIndex == 0)
        return 10.0;
    return 0.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor clearColor]];
    return view;
}
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    int count = [self.imageDict count];
    if (!self.segmentedControl.hidden) {
        switch (self.segmentedControl.selectedSegmentIndex) {
            case 0:
                count = self.imageDict.count;
                break;
            case 1:
                count = self.fbContentDict.count;
                break;
            case 2:
                count = self.twitterContentDict.count;
                break;
            default:
                break;
        }
    }
    else
        count = [self.imageDict count];
    return count;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            return 100;//120;
        }
        return 180;
    }
    else
        return 100;
}

#pragma mark - TableView Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    UITableViewCell *cell = nil;//[tableView dequeueReusableCellWithIdentifier:@"Identifier"];
    
    
    switch (self.segmentedControl.selectedSegmentIndex) {
        case 0: {
            if (!cell) {
                cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GalleryIdentifier"];
                [cell setBackgroundColor:tableView.backgroundColor];
            }
            //            [cell.contentView addSubview:[self getSelectedBGView]];
            [cell setBackgroundView:[self getContentViewForIndexpath:indexPath]];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
            break;
        case 1: {
            if (!cell) {
                cell = [[SideSwipeTableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"FBIdentifier"];
                [cell setBackgroundColor:tableView.backgroundColor];
                
                UIButton *fbButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [fbButton setImage:[UIImage imageWithData:[self.delegate loadFile:@"fb_Icon.png"]] forState:UIControlStateNormal];
                [fbButton addTarget:self action:@selector(fbButtonClicked) forControlEvents:UIControlEventTouchUpInside];
                // [baseView addSubview:fbButton];
                fbButton.frame = CGRectMake(self.socialTableView.frame.size.width - 40, 5, 25, 25);
                [cell addSubview:fbButton];
                [(SideSwipeTableViewCell *)cell setSupressDeleteButton:![self gestureRecognizersSupported]];
                
            }
            
            NSArray *keys = [self.fbContentDict allKeys];
            NSDictionary *fbContent = [self.fbContentDict objectForKey:[keys objectAtIndex:indexPath.row]];
            
            NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
            keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
            
            //            [cell setBackgroundView:[self getFBContentViewForContent:fbContent]];
            [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
            [cell addSubview:[self getFBContentViewForContent:fbContent index:indexPath.row]];
            
            
            
        }
            break;
        case 2: {
            NSArray *keys = [self.twitterContentDict allKeys];
            
            if (!cell) {
                cell = [[SideSwipeTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TwitterIdentifier"];
                [cell setBackgroundColor:tableView.backgroundColor];
                UIButton *twitterButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [twitterButton setImage:[UIImage imageWithData:[self.delegate loadFile:@"twitter_Icon.png"]] forState:UIControlStateNormal];
                [twitterButton addTarget:self action:@selector(twitterButtonClicked) forControlEvents:UIControlEventTouchUpInside];
                twitterButton.frame = CGRectMake(self.socialTableView.frame.size.width - 40, 5, 25, 25);
                [cell addSubview:twitterButton];
                [(SideSwipeTableViewCell *)cell setSupressDeleteButton:![self gestureRecognizersSupported]];
                
            }
            
            NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
            keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
            
            NSDictionary *twitterContent = [self.twitterContentDict objectForKey:[keys objectAtIndex:indexPath.row]];
            [cell setBackgroundView:[self getTwitterContentViewForContent:twitterContent index:indexPath.row]];
            
            
            [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
            
        }
            break;
            
        default:
            break;
    }
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    
    if (indexPath.row == selectedImage) {
        return;
    }
    switch (self.segmentedControl.selectedSegmentIndex) {
        case 0: {
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
            [self removeHotspotBtns];

            [UIView animateWithDuration:0.5 animations:^{
                if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))    {
                    [self.galleryImageView setContentMode:UIViewContentModeScaleAspectFill];
                    CGRect frame = self.galleryImageView.bounds;
                    frame.size = CGSizeMake(30, 30);
                    frame.origin.x = self.galleryImageView.frame.size.width - frame.size.width;
                    frame.origin.y = 0;
                    self.closeButton.frame = frame;
                    
                }
                else {
                    [self.galleryImageView setFrame:self.view.bounds];
                    [self.view bringSubviewToFront:self.galleryImageView];
                    [self.galleryImageView setContentMode:UIViewContentModeScaleAspectFit];
                    
                }
                
                [self.galleryImageView setAlpha:1.0];
            } completion:^(BOOL finished) {
                [self generateHotSpots];

            }];
        }
            break;
        case 1: {
            NSArray *keys = [self.fbContentDict allKeys];
            NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
            keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
            
            NSDictionary *fbContent = [self.fbContentDict objectForKey:[keys objectAtIndex:indexPath.row]];
            if ([[fbContent objectForKey:@"clickurl"] length]) {
                [[ECAdManager sharedManager] videoAdLandingPageOpened:[fbContent objectForKey:@"clickurl"]];

                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[fbContent objectForKey:@"clickurl"]]];
            }
        }
            break;
        case 2: {
            NSArray *keys = [self.twitterContentDict allKeys];
            NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
            keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
            
            NSDictionary *fbContent = [self.twitterContentDict objectForKey:[keys objectAtIndex:indexPath.row]];
            if ([[fbContent objectForKey:@"message"] length]) {
                NSString *tweet = [self getTwitterLink:[fbContent objectForKey:@"message"]];
                [[ECAdManager sharedManager] videoAdLandingPageOpened:tweet];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:tweet]];
            }
            
        }
            break;
            
        default:
            break;
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
- (UIView *)getSelectedBGView {
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor orangeColor]];
    return view;
}
- (UIImageView *)getContentViewForIndexpath:(NSIndexPath *)indexPath {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.image = [self.imageDict objectForKey:[NSString stringWithFormat:@"%d",indexPath.row]];
    [imageView setTag:indexPath.row + ECAdGalleryImageTag];
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
        [imageView setContentMode:UIViewContentModeScaleAspectFit];
    else
        [imageView setContentMode:UIViewContentModeScaleToFill];
    
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

- (UIView *)getFBContentViewForContent:(NSDictionary *)fbContent index:(int)index{
    UIView *baseView = [[UIView alloc] init];
    [baseView setBackgroundColor:[UIColor redColor]];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 50, 50)];
    [imageView setContentMode:UIViewContentModeScaleToFill];
    [baseView addSubview:imageView];
    imageView.image =  [self.socialImages objectForKey:[fbContent objectForKey:@"picture"]];
    
    
    if ([self.sharedPost containsObject:[NSString stringWithFormat:@"%d",index]]) {
        UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        [iconView setContentMode:UIViewContentModeScaleToFill];
        [imageView addSubview:iconView];
        iconView.image = [UIImage imageWithData:[self.delegate loadFile:@"tick.png"]];
        
    }
    UILabel *userName = [[UILabel alloc] initWithFrame:CGRectMake(imageView.frame.origin.x + imageView.frame.size.width+2, imageView.frame.origin.y, 120, 20)];
    [userName setBackgroundColor:[UIColor blackColor]];
    [userName setTextColor:[UIColor whiteColor]];
    //    [userName setFont:[UIFont boldSystemFontOfSize:12]];
    
    
    UIFont *font = [UIFont fontWithName:@"Georgia-Bold" size:14.0];
    [userName setFont:font];
    
    
    [baseView addSubview:userName];
    [userName setText:[fbContent objectForKey:@"username"]];
    
    font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:12];
    /*
     UIButton *fbButton = [UIButton buttonWithType:UIButtonTypeCustom];
     [fbButton setImage:[UIImage imageNamed:@"fb_Icon.png"] forState:UIControlStateNormal];
     [fbButton addTarget:self action:@selector(fbButtonClicked) forControlEvents:UIControlEventTouchUpInside];
     [baseView addSubview:fbButton];
     fbButton.frame = CGRectMake(self.socialTableView.frame.size.width - 40, userName.frame.origin.y, 20, 20);*/
    
    UILabel *descView = [[UILabel alloc] initWithFrame:CGRectMake(userName.frame.origin.x, userName.frame.origin.y+userName.frame.size.height, 200, 60)];
    [descView setBackgroundColor:[UIColor blackColor]];
    [descView setTextColor:[UIColor whiteColor]];
    [descView setFont:[UIFont systemFontOfSize:12]];
    descView.font = font;
    [descView setNumberOfLines:0];
    descView.text = [fbContent objectForKey:@"message"];
    [baseView addSubview:descView];
    
    return baseView;
    //            self.socialFBUserName.text = [fbContent objectForKey:@"username"];
    //            self.socialFBDescTextView.text = [fbContent objectForKey:@"message"];
    //            self.socialFBImageView.image = [self.socialImages objectForKey:[fbContent objectForKey:@"picture"]];
    
}

- (UIView *)getTwitterContentViewForContent:(NSDictionary *)twitterContent index:(int)index {
    UIView *baseView = [[UIView alloc] init];
    [baseView setBackgroundColor:[UIColor blackColor]];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 50, 50)];
    [imageView setContentMode:UIViewContentModeScaleToFill];
    [baseView addSubview:imageView];
    imageView.image =  [self.socialImages objectForKey:[twitterContent objectForKey:@"iconurl"]];
    
    if ([self.sharedTweet containsObject:[NSString stringWithFormat:@"%d",index]]) {
        UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        [iconView setContentMode:UIViewContentModeScaleToFill];
        [imageView addSubview:iconView];
        iconView.image = [UIImage imageWithData:[self.delegate loadFile:@"tick.png"]];
    }
    
    UILabel *userName = [[UILabel alloc] initWithFrame:CGRectMake(imageView.frame.origin.x + imageView.frame.size.width+2, imageView.frame.origin.y, 120, 20)];
    [userName setBackgroundColor:[UIColor blackColor]];
    [userName setTextColor:[UIColor whiteColor]];
    UIFont *font = [UIFont fontWithName:@"Georgia-Bold" size:14.0];
    [userName setFont:font];
    
    [baseView addSubview:userName];
    [userName setText:[twitterContent objectForKey:@"username"]];
    font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:12];
    
    
    //    UIButton *twitterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //    [twitterButton setImage:[UIImage imageNamed:@"twitter_Icon.png"] forState:UIControlStateNormal];
    //    [twitterButton addTarget:self action:@selector(twitterButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    //    [baseView addSubview:twitterButton];
    //    twitterButton.frame = CGRectMake(self.socialTableView.frame.size.width - 40, userName.frame.origin.y, 20, 20);
    
    UILabel *descView = [[UILabel alloc] initWithFrame:CGRectMake(userName.frame.origin.x, userName.frame.origin.y+userName.frame.size.height, 200, 60)];
    [descView setBackgroundColor:[UIColor blackColor]];
    [descView setTextColor:[UIColor whiteColor]];
    //    [descView setFont:[UIFont systemFontOfSize:12]];
    descView.font = font;
    
    [descView setNumberOfLines:0];
    descView.text = [twitterContent objectForKey:@"message"];
    [baseView addSubview:descView];
    
    
    return baseView;
}

#pragma mark Generate images with given fill color
// Convert the image's fill color to the passed in color
-(UIImage*) imageFilledWith:(UIColor*)color using:(UIImage*)startImage
{
    // Create the proper sized rect
    CGRect imageRect = CGRectMake(0, 0, CGImageGetWidth(startImage.CGImage), CGImageGetHeight(startImage.CGImage));
    
    // Create a new bitmap context
    CGContextRef context = CGBitmapContextCreate(NULL, imageRect.size.width, imageRect.size.height, 8, 0, CGImageGetColorSpace(startImage.CGImage), kCGImageAlphaPremultipliedLast);
    
    // Use the passed in image as a clipping mask
    CGContextClipToMask(context, imageRect, startImage.CGImage);
    // Set the fill color
    CGContextSetFillColorWithColor(context, color.CGColor);
    // Fill with color
    CGContextFillRect(context, imageRect);
    
    // Generate a new image
    CGImageRef newCGImage = CGBitmapContextCreateImage(context);
    UIImage* newImage = [UIImage imageWithCGImage:newCGImage scale:startImage.scale orientation:startImage.imageOrientation];
    
    // Cleanup
    CGContextRelease(context);
    CGImageRelease(newCGImage);
    
    return newImage;
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
   /* for (int i = 0 ; i < ECADMaxHotSpots ; i++) {
        UIButton *hotspotView = (UIButton *) [self.galleryImageView viewWithTag:ECADHotSpotViewTag+i];
        CGRect frame = hotspotView.frame;
        if (frame.origin.y >= self.galleryImageView.frame.size.height) {
            frame.origin.y = (self.galleryImageView.frame.size.height - frame.size.height)+10;
            if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))    {
                frame.origin.y -= (frame.size.height - 10);
            }
        }
        else
            frame.origin.y = self.galleryImageView.frame.size.height;
        [UIView animateWithDuration:0.5 animations:^{
            hotspotView.frame = frame;
        }];
    }*/
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"hotspotClicked"];

    int idx = sender.tag-ECADHotSpotTag;
    currentHotspot = idx;
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

- (void)willPresentActionSheet1:(UIActionSheet *)actionSheet {
    UIImage *theImage = [UIImage imageWithData:[self.delegate loadFile:@"popoverBG1.png"]];
    theImage = [theImage stretchableImageWithLeftCapWidth:32 topCapHeight:32];
    CGSize theSize = actionSheet.frame.size;
    // draw the background image and replace layer content
    UIGraphicsBeginImageContext(theSize);
    [theImage drawInRect:CGRectMake(0, 0, theSize.width, theSize.height)];
    theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [[actionSheet layer] setContents:(id)theImage.CGImage];
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
        NSArray *arr = [spots objectAtIndex:currentHotspot];
         url = [[arr objectAtIndex:buttonIndex] objectForKey:@"link"];
    }
    if ([url length]) {
        [[ECAdManager sharedManager] videoAdLandingPageOpened:url];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
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
    
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self.moviePlayer];
    
    self.moviePlayer = nil;
}
@end
