//
//  ViewController.h
//  EC Ad Demo
//
//  Created by Engageclick on 9/20/13.
//  Copyright (c) 2013 Engageclick. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECAdManager.h"

@interface ViewController : UIViewController <ECBannerAdDelegate> {
    BOOL iPad;
}

@property (nonatomic, strong) NSMutableDictionary *adParams;
- (IBAction)showModalAd:(id)sender;
- (IBAction)showBannerAd:(id)sender;

@end
