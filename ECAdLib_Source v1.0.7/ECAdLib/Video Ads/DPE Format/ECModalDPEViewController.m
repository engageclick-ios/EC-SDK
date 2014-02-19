//
//  ECModalDPEViewController.m
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/29/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import "ECModalDPEViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import "ECAdManager.h"
#import "EcAdCustomPlayer.h"
#import "ECAdCustomButton.h"
#import "MPGlobal.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>


#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define kLEFT_ARROW_TAG 2000
#define kRIGHT_ARROW_TAG 3000
#define kSCROLL_TAG 4000



@interface ECModalDPEViewController () {
    NSTimer *timer;
    CGRect homeRect;
}
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) EcAdCustomPlayer *moviePlayer;
@property (nonatomic, strong) UIButton *imageView;
@property (nonatomic, strong) UIImageView *img;
@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) UIButton *upBtn;
@property (nonatomic, strong) UIImage *logoImage;

@end

@implementation ECModalDPEViewController
@synthesize img;

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
    self.spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    if (nil == self.responseDict)
        [self fetchData];
    else
        [self downloadLogoImage];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(playbackFinished:)
                                                name:UIApplicationDidEnterBackgroundNotification
                                              object:nil];

    
}
- (void)fetchData {
    self.basePath = [NSString stringWithFormat:@"http://devefence.engageclick.com/videos/video-json-mobile/dpeoverlay.json"];
    
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.basePath]] ;
    
    
    [request setHTTPMethod:@"GET"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        //        responseString = [self trimResponse:responseString];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        //ECLog(@"responseString = %@ and response statusCode = %d",responseString, [httpResponse statusCode]);
        data=[responseString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (responseDictionary)
            self.responseDict = [NSMutableDictionary dictionaryWithDictionary:responseDictionary];
        
        if ([httpResponse statusCode] == 200) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self downloadLogoImage];
            });
            
        } else {
        }
    }];
}

- (NSData *)loadFile:(NSString *)name {
    return [[ECAdManager sharedManager] loadFile:name];
}

- (void)setupVideoPlayer {
    NSDictionary *data =  [self.responseDict objectForKey:@"data"];
    self.moviePlayer = [[EcAdCustomPlayer alloc] initWithContentURL:[NSURL URLWithString:[data objectForKey:@"media"]]];
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
    if (self.DPEFormat == kECDPEFormatNFL)
        [self performSelector:@selector(createRollingdBtn) withObject:nil afterDelay:2.0];
    else if (self.DPEFormat == kECDPEFormatHulu) {
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkPlayback) userInfo:nil repeats:YES];
    }
    else if (self.DPEFormat == kECDPEFormatCallback)
        [self performSelector:@selector(createRollingAdForCallback) withObject:nil afterDelay:2.0];
    
    //        [self performSelector:@selector(createRollingdBtnForHulu) withObject:nil afterDelay:2.0];
    else
        [self performSelector:@selector(createRollingdBtnForTarget) withObject:nil afterDelay:2.0];
    
    
}

- (void)playbackFinished:(MPMoviePlayerController *)player {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if ([self.delegate respondsToSelector:@selector(adVideoDidFinishPlayback)])
        [self.delegate performSelector:@selector(adVideoDidFinishPlayback)];
}


- (void)createRollingAdForCallback {
    img=[[UIImageView alloc]init];
    img.frame = CGRectMake(self.moviePlayer.view.frame.origin.x+5, self.moviePlayer.view.frame.origin.y + self.moviePlayer.view.frame.size.height-105, self.moviePlayer.view.frame.size.width-10, 85);
    [img setBackgroundColor:[UIColor colorWithRed:186.0/255.0 green:186.0/255.0 blue:186.0/255.0 alpha:0.5]];
    //[img setContentMode:UIViewContentModeBottom];
    [img setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth];
    [self.moviePlayer.view addSubview:img];
    [self.moviePlayer.view bringSubviewToFront:img];
    [img setUserInteractionEnabled:YES];
    [img setClipsToBounds:YES];
    
    UIImageView *logoImageView = nil;//
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(2, 2, 256, 256)];
    else {
        img.frame = CGRectMake(self.moviePlayer.view.frame.origin.x+5, self.moviePlayer.view.frame.origin.y + self.moviePlayer.view.frame.size.height-105, self.moviePlayer.view.frame.size.width-10, 70);
        logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(2, 2, 66, 54)];
    }
    
    [img addSubview:logoImageView];
    [logoImageView setImage:[UIImage imageWithData:[self.delegate loadFile:@"geico_start.png"]]];
    [logoImageView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
    [logoImageView setContentMode:UIViewContentModeScaleAspectFit];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"nlf_close.png"]] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeAd) forControlEvents:UIControlEventTouchUpInside];
    [img addSubview:closeBtn];
    [closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
    
    CGRect rect = img.bounds;
    rect.origin.x = rect.size.width - 30;
    rect.origin.y = 5;
    rect.size = CGSizeMake(30, 30);
    closeBtn.frame = rect;
    
    
    rect = img.frame;
    rect.origin.y = rect.origin.y + rect.size.height;
    img.frame = rect;
    rect.origin.y -= rect.size.height;
    
    UILabel *label = [[UILabel alloc] init];
    [label setText:@"Save Upto 15% or More"];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [img addSubview:label];
    
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button1 setBackgroundImage:[UIImage imageWithData:[self.delegate loadFile:@"buttonImage.png"]] forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(callUs) forControlEvents:UIControlEventTouchUpInside];
    [img addSubview:button1];
    [button1 setTitle:@"Call Us" forState:UIControlStateNormal];
    
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button2 setBackgroundImage:[UIImage imageWithData:[self.delegate loadFile:@"buttonImage.png"]] forState:UIControlStateNormal];
    [button2 addTarget:self action:@selector(callBack) forControlEvents:UIControlEventTouchUpInside];
    [img addSubview:button2];
    [button2 setTitle:@"Callback" forState:UIControlStateNormal];
    
    
    
    CGRect actualBtn1Frame = CGRectMake(50, 50, 128, 30);
    CGRect actualBtn2Frame = CGRectMake(actualBtn1Frame.origin.x + actualBtn1Frame.size.width+50, 50, 128, 30);
    CGRect actualBtn3Frame = CGRectMake(actualBtn1Frame.origin.x + actualBtn1Frame.size.width+50, 50, 128, 30);
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        actualBtn1Frame = CGRectMake(img.frame.size.width/2 - 75, logoImageView.frame.origin.y,180,30);
        actualBtn2Frame = CGRectMake(actualBtn1Frame.origin.x, actualBtn1Frame.origin.y+actualBtn1Frame.size.height+5, 75, 25);
        actualBtn3Frame = CGRectMake(actualBtn2Frame.origin.x+actualBtn2Frame.size.width+2, actualBtn2Frame.origin.y, 100, 25);
        
        UIFont *font =  [UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:16.0];
        label.font = font;
        font =  [UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:13.0];
        [button1.titleLabel setFont:font];
        [button2.titleLabel setFont:font];
        
    }
    
    CGRect animateFrame = actualBtn1Frame;
    //    animatreFrame.origin.y = img.frame.size.height;
    animateFrame.size = CGSizeZero;
    button1.frame = animateFrame;
    
    animateFrame = actualBtn2Frame;
    animateFrame.size = CGSizeZero;
    button2.frame = animateFrame;
    
    [UIView animateWithDuration:0.5 animations:^{
        img.frame = rect;
        homeRect = rect;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            button1.frame = actualBtn2Frame;
            label.frame = actualBtn1Frame;
            [UIView animateWithDuration:0.3 animations:^{
                button2.frame = actualBtn3Frame;
                
            }];
        }];
        
    }];
}


- (void)callUs {
    [self.moviePlayer pause];
    [[ECAdManager sharedManager] videoAdLandingPageOpened:@"tel://1-800-861-8380"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel://1-800-861-8380"]];
}

- (void)callBack {
    [self.moviePlayer pause];
    UIAlertView *inputAlertView = [[UIAlertView alloc] initWithTitle:@"Callback" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    [inputAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    UITextField *documentNameTextField = [inputAlertView textFieldAtIndex:0];
    documentNameTextField.keyboardAppearance = UIKeyboardAppearanceDefault;
    [documentNameTextField setKeyboardType:UIKeyboardTypeNumberPad];
    [documentNameTextField setPlaceholder:@"Phone Number"];
    [inputAlertView show];
}
#pragma mark -
#pragma mark - Alert view delegates

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
	UITextField *doucmentNameTextField = [alertView textFieldAtIndex:0];
    NSString *str = [doucmentNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if([str length]) {
		return YES;
	}
	return NO;
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.moviePlayer play];
}

- (void)downloadLogoImage {
    //    brandlogo
    if ([NSNull null] == [self.responseDict objectForKey:@"brandlogo"]) {
        [self setupVideoPlayer];
        return;
    }
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
                [self setupVideoPlayer];
                
                
            });
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
            [self setupVideoPlayer];
            });
        }
    }];
    
}

- (void)createRollingdBtnForTarget {
    if (self.DPEFormat == kECDPEFormatOverlay) {
        img=[[UIImageView alloc]init];
        img.frame = CGRectMake(self.moviePlayer.view.frame.origin.x+5, self.moviePlayer.view.frame.origin.y + self.moviePlayer.view.frame.size.height-105, self.moviePlayer.view.frame.size.width-10, 85);
        [img setBackgroundColor:[UIColor colorWithRed:186.0/255.0 green:186.0/255.0 blue:186.0/255.0 alpha:0.5]];
        //[img setContentMode:UIViewContentModeBottom];
        [img setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth];
        [self.moviePlayer.view addSubview:img];
        [self.moviePlayer.view bringSubviewToFront:img];
        [img setUserInteractionEnabled:YES];
        [img setClipsToBounds:YES];
        
        UIImageView *logoImageView = nil;//
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(2, 2, 256, 256)];
        else {
            img.frame = CGRectMake(self.moviePlayer.view.frame.origin.x+5, self.moviePlayer.view.frame.origin.y + self.moviePlayer.view.frame.size.height-105, self.moviePlayer.view.frame.size.width-10, 60);
            logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(2, 2, 100, 100)];
        }
        
        [img addSubview:logoImageView];
        [logoImageView setImage:self.logoImage];
        [logoImageView setContentMode:UIViewContentModeScaleAspectFit];
        // [logoImageView setImage:[UIImage imageWithData:[self.delegate loadFile:@"targetLogo.png"]]];
        [logoImageView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        
        
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"nlf_close.png"]] forState:UIControlStateNormal];
        [closeBtn addTarget:self action:@selector(closeAd) forControlEvents:UIControlEventTouchUpInside];
        [img addSubview:closeBtn];
        [closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        
        CGRect rect = img.bounds;
        rect.origin.x = rect.size.width - 30;
        rect.origin.y = 5;
        rect.size = CGSizeMake(30, 30);
        closeBtn.frame = rect;
        
        
        rect = img.frame;
        rect.origin.y = rect.origin.y + rect.size.height;
        img.frame = rect;
        rect.origin.y -= rect.size.height;
        
        NSDictionary *dict = [self.responseDict objectForKey:@"data"];
        NSArray *array = [dict objectForKey:@"cta"];
        ECAdCustomButton *button1;
        ECAdCustomButton *button2;
        ECAdCustomButton *button3;
        ECAdCustomButton *button4;
        if ([array lastObject]) {
            if ([array count] >= 1) {
                NSDictionary *dict = [array objectAtIndex:0];
                button1 = [ECAdCustomButton buttonWithType:UIButtonTypeCustom];
                [button1 setBackgroundImage:[UIImage imageWithData:[self.delegate loadFile:@"buttonImage.png"]] forState:UIControlStateNormal];
                [button1 addTarget:self action:@selector(customBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
                [img addSubview:button1];
                [button1 setTitle:[dict objectForKey:@"ctaName"] forState:UIControlStateNormal];
                [button1 setTargetURL:[dict objectForKey:@"ctaTarget"]];
                
                //    [button1 setTitle:@"Find a Store" forState:UIControlStateNormal];
            }
            if ([array count] >= 2) {
                NSDictionary *dict = [array objectAtIndex:1];

                button2 = [ECAdCustomButton buttonWithType:UIButtonTypeCustom];
                [button2 setBackgroundImage:[UIImage imageWithData:[self.delegate loadFile:@"buttonImage.png"]] forState:UIControlStateNormal];
                [button2 addTarget:self action:@selector(customBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
                [img addSubview:button2];
                //    [button2 setTitle:@"Weekly Ad" forState:UIControlStateNormal];
                [button2 setTitle:[dict objectForKey:@"ctaName"] forState:UIControlStateNormal];
                [button2 setTargetURL:[dict objectForKey:@"ctaTarget"]];

            }
            if ([array count] >=3) {
                NSDictionary *dict = [array objectAtIndex:2];

                button3 = [ECAdCustomButton buttonWithType:UIButtonTypeCustom];
                [button3 setBackgroundImage:[UIImage imageWithData:[self.delegate loadFile:@"buttonImage.png"]] forState:UIControlStateNormal];
                [button3 addTarget:self action:@selector(customBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
                [img addSubview:button3];
                //    [button3 setTitle:@"Gift Cards" forState:UIControlStateNormal];
                [button3 setTitle:[dict objectForKey:@"ctaName"] forState:UIControlStateNormal];
                [button3 setTargetURL:[dict objectForKey:@"ctaTarget"]];
                
            }
            if ([array count] >= 4){
                NSDictionary *dict = [array objectAtIndex:3];

                button4 = [ECAdCustomButton buttonWithType:UIButtonTypeCustom];
                [button4 setBackgroundImage:[UIImage imageWithData:[self.delegate loadFile:@"buttonImage.png"]] forState:UIControlStateNormal];
                [button4 addTarget:self action:@selector(customBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
                [img addSubview:button4];
                // [button4 setTitle:@"Registries" forState:UIControlStateNormal];
                [button4 setTitle:[dict objectForKey:@"ctaName"] forState:UIControlStateNormal];
                [button4 setTargetURL:[dict objectForKey:@"ctaTarget"]];
                
            }
        }
        
        
        
        CGRect actualBtn1Frame = CGRectMake(50, 50, 128, 30);
        CGRect actualBtn2Frame = CGRectMake(actualBtn1Frame.origin.x + actualBtn1Frame.size.width+50, 50, 128, 30);
        CGRect actualBtn3Frame = CGRectMake(actualBtn2Frame.origin.x + actualBtn2Frame.size.width+50, 50, 128, 30);
        CGRect actualBtn4Frame = CGRectMake(actualBtn3Frame.origin.x + actualBtn3Frame.size.width+50, 50, 128, 30);
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            actualBtn1Frame = CGRectMake(logoImageView.frame.origin.x+logoImageView.frame.size.width, logoImageView.frame.origin.y,70,20);
            actualBtn2Frame = CGRectMake(actualBtn1Frame.origin.x + actualBtn1Frame.size.width+5, actualBtn1Frame.origin.y, 70, 20);
            actualBtn3Frame = CGRectMake(actualBtn1Frame.origin.x, actualBtn1Frame.origin.y+actualBtn1Frame.size.height+2, 70, 20);
            actualBtn4Frame = CGRectMake(actualBtn3Frame.origin.x + actualBtn3Frame.size.width+5, actualBtn3Frame.origin.y, 70, 20);
            
            UIFont *font =  [UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:10.0];
            
            [button1.titleLabel setFont:font];
            [button2.titleLabel setFont:font];
            [button3.titleLabel setFont:font];
            [button4.titleLabel setFont:font];
            
        }
        
        CGRect animateFrame = actualBtn1Frame;
        //    animatreFrame.origin.y = img.frame.size.height;
        animateFrame.size = CGSizeZero;
        button1.frame = animateFrame;
        
        animateFrame = actualBtn2Frame;
        animateFrame.size = CGSizeZero;
        button2.frame = animateFrame;
        
        animateFrame = actualBtn3Frame;
        animateFrame.size = CGSizeZero;
        button3.frame = animateFrame;
        
        animateFrame = actualBtn4Frame;
        animateFrame.size = CGSizeZero;
        button4.frame = animateFrame;
        
        [UIView animateWithDuration:0.5 animations:^{
            img.frame = rect;
            homeRect = rect;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 animations:^{
                button1.frame = actualBtn1Frame;
                [UIView animateWithDuration:0.3 animations:^{
                    button2.frame = actualBtn2Frame;
                    [UIView animateWithDuration:0.3 animations:^{
                        button3.frame = actualBtn3Frame;
                        [UIView animateWithDuration:0.3 animations:^{
                            button4.frame = actualBtn4Frame;
                            
                        }];
                    }];
                }];
            }];
            
        }];
    }
    else {
        img=[[UIImageView alloc]init];
        img.frame = CGRectMake(self.moviePlayer.view.frame.origin.x+5, self.moviePlayer.view.frame.origin.y + self.moviePlayer.view.frame.size.height-55, self.moviePlayer.view.frame.size.width-10, 50);
        [img setBackgroundColor:[UIColor colorWithRed:186.0/255.0 green:186.0/255.0 blue:186.0/255.0 alpha:0.5]];
        //[img setContentMode:UIViewContentModeBottom];
        [img setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth];
        [self.moviePlayer.view addSubview:img];
        [self.moviePlayer.view bringSubviewToFront:img];
        [img setUserInteractionEnabled:YES];
        [img setClipsToBounds:YES];
        
        
        UIImageView *logoImageView = nil;//
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(2, 2, 256, 256)];
        else {
            img.frame = CGRectMake(self.moviePlayer.view.frame.origin.x+5, self.moviePlayer.view.frame.origin.y + self.moviePlayer.view.frame.size.height-105, self.moviePlayer.view.frame.size.width-10, 60);
            logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(2, 2, 100, 100)];
        }
        
        [img addSubview:logoImageView];
        [logoImageView setImage:[UIImage imageWithData:[self.delegate loadFile:@"targetLogo.png"]]];
        [logoImageView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        
        
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"nlf_close.png"]] forState:UIControlStateNormal];
        [closeBtn addTarget:self action:@selector(closeAd) forControlEvents:UIControlEventTouchUpInside];
        [img addSubview:closeBtn];
        [closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        
        CGRect rect = img.bounds;
        rect.origin.x = rect.size.width - 30;
        rect.origin.y = 5;
        rect.size = CGSizeMake(30, 30);
        closeBtn.frame = rect;
        
        
        rect = img.frame;
        rect.origin.y = rect.origin.y + rect.size.height;
        img.frame = rect;
        rect.origin.y -= rect.size.height;
        
        UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
        [button1 setImage:[UIImage imageWithData:[self.delegate loadFile:@"coupon.jpg"]] forState:UIControlStateNormal];
        [button1 addTarget:self action:@selector(showCoupons) forControlEvents:UIControlEventTouchUpInside];
        [img addSubview:button1];
        [closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        
        CGRect actualBtn1Frame = CGRectMake(img.frame.size.width - 190, 0, 128, 50);
        CGRect animateFrame = actualBtn1Frame;
        //    animatreFrame.origin.y = img.frame.size.height;
        animateFrame.size = CGSizeZero;
        button1.frame = animateFrame;
        
        [UIView animateWithDuration:0.5 animations:^{
            img.frame = rect;
            homeRect = rect;
            
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 animations:^{
                button1.frame = actualBtn1Frame;
            }];
        }];
    }
}

- (void)customBtnClicked:(ECAdCustomButton *)button {
    NSRange r = [button.targetURL rangeOfString:@"callback://"];
    if (r.location != NSNotFound)
        [self callBack];
    else {
        NSString *scheme = @"ecad://";
        r = [button.targetURL rangeOfString:scheme];
        if (r.location != NSNotFound) {
            NSString *schemelessUrlString = [button.targetURL substringFromIndex:scheme.length];
            r = [schemelessUrlString rangeOfString:@"?"];
            if (r.location != NSNotFound) {
            NSString *commandType = [[schemelessUrlString substringToIndex:r.location] lowercaseString];
            NSString *parameterString = [schemelessUrlString substringFromIndex:(r.location + 1)];
            NSDictionary *parameters = MPDictionaryFromQueryString(parameterString);
            if ([commandType isEqualToString:@"calendar"]) {
                [self addToCalander:parameters];
            }
            }
        }
        else {
            [[ECAdManager sharedManager] videoAdLandingPageOpened:button.targetURL];

            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:button.targetURL]];
        }
    }
}

- (void)addToCalander:(NSDictionary *)parameters {
    if (![parameters count])
        return;
    NSDateFormatter *dateFormatter1 = [[NSDateFormatter alloc] init];
    if ([parameters objectForKey:@"date_format"])
        [dateFormatter1 setDateFormat:[parameters objectForKey:@"date_format"]];
    else
        [dateFormatter1 setDateFormat:@"dd-MM-yyyy hh:mm:ss"];
    
    NSString *dateStr = [parameters objectForKey:@"start"];
    if (![dateStr length])
        return;
    NSDate *date = [dateFormatter1 dateFromString:dateStr];
    
    dateStr = [parameters objectForKey:@"end"];
    NSDate *endDate = [dateFormatter1 dateFromString:dateStr];
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    
    
    if([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        // iOS 6 and later
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            if (granted){
                //---- codes here when user allow your app to access theirs' calendar.
                EKEvent *event  = [EKEvent eventWithEventStore:eventStore];
                
                
                
                event.title     = [parameters objectForKey:@"description"];
                event.location  = [parameters objectForKey:@"location"];
                event.startDate = date;//[NSDate date];
                event.endDate   =  endDate;//[[NSDate alloc] initWithTimeInterval:3600 sinceDate:event.startDate];
                event.notes     = [parameters objectForKey:@"summary"];
                event.URL   = [NSURL URLWithString:[parameters objectForKey:@"facebook_event"]];
                
                [event setCalendar:[eventStore defaultCalendarForNewEvents]];
                BOOL success = [eventStore saveEvent:event span:EKSpanThisEvent error:nil];
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if(success) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Event Added" message:@"Event has been Successfully Added to the Calendar" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                        [alert show];
                    }
                });
            }else
            {
                //----- codes here when user NOT allow your app to access the calendar.
            }
        }];
    }
    else {
        //---- codes here for IOS < 6.0.
        EKEvent *event  = [EKEvent eventWithEventStore:eventStore];
        
        
        
        event.title     = [parameters objectForKey:@"description"];
        event.location  = [parameters objectForKey:@"location"];
        event.startDate = date;
        event.endDate   =  endDate;
        event.notes     = [parameters objectForKey:@"description"];
        event.URL   = [NSURL URLWithString:[parameters objectForKey:@"facebook_event"]];
        
        [event setCalendar:[eventStore defaultCalendarForNewEvents]];
        if([eventStore saveEvent:event span:EKSpanThisEvent error:nil]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Event Added" message:@"Event has been Successfully Added to the Calendar" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        }
    }
    
}

- (void)showCoupons {
    [self.moviePlayer pause];
    if (nil==self.overlayView) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            self.overlayView = [[UIView alloc] initWithFrame:CGRectInset(self.moviePlayer.view.frame, 50, 50)];
        else
            self.overlayView = [[UIView alloc] initWithFrame:CGRectInset(self.moviePlayer.view.frame, 10, 30)];
        
        [self.overlayView setBackgroundColor:[UIColor whiteColor]];
        [self.overlayView.layer setBorderWidth:4];
        [self.overlayView.layer setCornerRadius:12.0];
        [self.overlayView.layer setBorderColor:[UIColor redColor].CGColor];
    }
    //    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view cache:YES];
    [self setupInnerOverlayContent];
    self.overlayView.alpha = 0.0;
    [self.overlayView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
	[[self.moviePlayer view] addSubview:self.overlayView];
    [UIView animateWithDuration:0.5 animations:^{
        self.overlayView.alpha = 1.0;
    }];
    //    [UIView transitionFromView:img toView:self.overlayView duration:1.0 options:UIViewAnimationOptionTransitionFlipFromLeft completion:^(BOOL finished) {
    //        [self.moviePlayer.view addSubview:self.overlayView];
    //    }];
}

- (void)setupInnerOverlayContent {
    
    UIView *topView = nil;//
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        topView = [[UIView alloc] initWithFrame:CGRectMake(0, 5, self.overlayView.frame.size.width , 100)];
    else
        topView = [[UIView alloc] initWithFrame:CGRectMake(2, 5, self.overlayView.frame.size.width-4 , 50)];
    
    [self.overlayView addSubview:topView];
    [topView setBackgroundColor:[UIColor lightGrayColor]];
    [topView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth];
    
    UIImageView *logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 10, 256, 256)];
    [topView addSubview:logoImageView];
    [logoImageView setBackgroundColor:[UIColor clearColor]];
    [logoImageView setImage:[UIImage imageWithData:[self.delegate loadFile:@"targetLogo.png"]]];
    [logoImageView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"nlf_close.png"]] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeOverlay) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:closeBtn];
    [closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
    
    CGRect rect = topView.bounds;
    rect.origin.x = rect.size.width - 30;
    rect.origin.y = 5;
    rect.size = CGSizeMake(30, 30);
    closeBtn.frame = rect;
    
    
    UIButton *button4 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button4 setBackgroundImage:[UIImage imageWithData:[self.delegate loadFile:@"buttonImage.png"]] forState:UIControlStateNormal];
    [button4 addTarget:self action:@selector(sendCoupon) forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:button4];
    [button4 setTitle:@"Email Coupon" forState:UIControlStateNormal];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        button4.frame = CGRectMake((self.overlayView.frame.size.width - 129)/2,self.overlayView.frame.size.height - 150, 150, 30);
    else
        button4.frame = CGRectMake((self.overlayView.frame.size.width - 129)/2,self.overlayView.frame.size.height - 40, 150, 30);
    
    [button4 setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    
    
    
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"LeftArrow.png"]] forState:UIControlStateNormal];
    [leftBtn addTarget:self action:@selector(leftBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:leftBtn];
    leftBtn.tag = kLEFT_ARROW_TAG;
    
    CGRect frame = self.overlayView.bounds;
    frame.size = CGSizeMake(30, 30);
    frame.origin.y = (self.overlayView.frame.size.height/2) - (frame.size.height/2);
    leftBtn.frame = frame;
    leftBtn.enabled = NO;
    
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"RightArrow.png"]] forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(rightBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    frame.origin.x = self.overlayView.frame.size.width - (frame.size.width);
    rightBtn.frame  =frame;
    rightBtn.tag = kRIGHT_ARROW_TAG;
    
    [self.overlayView addSubview:rightBtn];
    
    rightBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
    leftBtn.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
    
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0,topView.frame.size.height, topView.frame.size.width, self.overlayView.frame.size.height - topView.frame.size.height)];
    scrollView.tag = kSCROLL_TAG;
    [self.overlayView addSubview:scrollView];
    scrollView.delegate = self;
    [scrollView setShowsHorizontalScrollIndicator:NO];
    [scrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [scrollView setPagingEnabled:YES];
    float x =0;
    for (int i=1 ; i<5; i++) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(x, 0, scrollView.frame.size.width, scrollView.frame.size.height)];
        [scrollView addSubview:view];
        x += scrollView.frame.size.width;
        [self setupCouponView:view index:i];
    }
    [scrollView setContentSize:CGSizeMake(scrollView.frame.size.width*4, scrollView.frame.size.height)];
    [self.overlayView bringSubviewToFront:leftBtn];
    [self.overlayView bringSubviewToFront:rightBtn];
    [self.overlayView bringSubviewToFront:button4];
}

- (void)sendCoupon {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        [mailViewController setSubject:@"Target Free Coupons"];
        [mailViewController setMessageBody:@"Please vist the link below via Web browser to take a print of the coupon \n\n http://coupons.target.com/" isHTML:YES];
        [self presentModalViewController:mailViewController animated:YES];
    }
    
    else {
        ECLog(@"Device is unable to send email in its current state.");
    }
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult: (MFMailComposeResult)result error:(NSError*)error {
    [self dismissModalViewControllerAnimated:YES];
}


- (void)setupCouponView:(UIView *)view index:(int)idx {
    UIImageView *imageView =nil;//
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        imageView =  [[UIImageView alloc] initWithFrame:CGRectMake(10, 0, 200, view.frame.size.height)];
    else
        imageView =  [[UIImageView alloc] initWithFrame:CGRectMake(0, 10, view.frame.size.width, 70)];
    
    [imageView setImage:[UIImage imageWithData:[self.delegate loadFile:[NSString stringWithFormat:@"%d.jpg",idx]]]];
    [view addSubview:imageView];
    [imageView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    [imageView setBackgroundColor:[UIColor clearColor]];
    
    UILabel *label = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        label = [[UILabel alloc] initWithFrame:CGRectMake(imageView.frame.size.width + 50, 100, 200, 100)];
    else
        label = [[UILabel alloc] initWithFrame:CGRectMake( 5, imageView.frame.origin.y + imageView.frame.size.height, view.frame.size.width, 50)];
    label.textAlignment = NSTextAlignmentCenter;
    [label setTextColor:[UIColor redColor]];
    [view addSubview:label];
    UIFont *font = [UIFont fontWithName:@"Georgia-Bold" size:20.0];
    [label setFont:font];
    
    UILabel *label1 = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        label1 = [[UILabel alloc] initWithFrame:CGRectMake(imageView.frame.size.width + 50, 200, 200, 200)];
    }
    else {
        label1 = [[UILabel alloc] initWithFrame:CGRectMake(20, label.frame.origin.y+label.frame.size.height+5, view.frame.size.width-25, 80)];
        [label1 setAdjustsFontSizeToFitWidth:YES];
    }
    [label1 setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin];
    [label1 setNumberOfLines:0];
    label1.textAlignment = NSTextAlignmentCenter;
    
    [label1 setTextColor:[UIColor blackColor]];
    [label1 setBackgroundColor:[UIColor clearColor]];
    [view addSubview:label1];
    font = [UIFont fontWithName:@"Georgia-Bold" size:20.0];
    [label1 setFont:font];
    
    
    switch (idx) {
        case 1: {
            label.text = @"1 % Off";
            label1.text= @"When you buy any ONE (1) Tidy Cats® Glade Scent cat litter";
        }
            break;
        case 2: {
            label.text = @"3 % Off";
            label1.text = @"Sensodyne toothpaste";
        }
            break;
        case 3: {
            label.text = @"1 % Off";
            label1.text = @"Litter Genie Cat litter disposal system ";
            
        }
            break;
        case 4: {
            label.text = @"1 % Off";
            label1.text=@"12-oz. or larger Dial body wash";
        }
            break;
            
        default:
            break;
    }
}



- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (self.DPEFormat == kECDPEFormatCoupon && self.overlayView) {
        UIScrollView *scrollView = (UIScrollView *)[self.overlayView viewWithTag:kSCROLL_TAG];
        UIButton *leftBtn = (UIButton *)[self.overlayView viewWithTag:kLEFT_ARROW_TAG];
        UIButton *rightBtn = (UIButton *)[self.overlayView viewWithTag:kRIGHT_ARROW_TAG];
        
        for (UIView *subView in scrollView.subviews) {
            [subView removeFromSuperview];
        }
        
        float x =0;
        for (int i=1 ; i<5; i++) {
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(x, 0, scrollView.frame.size.width, scrollView.frame.size.height)];
            [scrollView addSubview:view];
            x += scrollView.frame.size.width;
            [self setupCouponView:view index:i];
        }
        [scrollView setContentSize:CGSizeMake(scrollView.frame.size.width*4, scrollView.frame.size.height)];
        
        
        CGRect frame = self.overlayView.bounds;
        frame.size = CGSizeMake(30, 30);
        frame.origin.y = (self.overlayView.frame.size.height/2) - (frame.size.height/2);
        leftBtn.frame = frame;
        
        frame.origin.x = self.overlayView.frame.size.width - (frame.size.width);
        rightBtn.frame  =frame;
        
        [self.overlayView bringSubviewToFront:leftBtn];
        [self.overlayView bringSubviewToFront:rightBtn];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)_scrollView {
    CGFloat pageWidth = _scrollView.frame.size.width;
	int currentImageIndex = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    [self toggleDirectionBtn:currentImageIndex];
}

- (void)leftBtnClicked {
    UIButton *leftBtn = (UIButton *)[self.overlayView viewWithTag:kLEFT_ARROW_TAG];
    UIButton *rightBtn = (UIButton *)[self.overlayView viewWithTag:kRIGHT_ARROW_TAG];
    UIScrollView *scrollView = (UIScrollView *)[self.overlayView viewWithTag:kSCROLL_TAG];
    
    CGFloat pageWidth = scrollView.frame.size.width;
	int currentImageIndex = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    if (currentImageIndex <= 0) {
        leftBtn.enabled = NO;
        rightBtn.enabled = YES;
        return;
    }
    currentImageIndex --;
    [self toggleDirectionBtn:currentImageIndex];
    
    [scrollView setContentOffset:CGPointMake(currentImageIndex*scrollView.frame.size.width, 0) animated:YES];
    
}
- (void)rightBtnClicked {
    UIButton *leftBtn = (UIButton *)[self.overlayView viewWithTag:kLEFT_ARROW_TAG];
    UIButton *rightBtn = (UIButton *)[self.overlayView viewWithTag:kRIGHT_ARROW_TAG];
    UIScrollView *scrollView = (UIScrollView *)[self.overlayView viewWithTag:kSCROLL_TAG];
    
    CGFloat pageWidth = scrollView.frame.size.width;
	int currentImageIndex = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    if (currentImageIndex >= 3) {
        leftBtn.enabled = YES;
        rightBtn.enabled = NO;
        return;
    }
    
    currentImageIndex ++;
    [self toggleDirectionBtn:currentImageIndex];
    
    
    [scrollView setContentOffset:CGPointMake(currentImageIndex*scrollView.frame.size.width, 0) animated:YES];
}

- (void)toggleDirectionBtn:(int)currentImageIndex {
    UIButton *leftBtn = (UIButton *)[self.overlayView viewWithTag:kLEFT_ARROW_TAG];
    UIButton *rightBtn = (UIButton *)[self.overlayView viewWithTag:kRIGHT_ARROW_TAG];
    if (currentImageIndex >= 3) {
        rightBtn.enabled = NO;
    }
    else
        rightBtn.enabled = YES;
    
    if (currentImageIndex < 0) {
        leftBtn.enabled = NO;
    }
    else
        leftBtn.enabled = YES;
}

- (void)closeOverlay {
    [UIView animateWithDuration:0.5 animations:^{
        self.overlayView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.overlayView removeFromSuperview];
        self.overlayView = nil;
        [self.moviePlayer play];
    }];
}

- (void)registries {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.target.com/np/registry/-/N-56cy8#?lnk=gnav_registries"]];
    
}

- (void)giftCards {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.target.com/c/giftcards/-/N-5xsxu#?lnk=gnav_giftcards"]];
    
}
- (void)findStore {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.target.com/store-locator/find-stores#?lnk=gnav_findastore"]];
}

- (void)weeklyAd {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://weeklyad.target.com/minneapolis-mn-55403/homepage#"]];
}


- (void)createRollingdBtn {
    img=[[UIImageView alloc]init];
    img.frame = CGRectMake(self.moviePlayer.view.frame.origin.x+5, self.moviePlayer.view.frame.origin.y + self.moviePlayer.view.frame.size.height-105, self.moviePlayer.view.frame.size.width-10, 100);
    [img setImage:[UIImage imageWithData:[self.delegate loadFile:@"nflfooter.png"]]];
    //[img setBackgroundColor:[UIColor yellowColor]];
    //[img setContentMode:UIViewContentModeBottom];
    [img setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth];
    [self.moviePlayer.view addSubview:img];
    [self.moviePlayer.view bringSubviewToFront:img];
    [img setUserInteractionEnabled:YES];
    
    UIButton  *adBtn1 = [UIButton buttonWithType:UIButtonTypeCustom];
    [adBtn1 setImage:[UIImage imageWithData:[self.delegate loadFile:@"helmet2.png"]] forState:UIControlStateNormal];
    [adBtn1 addTarget:self action:@selector(openBengals) forControlEvents:UIControlEventTouchUpInside];
    adBtn1.frame = CGRectMake(img.bounds.size.width/2, 5,100,100);
    [adBtn1 setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleBottomMargin| UIViewAutoresizingFlexibleTopMargin];
    [adBtn1 setBackgroundColor:[UIColor clearColor]];
    [img addSubview:adBtn1];
    
    UIButton  *adBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [adBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"helmet1.png"]] forState:UIControlStateNormal];
    [adBtn addTarget:self action:@selector(openKansas) forControlEvents:UIControlEventTouchUpInside];
    adBtn.frame = CGRectMake(img.bounds.size.width/2, 5,100,100);
    [adBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin |UIViewAutoresizingFlexibleBottomMargin| UIViewAutoresizingFlexibleTopMargin];
    [adBtn setBackgroundColor:[UIColor clearColor]];
    [img addSubview:adBtn];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"nlf_close.png"]] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeAd) forControlEvents:UIControlEventTouchUpInside];
    [img addSubview:closeBtn];
    [closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
    
    //adBtn.layer.anchorPoint = CGPointMake(1.0, 0.0);
    
    // Rotate 90 degrees to hide it off screen
    CGAffineTransform rotationTransform = CGAffineTransformIdentity;
    rotationTransform = CGAffineTransformRotate(rotationTransform, DEGREES_TO_RADIANS(180));
    adBtn.transform = rotationTransform;
    adBtn1.transform = rotationTransform;
    
    
    
    CGRect rect = img.bounds;
    rect.origin.x = rect.size.width - 30;
    rect.origin.y = 5;
    rect.size = CGSizeMake(30, 30);
    closeBtn.frame = rect;
    
    
    rect = img.frame;
    rect.origin.y = rect.origin.y + rect.size.height;
    img.frame = rect;
    rect.origin.y -= rect.size.height;
    
    CGAffineTransform swingTransform = CGAffineTransformIdentity;
    swingTransform = CGAffineTransformRotate(swingTransform, DEGREES_TO_RADIANS(0));
    
    
    
    [UIView animateWithDuration:0.5 animations:^{
        img.frame = rect;
        homeRect = rect;
        
    } completion:^(BOOL finished) {
        [UIView beginAnimations:@"swing" context:(__bridge void *)(adBtn)];
        [UIView setAnimationDuration:1.0];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            adBtn.frame = CGRectMake(img.bounds.size.width - 110, 5,100,100);
            adBtn1.frame = CGRectMake(30, 5,100,100);
        }
        else {
            adBtn.frame = CGRectMake(img.bounds.size.width - 80, 5,100,100);
            adBtn1.frame = CGRectMake(5, 5,100,100);
            
        }
        
        adBtn.transform = swingTransform;
        adBtn1.transform = swingTransform;
        
        [UIView commitAnimations];
    }];
    [UIView animateWithDuration:0.5 animations:^{
    }];
}

- (void)checkPlayback {
    if (nil == img && self.moviePlayer.currentPlaybackTime >= 4.0f) {
        [self createRollingdBtnForHulu];
        [timer invalidate];
        timer = nil;
    }
}
- (void)createRollingdBtnForHulu {
    img=[[UIImageView alloc]init];
    [img setImage:[UIImage imageWithData:[self.delegate loadFile:@"hulu_footer.png"]]];
    img.frame = CGRectMake(self.moviePlayer.view.frame.origin.x+5, self.moviePlayer.view.frame.origin.y + self.moviePlayer.view.frame.size.height-img.image.size.height-5, self.moviePlayer.view.frame.size.width-10, img.image.size.height);
    //[img setBackgroundColor:[UIColor yellowColor]];
    //[img setContentMode:UIViewContentModeBottom];
    [img setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth];
    [self.moviePlayer.view addSubview:img];
    [img setUserInteractionEnabled:YES];
    UIButton *huluBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [img addSubview:huluBtn];
    [huluBtn addTarget:self action:@selector(huluTarget) forControlEvents:UIControlEventTouchUpInside];
    [huluBtn setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
    huluBtn.frame = img.bounds;
    [self.moviePlayer.view bringSubviewToFront:img];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"nlf_close.png"]] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeAd) forControlEvents:UIControlEventTouchUpInside];
    [huluBtn addSubview:closeBtn];
    [closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
    
    
    
    
    
    CGRect rect = img.bounds;
    rect.origin.x = rect.size.width - 30;
    rect.origin.y = 5;
    rect.size = CGSizeMake(30, 30);
    closeBtn.frame = rect;
    
    
    rect = img.frame;
    rect.origin.y = rect.origin.y + rect.size.height;
    img.frame = rect;
    rect.origin.y -= rect.size.height;
    self.upBtn.alpha = 0.0;
    
    [UIView animateWithDuration:0.5 animations:^{
        img.frame = rect;
        homeRect = rect;
        
    } completion:^(BOOL finished) {
    }];
    
}

- (void)huluTarget {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.hulu.com/its-always-sunny-in-philadelphia"]];
}
- (void)closeAd {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"overlayHidden"];

    if (nil == self.upBtn) {
        self.upBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.upBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"up.png"]] forState:UIControlStateNormal];
        [self.moviePlayer.view addSubview:self.upBtn];
        [self.upBtn addTarget:self action:@selector(showAd) forControlEvents:UIControlEventTouchUpInside];
        [self.upBtn setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin];
    }
    self.upBtn.frame = CGRectMake((self.moviePlayer.view.frame.size.width/2)-15,self.moviePlayer.view.frame.size.height-30,30, 30);
    self.upBtn.alpha = 0.0;
    CGRect rect = img.frame;
    rect.origin.y = rect.origin.y + rect.size.height+100;
    
    [UIView animateWithDuration:0.5 animations:^{
        img.frame = rect;
        
    } completion:^(BOOL finished) {
        self.upBtn.alpha = 1.0;
    }];
    
}

- (void)showAd {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"overlayshown"];

    CGRect  rect = img.frame;
    rect.origin.y = self.moviePlayer.view.frame.size.height-img.frame.size.height;//rect.origin.y + rect.size.height;
    self.upBtn.alpha = 0.0;
    
    [UIView animateWithDuration:0.5 animations:^{
        img.frame = homeRect;
    } completion:^(BOOL finished) {
    }];
}
- (void)openBengals {
    [self createImageView];
    [self.imageView setBackgroundImage:[UIImage imageWithData:[self.delegate loadFile:@"Bengals.jpg"]] forState:UIControlStateNormal];
    [self.imageView removeTarget:self action:@selector(openKansasLink) forControlEvents:UIControlEventTouchUpInside];
    [self.imageView addTarget:self action:@selector(openBengalsLink) forControlEvents:UIControlEventTouchUpInside];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.img.alpha = 0.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            self.imageView.alpha = 1.0;
        }];
        
        
    }];
    
}

- (void)openKansas {
    [self createImageView];
    [self.imageView setBackgroundImage:[UIImage imageWithData:[self.delegate loadFile:@"Kansas.jpg"]] forState:UIControlStateNormal];
    [self.imageView removeTarget:self action:@selector(openBengalsLink) forControlEvents:UIControlEventTouchUpInside];
    [self.imageView addTarget:self action:@selector(openKansasLink) forControlEvents:UIControlEventTouchUpInside];
    [UIView animateWithDuration:0.3 animations:^{
        self.img.alpha = 0.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            self.imageView.alpha = 1.0;
        }];
        
    }];
    
    
}


- (void)openBengalsLink {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.nflshop.com/category/index.jsp?categoryId=716574"]];
}

- (void)openKansasLink {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.nflshop.com/category/index.jsp?categoryId=716609"]];
    
}

- (void)closeImage {
    
    [UIView animateWithDuration:0.3 animations:^{
        self.imageView.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            self.img.alpha =1.0;
        }];
    }];
    [self.moviePlayer play];
}

- (void)createImageView {
    if (nil == self.imageView) {
        self.imageView = [[UIButton alloc] initWithFrame:CGRectInset(self.moviePlayer.view.bounds, 20,100)];
        [self.moviePlayer.view addSubview:self.imageView];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"nlf_close.png"]] forState:UIControlStateNormal];
        [closeBtn addTarget:self action:@selector(closeImage) forControlEvents:UIControlEventTouchUpInside];
        [self.imageView addSubview:closeBtn];
        [closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        CGRect rect = self.imageView.bounds;
        rect.origin.x = rect.size.width - 30;
        rect.origin.y = 5;
        rect.size = CGSizeMake(30, 30);
        closeBtn.frame = rect;
    }
    [self.moviePlayer.view bringSubviewToFront:self.imageView];
    [self.moviePlayer pause];
    
}
#pragma mark - Orientation Methods

- (BOOL)shouldAutorotate{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return YES;
    }
    else {
        if (self.DPEFormat == kECDPEFormatHulu)
            return self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight;
        else
            return YES;
    }
}

-(NSUInteger)supportedInterfaceOrientations{
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    else {
        if (self.DPEFormat == kECDPEFormatHulu)
            return UIInterfaceOrientationMaskLandscape;
        else
            return UIInterfaceOrientationMaskAll;
        
    }
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return self.interfaceOrientation;
    }
    else {
        if (self.DPEFormat == kECDPEFormatHulu)
            return UIInterfaceOrientationLandscapeLeft;
        else
            return self.interfaceOrientation;
        
    }
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return YES;
    else {
        if (self.DPEFormat == kECDPEFormatHulu)
            return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
        else
            return YES;
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
    [timer invalidate];
    timer = nil;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self.moviePlayer];
    
    self.moviePlayer = nil;
    [timer invalidate];
    timer = nil;
    
}
@end
