//
//  GalleryView.h
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/13/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    kECAdGalleryTypePlaylist,
    kECAdGalleryTypeTimeSync,
} kECAdGalleryType;

@interface ECAdGalleryView : UIView<UIScrollViewDelegate>

@property (nonatomic) kECAdGalleryType galleryType;
- (id)initWithDelegate:(id)parentView_;
- (int)getPageIndex;
- (void)setupGallery;
- (void)moveToOffset:(CGPoint )point;
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;


@end
