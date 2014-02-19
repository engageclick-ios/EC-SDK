//
//  MRAIDHelper.m
//  ECAdLib
//
//  Created by Karthik Kumaravel on 7/18/13.
//  Copyright (c) 2013 EngageClick. All rights reserved.
//

#import "ECMRAIDHelper.h"

@implementation ECMRAIDHelper

static id sharedHelper;


- (id)init
{
    if (nil != sharedHelper)
    {
        NSAssert(nil, @"Please do not init a ECAdManager use sharedManager");
        return nil;
    }
    self = [super init];
    if (nil != self)
    {
    }
    return self;
}

#pragma mark - Public
+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHelper = [[ECMRAIDHelper alloc] init];
    });
}

+ (ECMRAIDHelper *)sharedHelper
{
    
    return sharedHelper;
}


#pragma mark - MRAID Java Script Utility

- (void)applyRotationTransformForCurrentOrientationOnView:(UIView *)view {
    // We need to rotate the ad view in the direction opposite that of the device's rotation.
    // For example, if the device is in LandscapeLeft (90 deg. clockwise), we have to rotate
    // the view -90 deg. counterclockwise.
    
    CGFloat angle = 0.0;
    
    switch (MPInterfaceOrientation()) {
        case UIInterfaceOrientationPortraitUpsideDown: angle = M_PI; break;
        case UIInterfaceOrientationLandscapeLeft: angle = -M_PI_2; break;
        case UIInterfaceOrientationLandscapeRight: angle = M_PI_2; break;
        default: break;
    }
    
    view.transform = CGAffineTransformMakeRotation(angle);
}



- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation {
    [self fireChangeEventForProperty:
     [MRScreenSizeProperty propertyWithSize:MPApplicationFrame().size]];
    //    [self applyRotationTransformForCurrentOrientationOnView:self];
    //    [self rotateExpandedWindowsToCurrentOrientation];
}



- (NSString *)executeJavascript:(NSString *)javascript withVarArgs:(va_list)args {
    NSString *js = [[NSString alloc] initWithFormat:javascript arguments:args];
    
    return [_webView stringByEvaluatingJavaScriptFromString:js];
}

- (NSString *)executeJavascript:(NSString *)javascript, ... {
    va_list args;
    va_start(args, javascript);
    NSString *result = [self executeJavascript:javascript withVarArgs:args];
    va_end(args);
    return result;
}

- (void)fireChangeEventForProperty:(MRProperty *)property {
    NSString *JSON = [NSString stringWithFormat:@"{%@}", property];
    [self executeJavascript:@"window.mraidbridge.fireChangeEvent(%@);", JSON];
}
- (void)fireChangeEventsForProperties:(NSArray *)properties {
    NSString *JSON = [NSString stringWithFormat:@"{%@}",
                      [properties componentsJoinedByString:@", "]];
    [self executeJavascript:@"window.mraidbridge.fireChangeEvent(%@);", JSON];
}
- (void)initializeJavascriptState:(MRAdViewPlacementType)_placementType state:(MRAdViewState)_currentState {
    [self fireChangeEventForProperty:[MRPlacementTypeProperty propertyWithType:_placementType]];
    NSArray *properties = [NSArray arrayWithObjects:
                           [MRScreenSizeProperty propertyWithSize:MPApplicationFrame().size],
                           [MRStateProperty propertyWithState:_currentState],
                           nil];
    [self fireChangeEventsForProperties:properties];
    [self fireReadyEvent];
}
- (void)fireReadyEvent {
    [self executeJavascript:@"window.mraidbridge.fireReadyEvent();"];
}


- (void)fireNativeCommandCompleteEvent:(NSString *)command {
    [self executeJavascript:@"window.mraidbridge.nativeCallComplete('%@');", command];
}




@end
