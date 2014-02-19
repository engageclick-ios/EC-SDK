//
//  ECVideoPlaylistFormSheetViewController.h
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/9/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ECVideoPlaylistFormSheetView : UIView<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>

@property (nonatomic, assign) id parentView;
- (void)setupTopView;
- (void)layoutFrames;
- (void)scrollViewDidEndDecelerating;
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
@end
