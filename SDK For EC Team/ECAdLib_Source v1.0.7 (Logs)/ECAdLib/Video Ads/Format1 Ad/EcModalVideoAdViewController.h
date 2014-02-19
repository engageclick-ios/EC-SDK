//
//  ViewController.h
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/3/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface EcModalVideoAdViewController : UIViewController<UIActionSheetDelegate>
@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, strong) NSString *basePath;
@property (nonatomic, strong) NSMutableDictionary *responseDict;

@end

