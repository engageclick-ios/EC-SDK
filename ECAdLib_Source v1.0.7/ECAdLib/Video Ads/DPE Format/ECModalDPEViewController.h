//
//  ECModalDPEViewController.h
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/29/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

typedef enum
{
    kECDPEFormatNFL,
    kECDPEFormatOverlay,
    kECDPEFormatCoupon,
    kECDPEFormatHulu,
    kECDPEFormatCallback,
} kECDPEFormat;

@interface ECModalDPEViewController : UIViewController<UIScrollViewDelegate,MFMailComposeViewControllerDelegate,UIAlertViewDelegate>
@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, strong) NSString *basePath;
@property (nonatomic, assign) kECDPEFormat DPEFormat;
@property (nonatomic, strong) NSMutableDictionary *responseDict;

@end

