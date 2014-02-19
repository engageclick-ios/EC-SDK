//
//  CustomPlayer.m
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 7/23/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import "EcAdCustomPlayer.h"
#import "ECAdManager.h"

@implementation EcAdCustomPlayer

- (id)init
{
    if ((self = [super init]))
    {
        self.tapGuesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self.tapGuesture setNumberOfTapsRequired:1];
        self.tapGuesture.delegate = self;
        [self.tapGuesture setNumberOfTouchesRequired:1];
        [self.view addGestureRecognizer:self.tapGuesture];
    }
    return self;
}

#pragma mark - gesture delegate
// this allows you to dispatch touches
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}
// this enables you to handle multiple recognizers on single view
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)addGuesture:(UIView *)view {

}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if ([self playbackState] != MPMoviePlaybackStatePlaying)
        return; 
    [self pause];
    if (self.targetURL) {
        [[ECAdManager sharedManager] videoAdLandingPageOpened:self.targetURL];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.targetURL]];
    }
}

@end
