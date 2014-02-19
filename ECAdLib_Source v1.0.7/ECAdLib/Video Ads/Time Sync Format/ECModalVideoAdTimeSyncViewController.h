//
//  ECModalVideoAdTimeSyncViewController.h
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/15/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum
{
    kECTimesyncFormatSlideBanner,
    kECTimesyncOverlay,
} kECTimesyncFormat;

@interface ECModalVideoAdTimeSyncViewController : UIViewController
@property (nonatomic, assign) id delegate;
@property (nonatomic, strong) NSMutableDictionary *imageDict;
@property (nonatomic, strong) NSMutableDictionary *responseDict;
@property (nonatomic, strong) NSString *basePath;
@property (nonatomic) kECTimesyncFormat adFormat;

- (NSMutableDictionary *)getImageDict;
@end
