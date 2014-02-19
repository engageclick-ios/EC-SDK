//
//  ControlBarGalleryView.m
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/14/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import "ECAdControlBarGalleryView.h"
#import "ECModalVideoPlaylistAdViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/QuartzCore.h>
#import <MapKit/MapKit.h>
#import "ECAdMapPoint.h"
#import "ECAdCarousel.h"
#import "EcAdReflectionView.h"
#import "ECAdManager.h"
#import "ECAdConstants.h"

#define ECAdGalleryImageTag 3000
#define ECADGallerySelectionWidth 4
#define kGOOGLE_API_KEY @"AIzaSyBO25quts5C-FJFt5zdLuZWOmPLU58h5uQ"
#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )


@interface ECAdControlBarGalleryView ()<iCarouselDataSource,iCarouselDelegate> {
    int selectedImage;
    BOOL isSmartSkip;
    CGRect skipRect;
    UILabel *dragLabel;
}
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *dragImageView;

@property (nonatomic, strong) UITableView *galleryTableView;
@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UITableView *socialTableView;
@property (nonatomic, strong) UITextField *txtField;
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) ECAdCarousel *carousel;

@end
@implementation ECAdControlBarGalleryView
@synthesize carousel;

- (id)initWithControlBarFormat:(kECAdControlBarFormat)format withDelegate:(id)delegate_
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.delegate  = delegate_;
        self.controlBarFormat = format;
        if ([delegate_ adFormat] == kECAdSmartSkip)
            isSmartSkip = YES;
        // Initialization code
    }
    return self;
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    UITouch *touch = [[event allTouches] anyObject];
    if ([touch view] == self.dragImageView) {
        CGPoint newTouchLocation = [[touches anyObject] locationInView:self];
        //        CGPoint newTouch = [self convertPoint:newTouchLocation toView:[(UIViewController *)self.delegate view]];
        //        CGRect rect = self.frame;
        //        rect.origin.y = newTouch.y;
        CGPoint dragTouch = newTouchLocation;
        CGRect frame = self.dragImageView.frame;
        frame.origin.x = dragTouch.x - (self.dragImageView.frame.size.width/2);
        frame.origin.y = dragTouch.y - (self.dragImageView.frame.size.height/2);
        
        if (frame.origin.x < self.imageView.bounds.origin.x || frame.origin.x+frame.size.width > self.imageView.frame.size.width || frame.origin.y < self.imageView.bounds.origin.y || frame.origin.y+frame.size.height > self.imageView.frame.size.height)
            return;
        
        if (CGRectContainsPoint(frame, dragTouch))
            self.dragImageView.center = newTouchLocation;
    }
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    UITouch *touch = [[event allTouches] anyObject];
    if ([touch view] == self.dragImageView ) {
        if (CGRectIntersectsRect(skipRect,self.dragImageView.frame)  && selectedImage == [self.delegate sequenceForSkip]) {
            [UIView animateWithDuration:0.3 animations:^{
                self.dragImageView.frame = skipRect;
                self.dragImageView.transform = CGAffineTransformMakeScale(1.3, 1.3);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.3 animations:^{
                    self.dragImageView.transform = CGAffineTransformIdentity;
                    if ([self.delegate respondsToSelector:@selector(smartSkippableInteractionSuccess)])
                        [self.delegate smartSkippableInteractionSuccess];
                    
                }];
            }];
        }
        else {
            [UIView animateWithDuration:0.3 animations:^{
                self.dragImageView.frame = CGRectMake(0, 0, self.dragImageView.frame.size.width, self.dragImageView.frame.size.height);
            } completion:^(BOOL finished) {
            }];
            
        }
    }
}



- (CGRect)getCroppedRect:(CGRect )originalRect forImage:(UIImage *)image {
    UIImageView *imageView = self.imageView;
    
    CGSize imageSize = image.size;
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



- (void)initialize {
    switch (self.controlBarFormat) {
        case kECControlBarGallery: {
            [self setupGalleryView];
            self.galleryTableView.hidden = NO;
        }
            break;
        case kECControlBarVideo: {
            [self setupVideoView];
        }
            break;
        case kECControlBarLocator:
            [self setupLocatorView];
            break;
        case kECControlBarFacebook:
            [self setupFbView];
            break;
        case kECControlBarTwitter:
            [self setupTwitterView];
            break;
        default:
            break;
    }
}


- (void)setupLocatorView {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        self.txtField = [[UITextField alloc] initWithFrame:CGRectInset(CGRectMake(0, 0, self.frame.size.width, 60), 100, 10)];
    else
        self.txtField = [[UITextField alloc] initWithFrame:CGRectInset(CGRectMake(0, 0, self.frame.size.width, 60), 40, 10)];
    [self addSubview:self.txtField];
    self.txtField.borderStyle = UITextBorderStyleRoundedRect;
    [self.txtField setBackgroundColor:[UIColor whiteColor]];
    self.txtField.keyboardType = UIKeyboardTypeAlphabet;
    self.txtField.returnKeyType = UIReturnKeySearch;
    self.txtField.delegate = self;
    self.txtField.placeholder = @"Enter Zip Code";
    
    self.txtField.autoresizingMask =  UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
    
    self.closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"close_Icon.png"]] forState:UIControlStateNormal];
    [self.closeBtn addTarget:self action:@selector(closeBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.closeBtn];
    [self.closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    CGRect rect = self.bounds;
    rect.origin.x = rect.size.width - 40;
    rect.origin.y = 5;
    rect.size = CGSizeMake(30, 30);
    self.closeBtn.frame = rect;
    [self bringSubviewToFront:self.closeBtn];
    
    if (nil == self.mapView) {
        self.mapView = [[MKMapView alloc] initWithFrame:CGRectInset(CGRectMake(0, self.txtField.frame.origin.y + self.txtField.frame.size.height, self.frame.size.width, self.frame.size.height - (self.txtField.frame.origin.y+self.txtField.frame.size.height)), 10, 10)];
        [self addSubview:self.mapView];
        self.mapView.autoresizingMask = self.autoresizingMask;
    }
    
}
#pragma mark - TextView delegate

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
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:self.txtField.text forKey:@"locatorclickedforzip"];

    self.mapView.hidden = NO;
    [self fetchLatLonForZipCode];
    
}


- (void)fetchLatLonForZipCode {
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
    
    [self.mapView setRegion:region animated:YES];
    //   [self.mapView regionThatFits:region];
    //  [self.mapView setCenterCoordinate:location animated:YES];
    
    
    
    
    //NSString *url  =@"http://maps.google.com/maps/api/geocode/json?address=600051&sensor=false";
    
    //    NSString *url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/search/json?keyword=%@&location=%f,%f&radius=%@&sensor=false&key=%@",@"nissan_dealerships"/*[[self.delegate responseDict] objectForKey:@"brand"]*/,[[loc objectForKey:@"lat"] doubleValue], [[loc objectForKey:@"lng"] doubleValue],[NSString stringWithFormat:@"%i", currenDist], kGOOGLE_API_KEY];
    NSString *url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/search/json?keyword=%@&location=%f,%f&radius=%@&sensor=false&key=%@",[[self.delegate responseDict] objectForKey:@"brand"],[[loc objectForKey:@"lat"] doubleValue], [[loc objectForKey:@"lng"] doubleValue],[NSString stringWithFormat:@"%i", currenDist], kGOOGLE_API_KEY];
    
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
    if (![responseData length]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"No Nearby Location Found" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
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
        
        
        //    MKCoordinateRegion region = MKCoordinateRegionMake(locationCenter, locationSpan);
        //     [self.mapView setRegion:region animated:YES];
        //            [self.mapView setCenter:self.mapView.userLocation.coordinate animated:YES];
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
- (void)setupFbView {
    if (nil == self.socialTableView) {
        self.socialTableView = [[UITableView alloc] initWithFrame:CGRectInset(self.bounds, 20, 20)];
        self.socialTableView.backgroundColor = [UIColor clearColor];
        self.socialTableView.dataSource = self;
        self.socialTableView.delegate = self;
        self.socialTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.socialTableView];
        [self.socialTableView setShowsHorizontalScrollIndicator:NO];
        [self.socialTableView setShowsVerticalScrollIndicator:NO];
        self.closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"close_Icon.png"]] forState:UIControlStateNormal];
        [self.closeBtn addTarget:self action:@selector(closeBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.closeBtn];
        [self.closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
        CGRect rect = self.bounds;
        rect.origin.x = rect.size.width - 40;
        rect.origin.y = 5;
        rect.size = CGSizeMake(30, 30);
        self.closeBtn.frame = rect;
        [self bringSubviewToFront:self.closeBtn];
    }
    [self.socialTableView reloadData];
    
    
}
- (void)setupTwitterView {
    if (nil == self.socialTableView) {
        self.socialTableView = [[UITableView alloc] initWithFrame:CGRectInset(self.bounds, 20, 20)];
        self.socialTableView.backgroundColor = [UIColor clearColor];
        self.socialTableView.dataSource = self;
        self.socialTableView.delegate = self;
        self.socialTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.socialTableView];
        [self.socialTableView setShowsHorizontalScrollIndicator:NO];
        [self.socialTableView setShowsVerticalScrollIndicator:NO];
        
        self.closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"close_Icon.png"]] forState:UIControlStateNormal];
        [self.closeBtn addTarget:self action:@selector(closeBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.closeBtn];
        [self.closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
        CGRect rect = self.bounds;
        rect.origin.x = rect.size.width - 40;
        rect.origin.y = 5;
        rect.size = CGSizeMake(30, 30);
        self.closeBtn.frame = rect;
        [self bringSubviewToFront:self.closeBtn];
    }
    [self.socialTableView reloadData];
}
- (void)setupGalleryView1 {
    if (nil == self.imageView) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height - 300)];
        else
            self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height - 200)];
        
        [self addSubview: self.imageView];
        [self.imageView setUserInteractionEnabled:YES];
        [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self.imageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self.imageView setBackgroundColor:[UIColor clearColor]];
        
        self.closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"close_Icon.png"]] forState:UIControlStateNormal];
        [self.closeBtn addTarget:self action:@selector(closeBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.closeBtn];
        [self.closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
        
        CGRect rect = self.imageView.bounds;
        rect.origin.x = rect.size.width - 40;
        rect.origin.y = 5;
        rect.size = CGSizeMake(30, 30);
        self.closeBtn.frame = rect;
        [self bringSubviewToFront:self.closeBtn];
    }
    if (nil == self.galleryTableView) {
        self.galleryTableView = [[UITableView alloc] init];
        [self.galleryTableView setAutoresizingMask:UIViewAutoresizingNone];
        self.galleryTableView.delegate = self;
        self.galleryTableView.dataSource  = self;
        self.galleryTableView.hidden = YES;
        //   [self addSubview:self.galleryTableView];
        [self.galleryTableView setBackgroundColor:[UIColor blackColor]];
        
        [self.galleryTableView setShowsHorizontalScrollIndicator:NO];
        [self.galleryTableView setShowsVerticalScrollIndicator:NO];
        if (nil == self.carousel) {
            self.carousel = [[ECAdCarousel alloc] initWithFrame:CGRectMake(0, self.imageView.frame.origin.y+self.imageView.frame.size.height, self.frame.size.width, self.frame.size.height - (self.imageView.frame.origin.y+self.imageView.frame.size.height+13))];
            self.carousel.delegate = self;
            self.carousel.dataSource = self;
            [self addSubview:self.carousel];
            carousel.type = iCarouselTypeCoverFlow2;
            self.carousel.clipsToBounds = YES;
            [self.carousel setBackgroundColor:[UIColor viewFlipsideBackgroundColor]];
            [self setBackgroundColor:[UIColor viewFlipsideBackgroundColor]];
            [self.carousel setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth];
        }
        //  carousel.type = iCarouselTypeCoverFlow;
        
        //        [self.carousel reloadData];
        CGRect rect = self.imageView.frame;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            rect.size.height = self.frame.size.height/2;
            // self.backgroundColor =[UIColor blackColor];
        }
        
        if (UIInterfaceOrientationIsLandscape([self.delegate interfaceOrientation])) {
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                rect.origin = CGPointMake(337,58);
                rect.size.width = self.frame.size.height- rect.size.height;
            }
            else {
                rect.origin = CGPointMake(175,-9);
                rect.size.width = self.frame.size.height- rect.size.height-40;//120;//400;
            }
            
            rect.size.height = self.imageView.frame.size.width;//tableFrame.size.width;//300;
        }
        else {
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                rect.origin = CGPointMake((self.frame.size.height- rect.size.height)+60,  (rect.size.width/2)+160);
                rect.size.width = self.frame.size.height- rect.size.height;//120;//400;
                rect.size.height = self.imageView.frame.size.width;//tableFrame.size.width;//300;
                
            }
            else {
                if (IS_IPHONE_5)
                    rect.origin = CGPointMake((self.frame.size.height- rect.size.height)-192,  (rect.size.width/2)+88);
                else
                    rect.origin = CGPointMake((self.frame.size.height- rect.size.height)-125,  (rect.size.width/2)+81);
                
                rect.size.width = self.frame.size.height- rect.size.height-100;//120;//400;
                rect.size.height = self.imageView.frame.size.width;//tableFrame.size.width;//300;
                
            }
        }
        
        
        self.galleryTableView.frame = rect;
        self.galleryTableView.transform = CGAffineTransformMakeRotation(-M_PI * 0.5);
        self.galleryTableView.showsHorizontalScrollIndicator = NO;
        self.galleryTableView.showsVerticalScrollIndicator = NO;
        
        self.galleryTableView.layer.cornerRadius = 20.0;
        // self.galleryTableView.layer.borderWidth = 4.0;
        //self.galleryTableView.layer.borderColor = [UIColor whiteColor].CGColor;
        NSMutableDictionary *imageDict = nil;//
        if (self.controlBarFormat == kECControlBarGallery)
            imageDict = [(ECModalVideoPlaylistAdViewController *)self.delegate imageDict];
        else
            imageDict = [self.delegate videoThumbDict];
        
        if (selectedImage < 0 || selectedImage > imageDict.count)
            selectedImage = 0;
        
        self.imageView.image = [imageDict objectForKey:[NSString stringWithFormat:@"%d",selectedImage]];
    }
    if (isSmartSkip) {
        NSMutableDictionary *imageDict = [(ECModalVideoPlaylistAdViewController *)self.delegate imageDict];
        skipRect = [self getCroppedRect:[self.delegate frameForSkip] forImage:[imageDict objectForKey:[NSString stringWithFormat:@"%d",[self.delegate sequenceForSkip]]]];
        
        if (nil == self.dragImageView) {
            self.dragImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:[self.delegate loadFile:@"dragImage.png"]]];
            [self.imageView addSubview: self.dragImageView];
            [self.dragImageView setUserInteractionEnabled:YES];
            [self.dragImageView setContentMode:UIViewContentModeScaleAspectFit];
            [self.dragImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
            [self.dragImageView setBackgroundColor:[UIColor clearColor]];
            dragLabel = [[UILabel alloc] init];
            dragLabel.text = @"Navigate throught the images and drag the tile to its matching matching place";
            [dragLabel setBackgroundColor:[UIColor colorWithRed:1.0/255.0 green:1.0/255.0 blue:1.0/255.0 alpha:0.3]];
            [self.imageView addSubview:dragLabel];
            [dragLabel setTextAlignment:NSTextAlignmentCenter];
            dragLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            dragLabel.numberOfLines = 0;
            [dragLabel setTextColor:[UIColor blackColor]];
            [dragLabel setFont:[UIFont systemFontOfSize:18]];
            
        }
        self.dragImageView.frame = CGRectMake(0, 0, skipRect.size.width, skipRect.size.height);
        dragLabel.frame = CGRectMake(self.dragImageView.frame.origin.x + self.dragImageView.frame.size.width, 2, self.imageView.frame.size.width - self.dragImageView.frame.size.width-35, 60);
        
        
    }
    
}
- (void)setupGalleryView {
    if (nil == self.imageView) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height - 300)];
        else
            self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height - 200)];
        
        [self addSubview: self.imageView];
        [self.imageView setUserInteractionEnabled:YES];
        [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self.imageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self.imageView setBackgroundColor:[UIColor clearColor]];
        
        self.closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"close_Icon.png"]] forState:UIControlStateNormal];
        [self.closeBtn addTarget:self action:@selector(closeBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.closeBtn];
        [self.closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
        
        CGRect rect = self.imageView.bounds;
        rect.origin.x = rect.size.width - 40;
        rect.origin.y = 5;
        rect.size = CGSizeMake(30, 30);
        self.closeBtn.frame = rect;
        [self bringSubviewToFront:self.closeBtn];
    }
    if (nil == self.carousel) {
        self.carousel = [[ECAdCarousel alloc] initWithFrame:CGRectMake(0, self.imageView.frame.origin.y+self.imageView.frame.size.height, self.frame.size.width, self.frame.size.height - (self.imageView.frame.origin.y+self.imageView.frame.size.height+13))];
        self.carousel.delegate = self;
        self.carousel.dataSource = self;
        [self addSubview:self.carousel];
        carousel.type = iCarouselTypeCoverFlow2;
        self.carousel.clipsToBounds = YES;
        [self.carousel setBackgroundColor:[UIColor viewFlipsideBackgroundColor]];
        [self setBackgroundColor:[UIColor viewFlipsideBackgroundColor]];
        [self.carousel setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth];
        NSMutableDictionary *imageDict = nil;//
        if (self.controlBarFormat == kECControlBarGallery)
            imageDict = [(ECModalVideoPlaylistAdViewController *)self.delegate imageDict];
        else
            imageDict = [self.delegate videoThumbDict];
        
        if (selectedImage < 0 || selectedImage > imageDict.count)
            selectedImage = 0;
        
        self.imageView.image = [imageDict objectForKey:[NSString stringWithFormat:@"%d",selectedImage]];
    }
    if (isSmartSkip) {
        NSMutableDictionary *imageDict = [(ECModalVideoPlaylistAdViewController *)self.delegate imageDict];
        skipRect = [self getCroppedRect:[self.delegate frameForSkip] forImage:[imageDict objectForKey:[NSString stringWithFormat:@"%d",[self.delegate sequenceForSkip]]]];
        
        if (nil == self.dragImageView) {
            self.dragImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:[self.delegate loadFile:@"dragImage.png"]]];
            [self.imageView addSubview: self.dragImageView];
            [self.dragImageView setUserInteractionEnabled:YES];
            [self.dragImageView setContentMode:UIViewContentModeScaleAspectFit];
            [self.dragImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
            [self.dragImageView setBackgroundColor:[UIColor clearColor]];
            dragLabel = [[UILabel alloc] init];
            dragLabel.text = @"Navigate throught the images and drag the tile to its matching matching place";
            [dragLabel setBackgroundColor:[UIColor colorWithRed:1.0/255.0 green:1.0/255.0 blue:1.0/255.0 alpha:0.3]];
            [self.imageView addSubview:dragLabel];
            [dragLabel setTextAlignment:NSTextAlignmentCenter];
            dragLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            dragLabel.numberOfLines = 0;
            [dragLabel setTextColor:[UIColor lightTextColor]];
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
                [dragLabel setFont:[UIFont systemFontOfSize:18]];
            else
                [dragLabel setFont:[UIFont systemFontOfSize:12]];
            
            [dragLabel setAdjustsFontSizeToFitWidth:YES];
        }
        self.dragImageView.frame = CGRectMake(0, 0, skipRect.size.width, skipRect.size.height);
        dragLabel.frame = CGRectMake(self.dragImageView.frame.origin.x + self.dragImageView.frame.size.width, 2, self.imageView.frame.size.width - self.dragImageView.frame.size.width-35, 60);
        
        
    }
    
}


- (void)setupVideoView {
    [self setupGalleryView];
    self.galleryTableView.hidden = NO;
    self.playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playBtn addTarget:self action:@selector(playBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.playBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"play.png"]] forState:UIControlStateNormal];
    [self.imageView addSubview:self.playBtn];
    CGRect rect = CGRectZero;
    rect.size = CGSizeMake(50, 50);
    
    self.playBtn.frame = rect;
    self.playBtn.center = self.imageView.center;
    self.playBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    
}

- (NSString *)getCurrentVideoUrl {
    NSString *media = [[self.delegate responseDict] objectForKey:@"similarmedia"];
    NSArray *urls = [media componentsSeparatedByString:@","];
    
    if (selectedImage > [urls count])
        return @"";
    return [urls objectAtIndex:selectedImage];
}
- (void)playBtnClicked {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:[self getCurrentVideoUrl] forKey:@"controlBarVideoPlayed"];

    self.imageView.hidden = YES;
    if (nil == self.moviePlayer) {
        self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:[self getCurrentVideoUrl]]];
        self.moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleTopMargin;
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            self.moviePlayer.view.frame = CGRectInset(self.imageView.frame, 10, 10);//self.imageView.frame;
        else {
            CGRect frm = CGRectInset(self.imageView.frame, 10, 10);//self.imageView.frame;
            //            frm.size.height -= 120;
            self.moviePlayer.view.frame = frm;
        }
        [self.moviePlayer setControlStyle:MPMovieControlStyleNone];
        [self addSubview:self.moviePlayer.view];
        
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [closeBtn setImage:[UIImage imageWithData:[self.delegate loadFile:@"close_Icon.png"]] forState:UIControlStateNormal];
        [closeBtn addTarget:self action:@selector(closeBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self.moviePlayer.view addSubview:closeBtn];
        [closeBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
        
        CGRect rect = self.moviePlayer.view.bounds;
        rect.origin.x = rect.size.width - 40;
        rect.origin.y = 5;
        rect.size = CGSizeMake(30, 30);
        closeBtn.frame = rect;
        [self.moviePlayer.view bringSubviewToFront:closeBtn];
    }
    self.moviePlayer.view.hidden = NO;
    [self.moviePlayer prepareToPlay];
    [self.moviePlayer play];
    [self bringSubviewToFront:self.playBtn];
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)layoutFrames:(UIInterfaceOrientation )interfaceOrientation {
    [self layoutGalleryTableView:interfaceOrientation];
}
- (void)showGalleryView {
    [[[ECAdManager sharedManager] getVideoLogDict] setObject:@"yes" forKey:@"GalleryViewShown"];

    self.galleryTableView.hidden = NO;
}
- (void)layoutGalleryTableView:(UIInterfaceOrientation)interfaceOrientation {
    if (self.galleryTableView) {
        [self.galleryTableView removeFromSuperview];
        self.galleryTableView = nil;
        [self setupGalleryView];
    }
    [self.socialTableView reloadData];
}
- (void)closeBtnClicked {
    if ([self.delegate respondsToSelector:@selector(controlAdViewClosed)])
        [self.delegate performSelector:@selector(controlAdViewClosed)];
}


#pragma mark -
#pragma mark TableView Data Source
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 10.0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 10.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor clearColor]];
    return view;
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor clearColor]];
    return view;
}
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    if (self.controlBarFormat == kECControlBarGallery)
        return [[(ECModalVideoPlaylistAdViewController *)self.delegate imageDict] count];
    else if (self.controlBarFormat == kECControlBarVideo)
        return [[(ECModalVideoPlaylistAdViewController *)self.delegate videoThumbDict] count];
    
    else if (self.controlBarFormat == kECControlBarFacebook)
        return [self.delegate fbContentDict].count;
    else if (self.controlBarFormat ==  kECControlBarTwitter)
        return [self.delegate twitterContentDict].count;
    return 0;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && (self.controlBarFormat == kECControlBarFacebook || self.controlBarFormat ==  kECControlBarTwitter))
        return 80;
    
    return 120;
}
#pragma mark - TableView Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    UITableViewCell *cell = nil;[tableView dequeueReusableCellWithIdentifier:@"Identifier"];
    
    if (self.controlBarFormat == kECControlBarGallery || self.controlBarFormat == kECControlBarVideo) {
        if (!cell) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Identifier"];
            [cell setBackgroundColor:tableView.backgroundColor];
        }
        // [cell.contentView addSubview:[self getSelectedBGView]];
        [cell setBackgroundView:[self getContentViewForIndexpath:indexPath]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        cell.transform = CGAffineTransformMakeRotation(M_PI * 0.5);
    }
    else if (self.controlBarFormat == kECControlBarTwitter) {
        NSArray *keys = [[self.delegate twitterContentDict] allKeys];
        if (!cell) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TwitterIdentifier"];
            [cell setBackgroundColor:tableView.backgroundColor];
            UIButton *twitterButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [twitterButton setImage:[UIImage imageWithData:[self.delegate loadFile:@"twitter_Icon.png"]] forState:UIControlStateNormal];
            
            [twitterButton addTarget:self action:@selector(twitterButtonClicked) forControlEvents:UIControlEventTouchUpInside];
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
                twitterButton.frame = CGRectMake(self.socialTableView.frame.size.width - 40, 2, 20, 20);
            else
                twitterButton.frame = CGRectMake(self.socialTableView.frame.size.width - 40, 5, 25, 25);
            [cell addSubview:twitterButton];
            
            
        }
        NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
        keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
        
        NSDictionary *twitterContent = [[self.delegate twitterContentDict] objectForKey:[keys objectAtIndex:indexPath.row]];
        if (twitterContent.count)
            [cell setBackgroundView:[self getTwitterContentViewForContent:twitterContent]];
        
    }
    else if (self.controlBarFormat == kECControlBarFacebook) {
        if (!cell) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"FBIdentifier"];
            [cell setBackgroundColor:tableView.backgroundColor];
            
            UIButton *fbButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [fbButton setImage:[UIImage imageWithData:[self.delegate loadFile:@"fb_Icon.png"]] forState:UIControlStateNormal];
            [fbButton addTarget:self action:@selector(fbButtonClicked) forControlEvents:UIControlEventTouchUpInside];
            // [baseView addSubview:fbButton];
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
                fbButton.frame = CGRectMake(self.socialTableView.frame.size.width - 40, 2, 20, 20);
            else
                fbButton.frame = CGRectMake(self.socialTableView.frame.size.width - 40, 5, 25, 25);
            [cell addSubview:fbButton];
            
        }
        
        NSArray *keys = [[self.delegate fbContentDict] allKeys];
        NSDictionary *fbContent = [[self.delegate fbContentDict] objectForKey:[keys objectAtIndex:indexPath.row]];
        
        NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
        keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
        
        //            [cell setBackgroundView:[self getFBContentViewForContent:fbContent]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        [cell addSubview:[self getFBContentViewForContent:fbContent]];
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        
    }
    
    return cell;
}

- (UIView *)getFBContentViewForContent:(NSDictionary *)fbContent {
    UIView *baseView = [[UIView alloc] init];
    
    UIImageView *imageView = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 50, 50)];
    else
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 100, 100)];
    [imageView setContentMode:UIViewContentModeScaleToFill];
    [baseView addSubview:imageView];
    imageView.image =  [[self.delegate socialImages ] objectForKey:[fbContent objectForKey:@"picture"]];
    
    
    UILabel *userName = [[UILabel alloc] initWithFrame:CGRectMake(imageView.frame.origin.x + imageView.frame.size.width+5, imageView.frame.origin.y, 120, 20)];
    [userName setBackgroundColor:[UIColor clearColor]];
    [userName setTextColor:[UIColor blackColor]];
    //    [userName setFont:[UIFont boldSystemFontOfSize:12]];
    
    
    UIFont *font = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        font = [UIFont fontWithName:@"Georgia-Bold" size:12.0];
    else
        font = [UIFont fontWithName:@"Georgia-Bold" size:20.0];
    
    [userName setFont:font];
    
    [baseView addSubview:userName];
    [userName setText:[fbContent objectForKey:@"username"]];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:12.0];
    else
        font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:20.0];    /*
                                                                         UIButton *fbButton = [UIButton buttonWithType:UIButtonTypeCustom];
                                                                         [fbButton setImage:[UIImage imageNamed:@"fb_Icon.png"] forState:UIControlStateNormal];
                                                                         [fbButton addTarget:self action:@selector(fbButtonClicked) forControlEvents:UIControlEventTouchUpInside];
                                                                         [baseView addSubview:fbButton];
                                                                         fbButton.frame = CGRectMake(self.socialTableView.frame.size.width - 40, userName.frame.origin.y, 20, 20);*/
    
    UILabel *descView = nil;//[[UILabel alloc] initWithFrame:CGRectMake(userName.frame.origin.x, userName.frame.origin.y+userName.frame.size.height, 400, 100)];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        descView = [[UILabel alloc] initWithFrame:CGRectMake(userName.frame.origin.x, userName.frame.origin.y+userName.frame.size.height, 400, 100)];
    else
        descView = [[UILabel alloc] initWithFrame:CGRectMake(userName.frame.origin.x, userName.frame.origin.y+userName.frame.size.height, self.socialTableView.frame.size.width -imageView.frame.size.width - 10, 50)];
    
    [descView setBackgroundColor:[UIColor clearColor]];
    [descView setTextColor:[UIColor blackColor]];
    descView.font = font;
    [descView setNumberOfLines:0];
    descView.text = [fbContent objectForKey:@"message"];
    [baseView addSubview:descView];
    
    return baseView;
    
    
}
- (UIView *)getTwitterContentViewForContent:(NSDictionary *)twitterContent {
    UIView *baseView = [[UIView alloc] init];
    [baseView setBackgroundColor:[UIColor clearColor]];
    
    UIImageView *imageView = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 50, 50)];
    else
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 100, 100)];
    [imageView setContentMode:UIViewContentModeScaleToFill];
    [baseView addSubview:imageView];
    imageView.image =  [[self.delegate socialImages] objectForKey:[twitterContent objectForKey:@"iconurl"]];
    
    UILabel *userName = [[UILabel alloc] initWithFrame:CGRectMake(imageView.frame.origin.x + imageView.frame.size.width+5, imageView.frame.origin.y, 120, 20)];
    [userName setBackgroundColor:[UIColor clearColor]];
    [userName setTextColor:[UIColor blackColor]];
    UIFont *font = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        font = [UIFont fontWithName:@"Georgia-Bold" size:12.0];
    else
        font = [UIFont fontWithName:@"Georgia-Bold" size:20.0];
    
    [userName setFont:font];
    
    [baseView addSubview:userName];
    [userName setText:[twitterContent objectForKey:@"username"]];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:12.0];
    else
        font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:20.0];
    
    
    //    UIButton *twitterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //    [twitterButton setImage:[UIImage imageNamed:@"twitter_Icon.png"] forState:UIControlStateNormal];
    //    [twitterButton addTarget:self action:@selector(twitterButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    //    [baseView addSubview:twitterButton];
    //    twitterButton.frame = CGRectMake(self.socialTableView.frame.size.width - 40, userName.frame.origin.y, 20, 20);
    
    UILabel *descView = nil;//[[UILabel alloc] initWithFrame:CGRectMake(userName.frame.origin.x, userName.frame.origin.y+userName.frame.size.height, 400, 100)];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        descView = [[UILabel alloc] initWithFrame:CGRectMake(userName.frame.origin.x, userName.frame.origin.y+userName.frame.size.height, 400, 100)];
    else
        descView = [[UILabel alloc] initWithFrame:CGRectMake(userName.frame.origin.x, userName.frame.origin.y+userName.frame.size.height, self.socialTableView.frame.size.width -imageView.frame.size.width - 10, 50)];
    
    [descView setBackgroundColor:[UIColor clearColor]];
    [descView setTextColor:[UIColor blackColor]];
    //    [descView setFont:[UIFont systemFontOfSize:12]];
    descView.font = font;
    
    [descView setNumberOfLines:0];
    descView.text = [twitterContent objectForKey:@"message"];
    [baseView addSubview:descView];
    
    
    return baseView;
}


#pragma mark -
#pragma mark iCarousel methods

- (NSUInteger)numberOfItemsInCarousel:(ECAdCarousel *)carousel
{
    if (self.controlBarFormat == kECControlBarGallery)
        return [[(ECModalVideoPlaylistAdViewController *)self.delegate imageDict] count];
    else if (self.controlBarFormat == kECControlBarVideo)
        return [[(ECModalVideoPlaylistAdViewController *)self.delegate videoThumbDict] count];
    return 0;
}

- (UIView *)carousel:(ECAdCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    //    UILabel *label = nil;
    //    view=  [self getContentViewForIndexpath:[NSIndexPath indexPathForRow:index inSection:0]];
    //    return view;
    NSMutableDictionary *imageDict = nil;
    if (self.controlBarFormat == kECControlBarGallery)
        imageDict = [(ECModalVideoPlaylistAdViewController *)self.delegate imageDict];
    else
        imageDict = [self.delegate videoThumbDict];
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        view = [[EcAdReflectionView alloc] initWithFrame:CGRectMake(0, 0, 250, 100)];
        view.contentMode = UIViewContentModeScaleAspectFit;
    }
    ((UIImageView *)view).image = [imageDict objectForKey:[NSString stringWithFormat:@"%d",index]];
    
    //set item label
    //remember to always set any properties of your carousel item
    //views outside of the `if (view == nil) {...}` check otherwise
    //you'll get weird issues with carousel item content appearing
    //in the wrong place in the carousel
    
    return view;
}

- (void)carousel:(ECAdCarousel *)carousel didSelectItemAtIndex:(NSInteger)index {
    if (index == selectedImage) {
        return;
    }
    [self.moviePlayer stop];
    self.moviePlayer.view.hidden = YES;
    
    
    
    UIImageView *imageView = (UIImageView *)[self.carousel itemViewAtIndex:index];
    selectedImage = index;
    [self.imageView setImage:imageView.image];
    [self.moviePlayer.view setHidden:YES];
    self.imageView.hidden = NO;
    
}

/*
 - (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel
 {
 //note: placeholder views are only displayed on some carousels if wrapping is disabled
 return  [[(ECModalVideoPlaylistAdViewController *)self.delegate imageDict] count];
 }
 
 - (UIView *)carousel:(iCarousel *)carousel placeholderViewAtIndex:(NSUInteger)index reusingView:(UIView *)view
 {
 NSMutableDictionary *imageDict = nil;
 if (self.controlBarFormat == kECControlBarGallery)
 imageDict = [(ECModalVideoPlaylistAdViewController *)self.delegate imageDict];
 else
 imageDict = [self.delegate videoThumbDict];
 
 //create new view if no view is available for recycling
 if (view == nil)
 {
 view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200.0f, 200.0f)];
 view.contentMode = UIViewContentModeCenter;
 }
 ((UIImageView *)view).image = [imageDict objectForKey:[NSString stringWithFormat:@"%d",index]];
 
 //set item label
 //remember to always set any properties of your carousel item
 //views outside of the `if (view == nil) {...}` check otherwise
 //you'll get weird issues with carousel item content appearing
 //in the wrong place in the carousel
 
 return view;
 
 }
 
 - (CATransform3D)carousel:(iCarousel *)_carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform
 {
 //implement 'flip3D' style carousel
 transform = CATransform3DRotate(transform, M_PI / 8.0f, 0.0f, 1.0f, 0.0f);
 return CATransform3DTranslate(transform, 0.0f, 0.0f, offset * carousel.itemWidth);
 }
 
 - (CGFloat)carousel1:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
 {
 switch (option)
 {
 case iCarouselOptionFadeMin:
 return -0.2;
 case iCarouselOptionFadeMax:
 return 0.2;
 case iCarouselOptionFadeRange:
 return 2.0;
 default:
 return value;
 }
 }
 
 
 - (CGFloat)carousel:(iCarousel *)_carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
 {
 //customize carousel display
 switch (option)
 {
 case iCarouselOptionWrap:
 {
 //normally you would hard-code this to YES or NO
 return NO;
 }
 case iCarouselOptionSpacing:
 {
 //add a bit of spacing between the item views
 return value * 1.05f;
 }
 case iCarouselOptionFadeMax:
 {
 if (carousel.type == iCarouselTypeCustom)
 {
 //set opacity based on distance from camera
 return 0.0f;
 }
 return value;
 }
 default:
 {
 return value;
 }
 }
 }
 
 */


- (void)fbButtonClicked {
    NSString *fbURL = [[self.delegate responseDict] objectForKey:@"fbtargeturl"];
    if ([fbURL length]) {
        [[ECAdManager sharedManager] videoAdLandingPageOpened:fbURL];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbURL]];
    }
}

- (void)twitterButtonClicked {
    NSString *twitterURL = [[self.delegate responseDict] objectForKey:@"twtargeturl"];
    if ([twitterURL length]) {
        [[ECAdManager sharedManager] videoAdLandingPageOpened:twitterURL];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:twitterURL]];
    }
}



- (UIImageView *)getContentViewForIndexpath:(NSIndexPath *)indexPath {
    NSMutableDictionary *imageDict = nil;
    if (self.controlBarFormat == kECControlBarGallery)
        imageDict = [(ECModalVideoPlaylistAdViewController *)self.delegate imageDict];
    else
        imageDict = [self.delegate videoThumbDict];
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.image = [imageDict objectForKey:[NSString stringWithFormat:@"%d",indexPath.row]];
    [imageView setTag:indexPath.row + ECAdGalleryImageTag];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    imageView.layer.cornerRadius = 20.0;
    
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    
    if (self.controlBarFormat == kECControlBarGallery || self.controlBarFormat == kECControlBarVideo) {
        if (indexPath.row == selectedImage) {
            return;
        }
        [self.moviePlayer stop];
        self.moviePlayer.view.hidden = YES;
        
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
        [self.imageView setImage:imageView.image];
        [self.moviePlayer.view setHidden:YES];
        self.imageView.hidden = NO;
    }
    else if (self.controlBarFormat == kECControlBarTwitter) {
        NSArray *keys = [[self.delegate twitterContentDict] allKeys];
        NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
        keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
        
        NSDictionary *fbContent = [[self.delegate twitterContentDict] objectForKey:[keys objectAtIndex:indexPath.row]];
        if ([[fbContent objectForKey:@"message"] length]) {
            NSString *tweet = [self getTwitterLink:[fbContent objectForKey:@"message"]];
            [[ECAdManager sharedManager] videoAdLandingPageOpened:tweet];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:tweet]];
        }
    }
    else if (self.controlBarFormat == kECControlBarFacebook) {
        NSArray *keys = [[self.delegate fbContentDict] allKeys];
        NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
        keys = [keys sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
        
        NSDictionary *fbContent = [[self.delegate fbContentDict] objectForKey:[keys objectAtIndex:indexPath.row]];
        if ([[fbContent objectForKey:@"clickurl"] length]) {
            NSString *post = [fbContent objectForKey:@"clickurl"];
            [[ECAdManager sharedManager] videoAdLandingPageOpened:post];

            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:post]];
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



/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end
