//
//  CustomPlayer.h
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 7/23/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface EcAdCustomPlayer : MPMoviePlayerController<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UITapGestureRecognizer *tapGuesture;
@property (nonatomic, strong) NSString *targetURL;
- (void)addGuesture:(UIView *)view;
@end
