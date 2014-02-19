//
//  ECModalViewRegionalViewController.m
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 6/10/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import "ECModalViewRegionalViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ECAdManager.h"
#import "EcAdCustomPlayer.h"

@interface ECModalViewRegionalViewController () {
    int adCount;
    NSTimer *thugTimer;
}
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) UILabel *thugLabel;
@end

@implementation ECModalViewRegionalViewController

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
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.spinner setCenter:self.view.center];
    [self.view addSubview:self.spinner];
    [self.spinner setHidesWhenStopped:YES];
    [self.spinner startAnimating];
    self.spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    
    NSDictionary *dict = [self.responseDict objectForKey:@"data"];
    self.primaryURL = [dict objectForKey:@"media"];
    self.secondaryURL = [dict objectForKey:@"regionalad"];
    self.adDuration = [[dict objectForKey:@"adDuration"] doubleValue];
    [self setupVideoPlayer];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(playbackFinished:)
                                                name:UIApplicationDidEnterBackgroundNotification
                                              object:nil];
}

- (NSData *)loadFile:(NSString *)name {
    return [[ECAdManager sharedManager] loadFile:name];
}

- (void)setupVideoPlayer {
//    NSDictionary *data =  [self.responseDict objectForKey:@"data"];
    adCount = 1;
    self.moviePlayer = [[EcAdCustomPlayer alloc] initWithContentURL:[NSURL URLWithString:self.primaryURL]];
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
    [closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"black_Close.png"]] forState:UIControlStateNormal];
    [closeBtn addTarget:self.delegate action:@selector(adVideoDidFinishPlayback) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];
    [closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    CGRect rect = self.view.bounds;
    rect.origin.x = rect.size.width - 40;
    rect.origin.y = 5;
    rect.size = CGSizeMake(40, 40);
    closeBtn.frame = rect;
    
    // Thug Label - To DIsplay seconds
    
    self.thugLabel = [[UILabel alloc] init];
    //    self.thugLabel.text = [NSString stringWithFormat:@"Your Ad will end in %.0f seconds",ceil((self.moviePlayer.duration -  self.moviePlayer.currentPlaybackTime))];
    self.thugLabel.textColor = [UIColor whiteColor];
    [self.thugLabel setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.thugLabel];
    
    CGRect frame = self.view.frame;
    frame.origin.x = 10;
    frame.origin.y = 10;
    frame.size = CGSizeMake(self.view.frame.size.width, 20);
    self.thugLabel.frame = frame;
    
    [self.moviePlayer.view bringSubviewToFront:closeBtn];
    
}
- (void)playbackChanged:(MPMoviePlayerController *)player {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.moviePlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self.moviePlayer selector:@selector(play) name:@"AppDidEnterForeground" object:nil];
    
    [self.spinner stopAnimating];
    [thugTimer invalidate];
    thugTimer = nil;
    
    thugTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    //    [self verticalFlip];
}

- (void)updateTime {
    if (adCount != 1)
        self.thugLabel.text = [NSString stringWithFormat:@"Your Ad will end in %.0f seconds",ceil((self.moviePlayer.duration -  self.moviePlayer.currentPlaybackTime))];
    else
        self.thugLabel.text = [NSString stringWithFormat:@"Your Ad will end in %.0f seconds",ceil(((self.adDuration + self.moviePlayer.duration) -  self.moviePlayer.currentPlaybackTime))];
}


- (void)playbackFinished:(MPMoviePlayerController *)player {
    if (adCount == 1) {
        self.moviePlayer.contentURL = [NSURL URLWithString:self.secondaryURL];
        [self.moviePlayer play];
        adCount ++;
    }
    else {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        if ([self.delegate respondsToSelector:@selector(adVideoDidFinishPlayback)])
            [self.delegate performSelector:@selector(adVideoDidFinishPlayback)];
    }
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


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self.moviePlayer];
    
    [self.moviePlayer stop];
    self.moviePlayer = nil;
    [thugTimer invalidate];
    thugTimer = nil;

}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self.moviePlayer];
    
    self.moviePlayer = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
