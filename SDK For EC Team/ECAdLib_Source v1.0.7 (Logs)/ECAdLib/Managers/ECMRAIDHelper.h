//
//  MRAIDHelper.h
//  ECAdLib
//
//  Created by Karthik Kumaravel on 7/18/13.
//  Copyright (c) 2013 EngageClick. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MRProperty.h"
#import "MPGlobal.h"

@interface ECMRAIDHelper : NSObject
@property (nonatomic, assign) UIWebView *webView;

+ (ECMRAIDHelper *)sharedHelper;

- (void)initializeJavascriptState:(MRAdViewPlacementType)_placementType state:(MRAdViewState)_currentState;
- (void)fireNativeCommandCompleteEvent:(NSString *)command;
- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation;
- (void)fireChangeEventForProperty:(MRProperty *)property;
@end
