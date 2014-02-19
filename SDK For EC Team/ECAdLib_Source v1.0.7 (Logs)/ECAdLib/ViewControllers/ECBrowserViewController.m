//
//  ECModalinterstitialAdViewController.m
//  ECAdLib
//
//  Created by EngageClick on 5/22/13.
//  Copyright (c) 2013 EngageClick. All rights reserved.
//

#import "ECBrowserViewController.h"
#import "ECAdManager.h"

@interface ECBrowserViewController ()
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end

@implementation ECBrowserViewController

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
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    if (nil == self.webView) {
        CGRect rect = self.view.bounds;
        rect.size.height -= 44;
        
        self.webView = [[UIWebView alloc] initWithFrame:rect];
        [self.view addSubview:self.webView];
        self.webView.delegate = self;
        [self.webView setScalesPageToFit:YES];
        [self.webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self.webView setBackgroundColor:[UIColor clearColor]];
        
    }
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.webView addSubview:self.spinner];
    [self.webView bringSubviewToFront:self.spinner];
    [self.spinner setHidesWhenStopped:YES];
    [self.spinner startAnimating];

    self.webView.frame = self.view.bounds;
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.clickURL]]];
    self.spinner.frame = CGRectMake((self.webView.frame.size.width-20)/2, (self.webView.frame.size.height-20)/2, 20, 20);
    [self.spinner setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin];
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    toolbar.frame = CGRectMake(0, self.view.frame.size.height-44, self.view.frame.size.width, 44);
    NSMutableArray *items = [[NSMutableArray alloc] init];
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(clickBack)]];
     [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil]];
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(clickForward)]];
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil]];
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(clickRefresh)]];
    [toolbar setItems:items animated:YES];
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil]];
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeAd)]];
    [toolbar setItems:items animated:YES];
    
    [toolbar setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    [self.view addSubview:toolbar];
    //[self displayCloseButton];
    [self.webView bringSubviewToFront:self.spinner];
    
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(closeAd)
                                                name:UIApplicationDidEnterBackgroundNotification
                                              object:nil];

	// Do any additional setup after loading the view.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)clickBack {
    if ([self.webView canGoBack])
        [self.webView goBack];
}
- (void)clickForward {
    if ([self.webView canGoForward])
        [self.webView goForward];
    
}
- (void)clickRefresh {
    [self.webView reload];
}

- (void)displayCloseButton {
   NSBundle *resourceBundle =  [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"ECAdLibResources" withExtension:@"bundle"]];
    NSString *path =    [resourceBundle pathForResource:@"black_Close" ofType:@"png"];
//    NSData *data = [NSData dataWithContentsOfFile:path];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageWithContentsOfFile:path] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(closeAd) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    btn.frame = CGRectMake(5, 5, 40, 40);
    [self.view bringSubviewToFront:btn];
    [btn setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin];
}

- (void)closeAd {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self dismissViewControllerAnimated:YES completion:^{
        if ([self.interstitialDelegate respondsToSelector:@selector(interstitialAdDidClose:)])
            [self.interstitialDelegate performSelector:@selector(interstitialAdDidClose:) withObject:self];
    }];
    
}

#pragma mark - Webview delegate


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
//    NSString *scheme = request.URL.scheme;
    NSRange r = [request.URL.absoluteString rangeOfString:@"itunes.apple.com"];

    if (r.location != NSNotFound) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.spinner startAnimating];
    
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.spinner stopAnimating];
    if (/*!webView.isLoading && */[self.interstitialDelegate respondsToSelector:@selector(interstitialAdDidLoad:)]) {
        [self.interstitialDelegate performSelector:@selector(interstitialAdDidLoad:) withObject:self];
    }
    
    
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.spinner stopAnimating];
    if ([self.interstitialDelegate respondsToSelector:@selector(interstitialAd:didFailWithError:)]) {
        [self.interstitialDelegate performSelector:@selector(interstitialAd:didFailWithError:) withObject:self withObject:error];
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}
@end
