//
//  ECModalVideoInlineSocialViewController.h
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 6/7/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    kECInlineFormatSocialHorizontal,
    kECInlineFormatSocialVertical,
} kECInlineFormat;

@interface ECModalVideoInlineSocialViewController : UIViewController
@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, strong) NSString *basePath;
@property (nonatomic, assign) kECInlineFormat ECInlineFormat;

@end
