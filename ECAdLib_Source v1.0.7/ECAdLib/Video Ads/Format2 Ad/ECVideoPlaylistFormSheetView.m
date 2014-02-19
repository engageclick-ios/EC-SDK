//
//  ECVideoPlaylistFormSheetViewController.m
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/9/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import "ECVideoPlaylistFormSheetView.h"
#import "ECModalVideoPlaylistAdViewController.h"
#import "ECAdMapPoint.h"
#import "ECAdGalleryView.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import "ECAdManager.h"


#define ECAdGalleryImageTag 2000
#define ECADGallerySelectionWidth 4

#define kGOOGLE_API_KEY @"AIzaSyBO25quts5C-FJFt5zdLuZWOmPLU58h5uQ"


@interface ECVideoPlaylistFormSheetView () {
    int currentImageIndex;
    BOOL iskeyboardVisible;
    BOOL isTwitterOpen;
}

@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UIButton *socialBtn;
@property (nonatomic, strong) UIButton *galleryBtn;
@property (nonatomic, strong) UIButton *storeBtn;
@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, strong) UITableView *socialTableView;

@property (nonatomic, strong) UIButton *fbBtn;
@property (nonatomic, strong) UIButton *twitterBtn;

@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIView *titleStripView;
@property (nonatomic, strong) UIButton *picturesBtn;
@property (nonatomic, strong) UIButton *videosBtn;

@property (nonatomic, strong) UIButton *leftBtn;
@property (nonatomic, strong) UIButton *rightBtn;

@property (nonatomic, strong) ECAdGalleryView *galleryImage;

@property (nonatomic, strong) UITableView *playlistTableView;
@property (nonatomic, strong) UIView *verticalSeperatorLine;

@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) UIImageView *movieThumb;
@property (nonatomic, strong) UIButton *playbtn;

@property (nonatomic, strong) UIView *buttonSeperator;
@property (nonatomic, strong) UIView *locatorView;
@property (nonatomic, strong) UITextField *txtField;
@property (nonatomic, strong) MKMapView *mapView;
@end

@implementation ECVideoPlaylistFormSheetView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor whiteColor];
        currentImageIndex = -1;
        [self setClipsToBounds:YES];
        // [self setupTopView];
    }
    return self;
}

- (void)setupTopView {
    CGRect rect = CGRectInset(self.bounds, 10, 10);
    rect.size.height = 100;
    self.topView = [[UIView alloc] initWithFrame:rect];
    self.topView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.topView];
    
    self.topView.backgroundColor = [UIColor whiteColor];
    
    rect = self.topView.bounds;
    rect.origin.x = 0;
    rect.size.width = 100;
    
    UIImage *image =  nil;//[UIImage imageNamed:@"WallmartLogo.png"];
    self.logoImageView = [[UIImageView alloc] initWithFrame:rect];
    if ([self.parentView logoImage])
        self.logoImageView.image =[(ECModalVideoPlaylistAdViewController *)self.parentView logoImage];
    else
        self.logoImageView.image =image;//[(ECModalVideoPlaylistAdViewController *)self.parentView logoImage];
    rect.size = self.logoImageView.image.size;
    rect.size.height = 50;
    
    rect.size.width = self.logoImageView.image.size.width;
    self.logoImageView.frame = rect;
    self.logoImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.logoImageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.topView addSubview:self.logoImageView];
    
    self.socialBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.socialBtn setTitle:@"SOCIAL" forState:UIControlStateNormal];
    [self.socialBtn.titleLabel setFont:[UIFont systemFontOfSize:20]];
    [self.socialBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.socialBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    
    [self.socialBtn addTarget:self action:@selector(socialBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:self.socialBtn];
    
    self.galleryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.galleryBtn setTitle:@"GALLERY" forState:UIControlStateNormal];
    [self.galleryBtn.titleLabel setFont:[UIFont systemFontOfSize:20]];
    [self.galleryBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.galleryBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    
    [self.galleryBtn addTarget:self action:@selector(galleryBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:self.galleryBtn];
    //[self.galleryBtn setBackgroundColor:[UIColor yellowColor]];
    
    self.storeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    
    rect = self.topView.bounds;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        rect.origin.x = rect.size.width - (6*100);
        rect.origin.y = rect.size.height - 20;
        rect.size = CGSizeMake(100, 20);
        self.socialBtn.frame = rect;
        
        rect = self.socialBtn.frame;
        rect.origin.x += rect.size.width+8;
        rect.size.width += 80;
        self.galleryBtn.frame = rect;
        [self.storeBtn.titleLabel setFont:[UIFont systemFontOfSize:20]];
        
    }
    else {
        rect.origin.x =5;
        rect.origin.y = rect.size.height - 20;
        rect.size = CGSizeMake(50, 20);
        self.socialBtn.frame = rect;
        
        rect = self.socialBtn.frame;
        rect.origin.x += rect.size.width+5;
        rect.size.width += 30;
        self.galleryBtn.frame = rect;
        [self.galleryBtn.titleLabel setFont:[UIFont systemFontOfSize:12]];
        
        [self.socialBtn.titleLabel setFont:[UIFont systemFontOfSize:12]];
        [self.storeBtn.titleLabel setFont:[UIFont systemFontOfSize:12]];
        
    }
    
    
    [self.storeBtn setTitle:@"STORE LOCATOR" forState:UIControlStateNormal];
    [self.storeBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.storeBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    
    [self.storeBtn addTarget:self action:@selector(storeBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:self.storeBtn];
    //[self.storeBtn setBackgroundColor:[UIColor yellowColor]];
    rect = self.galleryBtn.frame;
    rect.origin.x += rect.size.width+8;
    rect.size.width += 80;
    self.storeBtn.frame = rect;
    
    
    self.closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeBtn setBackgroundImage:[UIImage imageWithData:[[self.parentView delegate] loadFile:@"gray_close.png"]] forState:UIControlStateNormal];
    rect = self.topView.bounds;
    rect.origin.x = rect.size.width - 30;
    rect.size = CGSizeMake(30, 30);
    self.closeBtn.frame = rect;
    [self.closeBtn addTarget:self action:@selector(closeBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    //[self.closeBtn setBackgroundColor:[UIColor redColor]];
    [self.topView addSubview:self.closeBtn];
    
    UIView *seperatorView = [[UIView alloc] init];
    [seperatorView setBackgroundColor:[UIColor colorWithRed:73.0/255.0 green:164.0/225.0 blue:214.0/255.0 alpha:1.0]];
    [self.topView addSubview:seperatorView];
    
    rect = self.storeBtn.frame;
    rect.origin.x -= 4;
    rect.size.width = 2;
    seperatorView.frame = rect;
    
    
    // seperatorView.autoresizingMask = self.storeBtn.autoresizingMask = self.galleryBtn.autoresizingMask = self.closeBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    
    UIView *seperatorView1 = [[UIView alloc] init];
    [seperatorView1 setBackgroundColor:[UIColor colorWithRed:73.0/255.0 green:164.0/225.0 blue:214.0/255.0 alpha:1.0]];
    [self.topView addSubview:seperatorView1];
    
    rect = self.galleryBtn.frame;
    rect.origin.x -= 4;
    rect.size.width = 2;
    seperatorView1.frame = rect;
    
    
    self.socialBtn.autoresizingMask=seperatorView.autoresizingMask = seperatorView1.autoresizingMask = self.storeBtn.autoresizingMask = self.galleryBtn.autoresizingMask = self.closeBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self galleryBtnClicked];
    [self.topView bringSubviewToFront:self.logoImageView];
}


- (void)closeBtnClicked {
    [(ECModalVideoPlaylistAdViewController *)self.parentView formSheetViewDidClose];
}
- (void)storeBtnClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"locatorClicked"];

    [self.socialBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.storeBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [self.galleryBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self setupStoreLocatorView];
}

- (void)setupStoreLocatorView {
    self.titleStripView.hidden =YES;
    self.socialTableView.hidden =YES;
    self.moviePlayer.view.hidden =YES;
    self.playlistTableView.hidden =YES;
    self.verticalSeperatorLine.hidden =YES;
    self.galleryImage.hidden =YES;
    self.buttonSeperator.hidden = YES;
    self.locatorView.hidden = NO;
    if (nil == self.locatorView) {
        self.locatorView = [[UIView alloc] init];
        [self.bottomView addSubview:self.locatorView];
        self.locatorView.backgroundColor = [UIColor lightGrayColor];
        [self.locatorView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        self.locatorView.layer.borderWidth = 2.0;
        self.locatorView.layer.borderColor = [UIColor whiteColor].CGColor;
        
        UILabel *locatorTitle = [[UILabel alloc] init];
        [self.locatorView addSubview:locatorTitle];
        [locatorTitle setText:@"Please enter your Zip code below to find a Wallmart store near you"];
        [locatorTitle setAdjustsFontSizeToFitWidth:YES];
        [locatorTitle setTextColor:[UIColor whiteColor]];
        [locatorTitle setTextAlignment:NSTextAlignmentCenter];
        [locatorTitle setBackgroundColor:[UIColor clearColor]];
        [locatorTitle setNumberOfLines:0];
        locatorTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            locatorTitle.font = [UIFont fontWithName:@"Georgia-Bold" size:22.0];;
            self.locatorView.frame   = CGRectInset(self.bottomView.bounds, 100, 100);
        }
        else {
            self.locatorView.frame   = CGRectInset(self.bottomView.bounds, 10, 10);
            locatorTitle.font = [UIFont fontWithName:@"Georgia-Bold" size:12.0];;
            
        }
        
        CGRect frame = self.locatorView.bounds;
        frame.size.height = frame.size.height/7;
        locatorTitle.frame = frame;
        
        self.txtField = [[UITextField alloc] init];
        [self.locatorView addSubview:self.txtField];
        //        self.txtField.layer.cornerRadius = 12.0;
        //        self.txtField.layer.borderWidth = 2.0;
        self.txtField.borderStyle = UITextBorderStyleRoundedRect;
        [self.txtField setBackgroundColor:[UIColor whiteColor]];
        self.txtField.keyboardType = UIKeyboardTypeAlphabet;
        self.txtField.returnKeyType = UIReturnKeySearch;
        self.txtField.delegate = self;
        //        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
        //        self.txtField.leftView = paddingView;
        //        self.txtField.leftViewMode = UITextFieldViewModeAlways;
        
        frame.size = CGSizeMake(200, 30);
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.txtField.frame = frame;
            self.txtField.center = CGPointMake(self.locatorView.frame.size.width/2, self.locatorView.frame.size.height/2);
        }
        else {
            frame.origin = CGPointMake(self.locatorView.frame.size.width/2-100, locatorTitle.frame.origin.y+locatorTitle.frame.size.height+5);
            self.txtField.frame = frame;
            
        }
        self.txtField.placeholder = @"Enter Zip Code";
        
        
        // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidEndEditing:) name:UITextFieldTextDidEndEditingNotification object:self.txtField];
        self.txtField.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    }
    else {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.locatorView.frame   = CGRectInset(self.bottomView.bounds, 100, 100);
        }
        else {
            self.locatorView.frame   = CGRectInset(self.bottomView.bounds, 10, 10);
            
        }
    }
}

#pragma mark - TextView delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    iskeyboardVisible = YES;
    
    if (UIInterfaceOrientationIsLandscape([(UIViewController *)self.parentView interfaceOrientation])) {
        CGRect rect = self.locatorView.frame;
        rect.origin.y = 5;
        [UIView animateWithDuration:0.3 animations:^{
            self.locatorView.frame = rect;
        }];
    }
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    iskeyboardVisible = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.locatorView.frame = CGRectInset(self.bottomView.bounds, 100, 100);
    }];
    
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    BOOL isValidZip = [self validateZipCode:textField.text];
    if(isValidZip) {
        [self setupMapView];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please enter a valid Zip code" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    [textField resignFirstResponder];
    return YES;
}

- (void)setupMapView {
    self.locatorView.hidden = YES;
    self.mapView.hidden = NO;
    if (nil == self.mapView) {
        self.mapView = [[MKMapView alloc] initWithFrame:CGRectInset(self.bottomView.bounds, 10, 10)];
        [self.bottomView addSubview:self.mapView];
        self.mapView.autoresizingMask = self.locatorView.autoresizingMask;
    }
    [self fetchLatLonForZipCode];
    
}


- (void)fetchLatLonForZipCode {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:self.txtField.text forKey:@"locatiorClickedForZip"];

    NSString *url  = [NSString stringWithFormat:@"http://maps.google.com/maps/api/geocode/json?address=%@&sensor=false",self.txtField.text];
    //Formulate the string as URL object.
    NSURL *googleRequestURL=[NSURL URLWithString:url];
    
    // Retrieve the results of the URL.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSData dataWithContentsOfURL: googleRequestURL];
        [self performSelectorOnMainThread:@selector(fetchedGeoData:) withObject:data waitUntilDone:YES];
    });
}
- (void)fetchedGeoData:(NSData *)responseData {
    //parse out the json data
    NSError* error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:responseData
                          
                          options:kNilOptions
                          error:&error];
    
    //The results from Google will be an array obtained from the NSDictionary object with the key "results".
    NSArray* places = [json objectForKey:@"results"];
    
    //Write out the data to the console.
    //ECLog(@"Google Data: %@", places);
    
    //Plot the data in the places array onto the map with the plotPostions method.
    //    [self plotPositions:places];
    if ([places count])
        [self fetchNearbyStores:[places lastObject]];
    
    
}


- (void)fetchNearbyStores:(NSDictionary *)data {
    int  currenDist = 1000000;
    NSDictionary *geo = [data objectForKey:@"geometry"];
    NSDictionary *loc = [geo objectForKey:@"location"];
    
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    
    span.latitudeDelta=1;//0.01;
    span.longitudeDelta=1;//0.01;
    
    CLLocationCoordinate2D location=CLLocationCoordinate2DMake([[loc objectForKey:@"lat"] doubleValue], [[loc objectForKey:@"lng"] doubleValue]);
    
    region.span=span;
    region.center=location;
    
    [self.mapView setRegion:region animated:TRUE];
    [self.mapView regionThatFits:region];
    [self.mapView setCenterCoordinate:location animated:YES];
    
    
    
    
    //NSString *url  =@"http://maps.google.com/maps/api/geocode/json?address=600051&sensor=false";
    NSString *url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/search/json?keyword=%@&location=%f,%f&radius=%@&sensor=false&key=%@",[[self.parentView responseDict] objectForKey:@"brand"],[[loc objectForKey:@"lat"] doubleValue], [[loc objectForKey:@"lng"] doubleValue],[NSString stringWithFormat:@"%i", currenDist], kGOOGLE_API_KEY];
    
    //Formulate the string as URL object.
    NSURL *googleRequestURL=[NSURL URLWithString:url];
    
    // Retrieve the results of the URL.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSData dataWithContentsOfURL: googleRequestURL];
        [self performSelectorOnMainThread:@selector(fetchedStoreData:) withObject:data waitUntilDone:YES];
    });
    
}

- (void)fetchedStoreData:(NSData *)responseData {
    //parse out the json data
    NSError* error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:responseData
                          
                          options:kNilOptions
                          error:&error];
    
    //The results from Google will be an array obtained from the NSDictionary object with the key "results".
    NSArray* places = [json objectForKey:@"results"];
    
    //Write out the data to the console.
    //ECLog(@"Google Data: %@", places);
    
    //Plot the data in the places array onto the map with the plotPostions method.
    //    [self plotPositions:places];
    if ([places count])
        [self plotPositions:places];
    
    
}


- (void)plotPositions:(NSArray *)data
{
    //Remove any existing custom annotations but not the user location blue dot.
    for (id<MKAnnotation> annotation in self.mapView.annotations)
    {
        if ([annotation isKindOfClass:[ECAdMapPoint class]])
        {
            [self.mapView removeAnnotation:annotation];
        }
    }
    
    
    //Loop through the array of places returned from the Google API.
    for (int i=0; i<[data count]; i++)
    {
        
        //Retrieve the NSDictionary object in each index of the array.
        NSDictionary* place = [data objectAtIndex:i];
        
        //There is a specific NSDictionary object that gives us location info.
        NSDictionary *geo = [place objectForKey:@"geometry"];
        
        
        //Get our name and address info for adding to a pin.
        NSString *name=[place objectForKey:@"name"];
        NSString *vicinity=[place objectForKey:@"vicinity"];
        
        //Get the lat and long for the location.
        NSDictionary *loc = [geo objectForKey:@"location"];
        
        //Create a special variable to hold this coordinate info.
        CLLocationCoordinate2D placeCoord;
        
        //Set the lat and long.
        placeCoord.latitude=[[loc objectForKey:@"lat"] doubleValue];
        placeCoord.longitude=[[loc objectForKey:@"lng"] doubleValue];
        
        //Create a new annotiation.
        ECAdMapPoint *placeObject = [[ECAdMapPoint alloc] initWithName:name address:vicinity coordinate:placeCoord];
        
        
        [self.mapView addAnnotation:placeObject];
    }
    
    
    @try {
        double upperLatitude = [[[[[data objectAtIndex:0] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"] doubleValue];
        double lowerLatitude =[[[[[data lastObject] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"] doubleValue];
        
        double upperLongitude = [[[[[data objectAtIndex:0] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"] doubleValue];
        double lowerLongitude =[[[[[data lastObject] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"] doubleValue];
        
        MKCoordinateSpan locationSpan;
        locationSpan.latitudeDelta = upperLatitude - lowerLatitude;
        locationSpan.longitudeDelta = upperLongitude - lowerLongitude;
        CLLocationCoordinate2D locationCenter;
        locationCenter.latitude = (upperLatitude + lowerLatitude) / 2;
        locationCenter.longitude = (upperLongitude + lowerLongitude) / 2;
        
        MKCoordinateRegion region = MKCoordinateRegionMake(locationCenter, locationSpan);
        [self.mapView setRegion:region animated:YES];
    }
    @catch (NSException *exception) {
    }
}

- (BOOL)validateZipCode:(NSString *)string {
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([string rangeOfCharacterFromSet:notDigits].location == NSNotFound)
        return YES;
    
    return NO;
    
}
- (void)socialBtnClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"socialBtnClicked"];

    [self.txtField resignFirstResponder];
    
    [self.galleryBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.storeBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.socialBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [self setupSocialView];
}
- (void)galleryBtnClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"galleryBtnClicked"];

    [self.txtField resignFirstResponder];
    [self.socialBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.galleryBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [self.storeBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self setupGalleryView];
    
}

- (void)twitterBtnClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"twitterBtnClicked"];

    isTwitterOpen = YES;
    [self.twitterBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [self.fbBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self setupTwitterView];
    
}
- (void)fBBtnClicked {
    isTwitterOpen = NO;
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"fBBtnClicked"];

    [self.fbBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [self.twitterBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self setupFbView];
    
}

- (void)picturesBtnClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"picturesBtnClicked"];

    [self.picturesBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [self.videosBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self setupPicturesView];
}

- (void)videosBtnClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"videosBtnClicked"];

    NSMutableDictionary *imagesDict = [(ECModalVideoPlaylistAdViewController *)self.parentView videoThumbDict];
    if (![imagesDict count]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Currently no Video Content Available" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    [self.videosBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [self.picturesBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self setupVideoView];
}

- (void)setupVideoView {
    self.galleryImage.hidden = YES;
    self.playlistTableView.hidden = NO;
    self.verticalSeperatorLine.hidden = NO;
    self.moviePlayer.view.hidden = NO;
    if (nil == self.playlistTableView) {
        self.playlistTableView = [[UITableView alloc] init];
        self.playlistTableView.delegate = self;
        self.playlistTableView.dataSource = self;
        [self.playlistTableView setShowsHorizontalScrollIndicator:NO];
        [self.playlistTableView setShowsVerticalScrollIndicator:NO];
        
        [self.bottomView addSubview:self.playlistTableView];
        self.playlistTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        self.playlistTableView.showsVerticalScrollIndicator = NO;
        CGRect rect = self.galleryImage.frame;
        rect.origin.x = 5;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            rect.size.width = 200;
        else
            rect.size.width = (self.bottomView.frame.size.width /2) - 50;
        
        self.playlistTableView.frame = rect;
        [self.playlistTableView setBackgroundColor:self.bottomView.backgroundColor];
        
        self.verticalSeperatorLine = [[UIView alloc] init];
        [self.bottomView addSubview:self.verticalSeperatorLine];
        [self.verticalSeperatorLine setBackgroundColor:[UIColor grayColor]];
        self.verticalSeperatorLine.layer.cornerRadius = 6.0;
        
        rect = self.playlistTableView.frame;
        
        self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:@"http://devefence.engageclick.com/videos/walmart/main/18082-Walmart.mp4"]];
        self.moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleTopMargin;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            rect.origin.x += rect.size.width+20;
            rect.origin.y += 20;
            rect.size.width = 2;
            rect.size.height -= 40;
            self.verticalSeperatorLine.frame = rect;
            self.verticalSeperatorLine.autoresizingMask = UIViewAutoresizingFlexibleHeight;
            
            rect.origin.x += 50;
            rect.origin.y += 20;
            rect.size = CGSizeMake(self.bottomView.frame.size.width - (self.verticalSeperatorLine.frame.origin.x + 100),self.playlistTableView.frame.size.height-50);
        }
        else {
            rect.origin.x += rect.size.width+5;
            rect.origin.y += 20;
            rect.size.width = 2;
            rect.size.height -= 40;
            self.verticalSeperatorLine.frame = rect;
            self.verticalSeperatorLine.autoresizingMask = UIViewAutoresizingFlexibleHeight;
            
            rect.origin.x += 5;
            rect.origin.y += 20;
            rect.size = CGSizeMake(self.bottomView.frame.size.width - (self.verticalSeperatorLine.frame.origin.x+10),self.playlistTableView.frame.size.height-50);
        }
        
        
        self.moviePlayer.view.frame = rect;
        [self.moviePlayer setControlStyle:MPMovieControlStyleNone];
        [self.bottomView addSubview:self.moviePlayer.view];
        //[self.moviePlayer prepareToPlay];
        //[self.moviePlayer play];
        currentImageIndex = 0;
        [self.playlistTableView reloadData];
        [self.playlistTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
        self.movieThumb = [[UIImageView alloc] initWithFrame:self.moviePlayer.view.bounds];
        [self.moviePlayer.view addSubview:self.movieThumb];
        
        UITableViewCell *cell = [self.playlistTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        UIImageView *imageView = (UIImageView *)[cell viewWithTag:currentImageIndex + ECAdGalleryImageTag];
        [imageView.layer setBorderWidth:ECADGallerySelectionWidth];
        [imageView.layer setBorderColor:[UIColor orangeColor].CGColor];
        
        self.movieThumb.image = imageView.image;
        self.movieThumb.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.movieThumb.contentMode = UIViewContentModeScaleAspectFit;
        [self.moviePlayer.view bringSubviewToFront:self.movieThumb];
        [self.movieThumb setUserInteractionEnabled:YES];
        
        self.playbtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.playbtn addTarget:self action:@selector(playBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self.playbtn setImage:[UIImage imageWithData:[[self.parentView delegate] loadFile:@"play.png"]] forState:UIControlStateNormal];
        [self.movieThumb addSubview:self.playbtn];
        
        rect.size = CGSizeMake(50, 50);
        
        self.playbtn.frame = rect;
        self.playbtn.center = self.movieThumb.center;
        self.playbtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
        
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.galleryImage willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if (self.socialTableView && !self.socialTableView.hidden)
        [self.socialTableView reloadData];
}


- (void)layoutFrames {
    self.playbtn.center = self.movieThumb.center;
    [self.movieThumb bringSubviewToFront:self.playbtn];
    
    CGRect frame = self.galleryImage.bounds;
    frame.size = CGSizeMake(30, 30);
    frame.origin.y = (self.galleryImage.frame.size.height/2) - (frame.size.height/2);
    self.leftBtn.frame = frame;
    
    frame.origin.x = self.galleryImage.frame.size.width - (frame.size.width);
    self.rightBtn.frame  =frame;
    
    if (iskeyboardVisible && UIInterfaceOrientationIsLandscape([(UIViewController *)self.parentView interfaceOrientation])) {
        CGRect rect = self.locatorView.frame;
        rect.origin.y = 5;
        iskeyboardVisible = YES;
        [UIView animateWithDuration:0.3 animations:^{
            self.locatorView.frame = rect;
        }];
        
    }
    // self.txtField.center = CGPointMake((self.locatorView.frame.size.width-frame.size.width)/2, (self.locatorView.frame.size.height-frame.size.height)/2);
    
    
}
- (void) playBtnClicked {
    self.movieThumb.hidden = YES;
    [self.moviePlayer setContentURL:[NSURL URLWithString:[self getCurrentVideoUrl]]];
    [self.moviePlayer prepareToPlay];
    [self.moviePlayer play];
}

- (NSString *)getCurrentVideoUrl {
    NSString *media = [[self.parentView responseDict] objectForKey:@"similarmedia"];
    NSArray *urls = [media componentsSeparatedByString:@","];
    
    if (currentImageIndex > [urls count])
        return @"";
    return [urls objectAtIndex:currentImageIndex];
}

- (void)setupFbView {
    [self setupTwitterView];
}

- (void)setupTwitterView {
    if (nil == self.socialTableView) {
        self.socialTableView = [[UITableView alloc] initWithFrame:self.galleryImage.frame];
        self.socialTableView.backgroundColor = [UIColor clearColor];
        self.socialTableView.dataSource = self;
        self.socialTableView.delegate = self;
        self.socialTableView.autoresizingMask = self.galleryImage.autoresizingMask;
        [self.bottomView addSubview:self.socialTableView];
        [self.socialTableView setShowsHorizontalScrollIndicator:NO];
        [self.socialTableView setShowsVerticalScrollIndicator:NO];
        
    }
    
    [self.socialTableView reloadData];
}

- (void)setupPicturesView {
    self.galleryImage.hidden = NO;
    self.playlistTableView.hidden = YES;
    self.verticalSeperatorLine.hidden = YES;
    self.moviePlayer.view.hidden = YES;
    if (nil == self.galleryImage) {
        currentImageIndex = 0;
        // NSMutableDictionary *imageDict = [(ECModalVideoPlaylistAdViewController *)self.parentView getImageDict];
        
        //self.galleryImage = [[UIImageView alloc] initWithImage:[imageDict objectForKey:[NSString stringWithFormat:@"%d",currentImageIndex]]];
        self.galleryImage = [[ECAdGalleryView alloc] initWithDelegate:self];
        [self.bottomView addSubview:self.galleryImage];
        
        CGRect frame = self.bottomView.bounds;
        frame.origin.y += self.titleStripView.frame.size.height;
        frame.size.height -= frame.origin.y;
        [self.galleryImage setFrame:frame];
        self.galleryImage.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.galleryImage setAutoresizesSubviews:YES];
        self.galleryImage.userInteractionEnabled = YES;
        [self.galleryImage setBackgroundColor:[UIColor clearColor]];
        //        self.galleryImage.contentMode = UIViewContentModeScaleAspectFit;
        self.leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.leftBtn setImage:[UIImage imageWithData:[[self.parentView delegate] loadFile:@"LeftArrow.png"]] forState:UIControlStateNormal];
        [self.leftBtn addTarget:self action:@selector(leftBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self.galleryImage setupGallery];
        [self.galleryImage addSubview:self.leftBtn];
        
        frame = self.galleryImage.bounds;
        frame.size = CGSizeMake(30, 30);
        frame.origin.y = (self.galleryImage.frame.size.height/2) - (frame.size.height/2);
        self.leftBtn.frame = frame;
        self.leftBtn.enabled = NO;
        self.rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.rightBtn setImage:[UIImage imageWithData:[[self.parentView delegate] loadFile:@"RightArrow.png"]] forState:UIControlStateNormal];
        [self.rightBtn addTarget:self action:@selector(rightBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        frame.origin.x = self.galleryImage.frame.size.width - (frame.size.width);
        self.rightBtn.frame  =frame;
        
        [self.galleryImage addSubview:self.rightBtn];
        
        self.rightBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
        self.leftBtn.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
        
    }
}

- (void)leftBtnClicked {
    currentImageIndex = [self.galleryImage getPageIndex];
    if (currentImageIndex <= 0) {
        self.leftBtn.enabled = NO;
        self.rightBtn.enabled = YES;
        return;
    }
    currentImageIndex --;
    [self toggleDirectionBtn];
    
    [self.galleryImage moveToOffset:CGPointMake(currentImageIndex*self.galleryImage.frame.size.width, 0)];
    //    NSMutableDictionary *imageDict = [(ECModalVideoPlaylistAdViewController *)self.parentView getImageDict];
    //
    //    CATransition *navTransition = [CATransition animation];
    //    navTransition.duration = 0.65;
    //    navTransition.timingFunction = [CAMediaTimingFunction
    //                                    functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    //    [navTransition setType:kCATransitionPush];
    //    [navTransition setSubtype:kCATransitionFromRight];
    //    [self.galleryImage.layer
    //     addAnimation:navTransition forKey:nil];
    //self.galleryImage.image = [imageDict objectForKey:[NSString stringWithFormat:@"%d",currentImageIndex]];
}
- (void)rightBtnClicked {
    NSMutableDictionary *imageDict = [(ECModalVideoPlaylistAdViewController *)self.parentView getImageDict];
    currentImageIndex = [self.galleryImage getPageIndex];
    if (currentImageIndex >= imageDict.count-1) {
        self.leftBtn.enabled = YES;
        self.rightBtn.enabled = NO;
        return;
    }
    
    currentImageIndex ++;
    [self toggleDirectionBtn];
    
    
    
    [self.galleryImage moveToOffset:CGPointMake(currentImageIndex*self.galleryImage.frame.size.width, 0)];
    
    //    CATransition *navTransition = [CATransition animation];
    //    navTransition.duration = 0.65;
    //    navTransition.timingFunction = [CAMediaTimingFunction
    //                                    functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    //    [navTransition setType:kCATransitionPush];
    //    [navTransition setSubtype:kCATransitionFromLeft];
    //    [self.galleryImage.layer
    //     addAnimation:navTransition forKey:nil];
    //self.galleryImage.image = [imageDict objectForKey:[NSString stringWithFormat:@"%d",currentImageIndex]];
    
    
}

- (void)scrollViewDidEndDecelerating {
    currentImageIndex = [self.galleryImage getPageIndex];
    [self toggleDirectionBtn];
}
- (void)toggleDirectionBtn {
    NSMutableDictionary *imageDict = [(ECModalVideoPlaylistAdViewController *)self.parentView getImageDict];
    
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

- (void)setupSocialView {
    [self layoutSocialButtons];
    [self fBBtnClicked];
    self.galleryImage.hidden =YES;
    self.locatorView.hidden =YES;
    self.videosBtn.hidden =YES;
    self.mapView.hidden =YES;
    self.picturesBtn.hidden =YES;
    self.twitterBtn.hidden = NO;
    self.fbBtn.hidden = NO;
    self.titleStripView.hidden = NO;
    self.socialTableView.hidden = NO;
    
    self.playlistTableView.hidden = YES;
    self.verticalSeperatorLine.hidden = YES;
    self.moviePlayer.view.hidden = YES;
    
}

- (void)layoutSocialButtons {
    self.fbBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.fbBtn setTitle:@"Facebook" forState:UIControlStateNormal];
    [self.fbBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.fbBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    
    [self.fbBtn addTarget:self action:@selector(fBBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.titleStripView addSubview:self.fbBtn];
    //[self.galleryBtn setBackgroundColor:[UIColor yellowColor]];
    CGRect rect = self.titleStripView.bounds;
    
    
    self.twitterBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.twitterBtn setTitle:@"Twitter" forState:UIControlStateNormal];
    [self.twitterBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.twitterBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    
    [self.twitterBtn addTarget:self action:@selector(twitterBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.titleStripView addSubview:self.twitterBtn];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        rect.origin.x = rect.size.width - (5.5*100);
        rect.origin.y = rect.size.height - 30;
        rect.size = CGSizeMake(100, 20);
        self.fbBtn.frame = rect;
        
        rect = self.fbBtn.frame;
        rect.origin.x += rect.size.width+8;
        //    rect.size.width += 80;
        self.twitterBtn.frame = rect;
        
        rect = self.twitterBtn.frame;
        rect.origin.x -= 4;
        rect.size.width = 2;
        self.buttonSeperator.frame = rect;
        [self.twitterBtn.titleLabel setFont:[UIFont systemFontOfSize:20]];
        [self.fbBtn.titleLabel setFont:[UIFont systemFontOfSize:20]];
    }
    else {
        rect.origin.x = 10;
        rect.origin.y = rect.size.height - 30;
        rect.size = CGSizeMake(80, 20);
        self.fbBtn.frame = rect;
        
        rect = self.fbBtn.frame;
        rect.origin.x += rect.size.width+10;
        //    rect.size.width += 80;
        self.twitterBtn.frame = rect;
        
        rect = self.twitterBtn.frame;
        rect.origin.x -= 4;
        rect.size.width = 2;
        self.buttonSeperator.frame = rect;
        [self.twitterBtn.titleLabel setFont:[UIFont systemFontOfSize:12]];
        [self.fbBtn.titleLabel setFont:[UIFont systemFontOfSize:12]];
        
    }
    
    self.buttonSeperator.autoresizingMask = self.fbBtn.autoresizingMask = self.twitterBtn.autoresizingMask  = UIViewAutoresizingFlexibleLeftMargin;
    
}
- (void)setupGalleryView {
    [self setupBottomView];
    [self picturesBtnClicked];
    self.titleStripView.hidden = NO;
    self.picturesBtn.hidden = NO;
    self.videosBtn.hidden = NO;
    self.socialTableView.hidden =YES;
    self.locatorView.hidden =YES;
    self.mapView.hidden =YES;
    self.twitterBtn.hidden =YES;
    self.fbBtn.hidden = YES;
    
}

- (void)setupBottomView {
    self.buttonSeperator.hidden = NO;
    if (nil == self.bottomView) {
        UIViewController *vc = (UIViewController *)self.parentView;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            if (UIInterfaceOrientationIsLandscape(vc.interfaceOrientation))
                self.bottomView  =[[UIView alloc] initWithFrame:CGRectMake(self.topView.frame.origin.x, self.topView.frame.origin.y+self.topView.frame.size.height+3, self.topView.frame.size.width, 422)];
            else
                self.bottomView  =[[UIView alloc] initWithFrame:CGRectMake(self.topView.frame.origin.x, self.topView.frame.origin.y+self.topView.frame.size.height+3, self.topView.frame.size.width, 670)];
        }
        else {
            self.bottomView  =[[UIView alloc] initWithFrame:CGRectMake(self.topView.frame.origin.x, self.topView.frame.origin.y+self.topView.frame.size.height+3, self.topView.frame.size.width,self.frame.size.height-(self.topView.frame.origin.y+self.topView.frame.size.height+10))];
        }
        
        self.bottomView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.bottomView setAutoresizesSubviews:YES];
        [self addSubview:self.bottomView];
        [self.bottomView setBackgroundColor:[UIColor colorWithRed:133.0/255.0 green:195.0/255.0 blue:232.0/255.0 alpha:1.0]];
        //        UIImage *bgImage = [UIImage imageNamed:@"PictureGalleryBackground.png"];
        //       bgImage =  [bgImage stretchableImageWithLeftCapWidth:bgImage.size.width/2 topCapHeight:bgImage.size.height/2];
        //        [self.bottomView setBackgroundColor:[UIColor colorWithPatternImage:bgImage]];
        self.titleStripView = [[UIView alloc] init];
        self.titleStripView.backgroundColor = [UIColor lightGrayColor];
        self.titleStripView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.bottomView addSubview:self.titleStripView];
        self.bottomView.clipsToBounds = YES;
        
        
        CGRect rect = self.bottomView.bounds;
        rect.size.height = 50;
        self.titleStripView.frame = rect;
        
        
        self.picturesBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.picturesBtn setTitle:@"Pictures" forState:UIControlStateNormal];
        [self.picturesBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.picturesBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
        
        [self.picturesBtn addTarget:self action:@selector(picturesBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self.titleStripView addSubview:self.picturesBtn];
        //[self.galleryBtn setBackgroundColor:[UIColor yellowColor]];
        
        self.videosBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.videosBtn setTitle:@"Videos" forState:UIControlStateNormal];
        [self.videosBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.videosBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
        
        [self.videosBtn addTarget:self action:@selector(videosBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self.titleStripView addSubview:self.videosBtn];
        //[self.storeBtn setBackgroundColor:[UIColor yellowColor]];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            rect = self.titleStripView.bounds;
            rect.origin.x = rect.size.width - (4*100);
            rect.origin.y = rect.size.height - 30;
            rect.size = CGSizeMake(100, 20);
            self.picturesBtn.frame = rect;
            
            rect = self.picturesBtn.frame;
            rect.origin.x += rect.size.width+8;
            //    rect.size.width += 80;
            self.videosBtn.frame = rect;
            [self.picturesBtn.titleLabel setFont:[UIFont systemFontOfSize:20]];
            [self.videosBtn.titleLabel setFont:[UIFont systemFontOfSize:20]];
            
        }
        else {
            rect = self.titleStripView.bounds;
            rect.origin.x =10;
            rect.origin.y = rect.size.height - 30;
            rect.size = CGSizeMake(50, 20);
            self.picturesBtn.frame = rect;
            
            rect = self.picturesBtn.frame;
            rect.origin.x += rect.size.width+10;
            //    rect.size.width += 80;
            self.videosBtn.frame = rect;
            
            [self.picturesBtn.titleLabel setFont:[UIFont systemFontOfSize:12]];
            [self.videosBtn.titleLabel setFont:[UIFont systemFontOfSize:12]];
            
            
        }
        
        self.buttonSeperator = [[UIView alloc] init];
        [self.buttonSeperator setBackgroundColor:[UIColor colorWithRed:121.0/255.0 green:121.0/225.0 blue:121.0/255.0 alpha:1.0]];
        [self.bottomView addSubview:self.buttonSeperator];
        
        rect = self.videosBtn.frame;
        rect.origin.x -= 4;
        rect.size.width = 2;
        self.buttonSeperator.frame = rect;
        
        
        self.buttonSeperator.autoresizingMask = self.videosBtn.autoresizingMask = self.picturesBtn.autoresizingMask  = UIViewAutoresizingFlexibleLeftMargin;
    }
    else {
        CGRect rect = self.videosBtn.frame;
        rect.origin.x -= 4;
        rect.size.width = 2;
        self.buttonSeperator.frame = rect;
        
    }
    
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
    if (tableView == self.playlistTableView) {
        NSMutableDictionary *imagesDict = [(ECModalVideoPlaylistAdViewController *)self.parentView videoThumbDict];
        
        return imagesDict.count;
    }
    else {
        if (isTwitterOpen)
            return [self.parentView twitterContentDict].count;
        return [self.parentView fbContentDict].count;
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return 120;
    return 80;
}

#pragma mark - TableView Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    UITableViewCell *cell = nil;
    if (tableView == self.playlistTableView) {
        [tableView dequeueReusableCellWithIdentifier:@"Identifier"];
        
        if (!cell) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Identifier"];
            [cell setBackgroundColor:tableView.backgroundColor];
        }
        //            [cell.contentView addSubview:[self getSelectedBGView]];
        [cell setBackgroundView:[self getContentViewForIndexpath:indexPath]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    else if (tableView == self.socialTableView) {
        if (isTwitterOpen) {
            NSArray *keys = [[self.parentView twitterContentDict] allKeys];
            
            if (!cell) {
                cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TwitterIdentifier"];
                [cell setBackgroundColor:tableView.backgroundColor];
                UIButton *twitterButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [twitterButton setImage:[UIImage imageWithData:[[self.parentView delegate] loadFile:@"twitter_Icon.png"]] forState:UIControlStateNormal];
                [twitterButton addTarget:self action:@selector(twitterButtonClicked) forControlEvents:UIControlEventTouchUpInside];
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
                    twitterButton.frame = CGRectMake(self.socialTableView.frame.size.width - 40, 5, 25, 25);
                else
                    twitterButton.frame = CGRectMake(self.socialTableView.frame.size.width - 40, 2, 20, 20);
                
                [cell addSubview:twitterButton];
                
            }
            NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
            keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
            
            NSDictionary *twitterContent = [[self.parentView twitterContentDict] objectForKey:[keys objectAtIndex:indexPath.row]];
            if (twitterContent.count)
                [cell setBackgroundView:[self getTwitterContentViewForContent:twitterContent]];
            
        }
        else {
            if (!cell) {
                cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"FBIdentifier"];
                [cell setBackgroundColor:tableView.backgroundColor];
                
                UIButton *fbButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [fbButton setImage:[UIImage imageWithData:[[self.parentView delegate] loadFile:@"fb_Icon.png"]] forState:UIControlStateNormal];
                [fbButton addTarget:self action:@selector(fbButtonClicked) forControlEvents:UIControlEventTouchUpInside];
                // [baseView addSubview:fbButton];
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
                    fbButton.frame = CGRectMake(self.socialTableView.frame.size.width - 40, 5, 25, 25);
                else
                    fbButton.frame = CGRectMake(self.socialTableView.frame.size.width - 40, 2, 20, 20);
                [cell addSubview:fbButton];
                
            }
            
            NSArray *keys = [[self.parentView fbContentDict] allKeys];
            NSDictionary *fbContent = [[self.parentView fbContentDict] objectForKey:[keys objectAtIndex:indexPath.row]];
            
            NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
            keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
            
            //            [cell setBackgroundView:[self getFBContentViewForContent:fbContent]];
            [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
            [cell addSubview:[self getFBContentViewForContent:fbContent]];
            
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    }
    
    return cell;
    
}

- (UIView *)getFBContentViewForContent:(NSDictionary *)fbContent {
    UIView *baseView = [[UIView alloc] init];
    UIImageView *imageView = nil;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 100, 100)];
    else
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 50, 50)];
    
    [imageView setContentMode:UIViewContentModeScaleToFill];
    [baseView addSubview:imageView];
    imageView.image =  [[self.parentView socialImages ] objectForKey:[fbContent objectForKey:@"picture"]];
    
    
    UILabel *userName =    [[UILabel alloc] initWithFrame:CGRectMake(imageView.frame.origin.x + imageView.frame.size.width+2, imageView.frame.origin.y, 120, 20)];
    
    [userName setBackgroundColor:[UIColor clearColor]];
    [userName setTextColor:[UIColor blackColor]];
    //    [userName setFont:[UIFont boldSystemFontOfSize:12]];
    
    
    UIFont *font = [UIFont fontWithName:@"Georgia-Bold" size:20.0];
    [userName setFont:font];
    
    
    [baseView addSubview:userName];
    [userName setText:[fbContent objectForKey:@"username"]];
    
    font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:18];
    /*
     UIButton *fbButton = [UIButton buttonWithType:UIButtonTypeCustom];
     [fbButton setImage:[UIImage imageNamed:@"fb_Icon.png"] forState:UIControlStateNormal];
     [fbButton addTarget:self action:@selector(fbButtonClicked) forControlEvents:UIControlEventTouchUpInside];
     [baseView addSubview:fbButton];
     fbButton.frame = CGRectMake(self.socialTableView.frame.size.width - 40, userName.frame.origin.y, 20, 20);*/
    
    UILabel *descView = nil;//[[UILabel alloc] initWithFrame:CGRectMake(userName.frame.origin.x, userName.frame.origin.y+userName.frame.size.height, 550, 100)];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        descView = [[UILabel alloc] initWithFrame:CGRectMake(userName.frame.origin.x, userName.frame.origin.y+userName.frame.size.height, 550, 100)];
        [userName setFont: [UIFont fontWithName:@"Georgia-Bold" size:20.0]];
        descView.font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:18];
    }
    else {
        descView = [[UILabel alloc] initWithFrame:CGRectMake(userName.frame.origin.x, userName.frame.origin.y+userName.frame.size.height, self.socialTableView.frame.size.width -imageView.frame.size.width - 10, 50)];
        [userName setFont: [UIFont fontWithName:@"Georgia-Bold" size:15.0]];
        descView.font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:12.0];
        
    }
    
    
    [descView setBackgroundColor:[UIColor clearColor]];
    [descView setTextColor:[UIColor blackColor]];
    [descView setNumberOfLines:0];
    descView.text = [fbContent objectForKey:@"message"];
    [baseView addSubview:descView];
    
    return baseView;
    
    
}
- (UIView *)getTwitterContentViewForContent:(NSDictionary *)twitterContent {
    UIView *baseView = [[UIView alloc] init];
    [baseView setBackgroundColor:[UIColor clearColor]];
    UIImageView *imageView = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 100, 100)];
    else
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 50, 50)];
    
    [imageView setContentMode:UIViewContentModeScaleToFill];
    [baseView addSubview:imageView];
    imageView.image =  [[self.parentView socialImages] objectForKey:[twitterContent objectForKey:@"iconurl"]];
    
    UILabel *userName = [[UILabel alloc] initWithFrame:CGRectMake(imageView.frame.origin.x + imageView.frame.size.width+2, imageView.frame.origin.y, 120, 20)];
    [userName setBackgroundColor:[UIColor clearColor]];
    [userName setTextColor:[UIColor blackColor]];
    [baseView addSubview:userName];
    [userName setText:[twitterContent objectForKey:@"username"]];
    
    
    //    UIButton *twitterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //    [twitterButton setImage:[UIImage imageNamed:@"twitter_Icon.png"] forState:UIControlStateNormal];
    //    [twitterButton addTarget:self action:@selector(twitterButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    //    [baseView addSubview:twitterButton];
    //    twitterButton.frame = CGRectMake(self.socialTableView.frame.size.width - 40, userName.frame.origin.y, 20, 20);
    
    UILabel *descView = nil;//[[UILabel alloc] initWithFrame:CGRectMake(userName.frame.origin.x, userName.frame.origin.y+userName.frame.size.height, 550, 100)];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        descView = [[UILabel alloc] initWithFrame:CGRectMake(userName.frame.origin.x, userName.frame.origin.y+userName.frame.size.height, 550, 100)];
        [userName setFont: [UIFont fontWithName:@"Georgia-Bold" size:20.0]];
        descView.font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:18];
    }
    else {
        descView = [[UILabel alloc] initWithFrame:CGRectMake(userName.frame.origin.x, userName.frame.origin.y+userName.frame.size.height, self.socialTableView.frame.size.width -imageView.frame.size.width - 10, 50)];
        [userName setFont: [UIFont fontWithName:@"Georgia-Bold" size:15.0]];
        descView.font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:12.0];
        
    }
    
    
    [descView setBackgroundColor:[UIColor clearColor]];
    [descView setTextColor:[UIColor blackColor]];
    //    [descView setFont:[UIFont systemFontOfSize:12]];
    
    [descView setNumberOfLines:0];
    descView.text = [twitterContent objectForKey:@"message"];
    [baseView addSubview:descView];
    
    
    return baseView;
}
- (void)fbButtonClicked {
    NSString *fbURL = [[self.parentView responseDict] objectForKey:@"fbtargeturl"];
    if ([fbURL length]) {
        [[ECAdManager sharedManager] videoAdLandingPageOpened:fbURL];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbURL]];
    }
}

- (void)twitterButtonClicked {
    NSString *twitterURL = [[self.parentView responseDict] objectForKey:@"twtargeturl"];
    if ([twitterURL length]) {
        [[ECAdManager sharedManager] videoAdLandingPageOpened:twitterURL];

        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:twitterURL]];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    
    if (tableView == self.playlistTableView) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        if (currentImageIndex >= 0) {
            UITableViewCell *prevCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:currentImageIndex inSection:0]];
            UIImageView *prevImage = (UIImageView *)[prevCell viewWithTag:currentImageIndex + ECAdGalleryImageTag];
            [prevImage.layer setBorderWidth:0.0];
        }
        
        
        UIImageView *imageView = (UIImageView *)[cell viewWithTag:indexPath.row + ECAdGalleryImageTag];
        
        [imageView.layer setBorderWidth:ECADGallerySelectionWidth];
        [imageView.layer setBorderColor:[UIColor orangeColor].CGColor];
        
        self.movieThumb.image = imageView.image;
        currentImageIndex = indexPath.row;
        [self.moviePlayer stop];
        self.movieThumb.hidden = NO;
        
    }
    else {
        if (isTwitterOpen) {
            NSArray *keys = [[self.parentView twitterContentDict] allKeys];
            NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
            keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
            
            NSDictionary *fbContent = [[self.parentView twitterContentDict] objectForKey:[keys objectAtIndex:indexPath.row]];
            if ([[fbContent objectForKey:@"message"] length]) {
                NSString *tweet =[self getTwitterLink:[fbContent objectForKey:@"message"]];
                [[ECAdManager sharedManager] videoAdLandingPageOpened:tweet];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:tweet]];
            }
        }
        else {
            NSArray *keys = [[self.parentView fbContentDict] allKeys];
            NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
            keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
            
            NSDictionary *fbContent = [[self.parentView fbContentDict] objectForKey:[keys objectAtIndex:indexPath.row]];
            if ([[fbContent objectForKey:@"clickurl"] length]) {
                [[ECAdManager sharedManager] videoAdLandingPageOpened:[fbContent objectForKey:@"clickurl"]];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[fbContent objectForKey:@"clickurl"]]];
            }
            
        }
        
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
    NSMutableDictionary *imageDict = [(ECModalVideoPlaylistAdViewController *)self.parentView videoThumbDict];
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.image = [imageDict objectForKey:[NSString stringWithFormat:@"%d",indexPath.row]];
    [imageView setTag:indexPath.row + ECAdGalleryImageTag];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    if (currentImageIndex >= 0) {
        if (indexPath.row == currentImageIndex) {
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

- (void)dealloc {
    
}
@end
