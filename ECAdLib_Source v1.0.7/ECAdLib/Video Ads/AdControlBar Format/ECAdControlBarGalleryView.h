//
//  ControlBarGalleryView.h
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/14/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>


typedef enum
{
    kECControlBarGallery,
    kECControlBarVideo,
    kECControlBarFacebook,
    kECControlBarTwitter,
    kECControlBarLocator
} kECAdControlBarFormat;

@interface ECAdControlBarGalleryView : UIView<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic) kECAdControlBarFormat controlBarFormat;
@property (nonatomic, assign) id delegate;
- (id)initWithControlBarFormat:(kECAdControlBarFormat)format withDelegate:(id)delegate_;
- (void)initialize;
- (void)layoutFrames:(UIInterfaceOrientation )interfaceOrientation;
- (void)showGalleryView;

@end
