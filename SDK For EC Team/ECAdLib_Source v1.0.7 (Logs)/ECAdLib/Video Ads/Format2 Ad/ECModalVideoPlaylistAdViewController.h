//
//  ECModalVideoPlaylistAdViewController.h
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/9/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

typedef enum
{
    kECVideoPlaylist,
    kECAdControlBar,
    kECAdControlOverlay,
    kECAdSmartSkip,
    kECAdSmartSkipSurvey,
} kECAdFormat;

@interface ECModalVideoPlaylistAdViewController : UIViewController

- (NSMutableDictionary *)getResponseDict;
- (NSMutableDictionary *)getImageDict;

@property (nonatomic) kECAdFormat adFormat;
@property (nonatomic, strong) UIImage *logoImage;

@property (nonatomic, strong) NSMutableDictionary *socialImages;
@property (nonatomic, strong) NSMutableDictionary *socialFBImages;

@property (nonatomic, strong) NSMutableDictionary *fbContentDict;
@property (nonatomic, strong) NSMutableDictionary *twitterContentDict;
@property (nonatomic, strong) NSMutableDictionary *responseDict;
@property (nonatomic, strong) NSMutableDictionary *imageDict;
@property (nonatomic, strong) NSMutableDictionary *videoThumbDict;
@property (nonatomic, strong) NSString *basePath;

@property (nonatomic, unsafe_unretained) id delegate;
- (void)formSheetViewDidClose;
- (UIImage *)imageForSkip;
- (CGRect)frameForSkip ;
- (NSInteger)sequenceForSkip;
- (void)smartSkippableInteractionSuccess;
- (void)continueAd;

@end
