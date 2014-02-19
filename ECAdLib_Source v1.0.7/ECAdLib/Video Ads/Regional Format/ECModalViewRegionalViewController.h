//
//  ECModalViewRegionalViewController.h
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 6/10/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ECModalViewRegionalViewController : UIViewController

@property (nonatomic, strong) NSString *primaryURL;
@property (nonatomic, strong) NSString *secondaryURL;
@property (nonatomic, assign) id delegate;
@property double adDuration;
@property (nonatomic, strong) NSMutableDictionary *responseDict;
@end
