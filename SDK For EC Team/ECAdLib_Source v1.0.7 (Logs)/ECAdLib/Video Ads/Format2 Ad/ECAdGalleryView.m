//
//  GalleryView.m
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/13/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import "ECAdGalleryView.h"
#import "ECModalVideoPlaylistAdViewController.h"
#import "ECVideoPlaylistFormSheetView.h"

#define kNoofViews 5
#define ARTICLE_CONTENT_VIEW_TAG 1000

@interface GalleryImageView : UIImageView {
    
}
@end
@implementation GalleryImageView


@end

@interface ECAdGalleryView () {
    int noOfPages;
    int pageIndex;
    BOOL shouldScroll;
    NSInteger oldMediaObjectIndex;
    NSInteger currentPosition;
    
    
}
@property (nonatomic, assign) id parentView;
@property (nonatomic, strong) NSMutableArray *pages;
@property (nonatomic, strong) UIScrollView *scrollView;

@end
@implementation ECAdGalleryView

- (int)getPageIndex {
    return pageIndex;
}
- (id)initWithDelegate:(id)parentView_ {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.parentView = parentView_;
        // Initialization code
    }
    return self;
}

- (void)setupGallery {
    self.pages = [NSMutableArray array];
    NSMutableDictionary *imageDict = (self.galleryType == kECAdGalleryTypePlaylist) ? [(ECModalVideoPlaylistAdViewController *)[(ECVideoPlaylistFormSheetView *)self.parentView parentView]getImageDict] : [self.parentView imageDict];
    noOfPages = imageDict.count;
    
    if (noOfPages <= 0)
        return;
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    [self.scrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self addSubview:self.scrollView];
    self.scrollView.showsHorizontalScrollIndicator = self.scrollView.showsVerticalScrollIndicator = NO;
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * noOfPages, self.scrollView.frame.size.height)];
	[self.scrollView setScrollEnabled:YES];
	self.scrollView.delegate = self;
	self.scrollView.pagingEnabled = YES;
    
    int viewCount;
	if (noOfPages > kNoofViews)
		viewCount = kNoofViews;
	else
		viewCount = noOfPages;
	CGRect viewFrame = self.scrollView.frame;
    
    for(int i=0; i<viewCount ; i++) {
		GalleryImageView *articleContentView = [[GalleryImageView alloc] initWithFrame:viewFrame];
		[self.scrollView addSubview:articleContentView];
        [articleContentView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [articleContentView setContentMode:UIViewContentModeScaleAspectFit];
		[self.pages addObject:articleContentView];
		viewFrame.origin.x += self.scrollView.frame.size.width;
        [articleContentView setImage: [imageDict objectForKey:[NSString stringWithFormat:@"%d",i]]];
        [articleContentView setTag:ARTICLE_CONTENT_VIEW_TAG+i];
	}
}


- (void)moveToOffset:(CGPoint )point {
    [self.scrollView setContentOffset:point animated:YES];
}

#pragma mark
#pragma mark scrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSMutableDictionary *imageDict = (self.galleryType == kECAdGalleryTypePlaylist) ? [(ECModalVideoPlaylistAdViewController *)[(ECVideoPlaylistFormSheetView *)self.parentView parentView]getImageDict] : [self.parentView imageDict];
    
	int additionValue=kNoofViews/2;
	int mediaObjectIndex=0;
	CGFloat pageWidth = _scrollView.frame.size.width;
	pageIndex = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
	mediaObjectIndex = floor((_scrollView.contentOffset.x - pageWidth /additionValue) / pageWidth) + 1;
	
	if(mediaObjectIndex <= -1)
		mediaObjectIndex = 0;
	if(mediaObjectIndex >= [imageDict count])
		mediaObjectIndex = [imageDict count]-1;
	
	if(mediaObjectIndex != oldMediaObjectIndex && !shouldScroll)
	{
		oldMediaObjectIndex = mediaObjectIndex;
		
		int page = floor((_scrollView.contentOffset.x - pageWidth / additionValue) / pageWidth) + 1;
		
		if (page < 0) {
			page = 0;
		} else if ((page >= [imageDict count]) && [imageDict count]) {
			page = [imageDict count] - 1;
		}
		// check if within page bounds
		if (currentPosition >= 0 &&  currentPosition != page) {
			
			if (currentPosition < page) {
				
				if (page + additionValue < [imageDict count] && page - additionValue > 0) {
					int index = page+additionValue;
					
					GalleryImageView *firstView = (GalleryImageView *)[self.pages objectAtIndex:(index) % kNoofViews];
					if (firstView) {
						CGRect frame = firstView.frame;
						frame.origin.x = ((page + additionValue) * (_scrollView.frame.size.width));
						[firstView setTag:index+ARTICLE_CONTENT_VIEW_TAG];
						frame.origin.y = 0.0;
						[firstView setFrame:frame];
                        [firstView setImage: [imageDict objectForKey:[NSString stringWithFormat:@"%d",index]]];
					}
                    
				}
			}
			else {
				
				if (currentPosition+additionValue < [imageDict count] && page - additionValue >= 0) {
					
					int index = page-additionValue;
					GalleryImageView *lastView = (GalleryImageView *)[self.pages objectAtIndex:(index) % kNoofViews];
					if (lastView) {
						CGRect frame = lastView.frame;
						frame.origin.x =((page - additionValue) * (_scrollView.frame.size.width));
						frame.origin.y = 0.0;
						[lastView setTag:index+ARTICLE_CONTENT_VIEW_TAG];
						[lastView setFrame:frame];
                        [lastView setImage: [imageDict objectForKey:[NSString stringWithFormat:@"%d",index]]];
                        
					}
				}
			}
			currentPosition = page;
			pageIndex = currentPosition;
		}
	}
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	CGFloat pageWidth = _scrollView.frame.size.width;
	pageIndex = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    [self.parentView scrollViewDidEndDecelerating];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    NSArray *subViews = [self.scrollView subviews];
	for (id object in subViews) {
		if ([object isKindOfClass:[GalleryImageView class]]) {
			GalleryImageView *contentView = (GalleryImageView *)object;
			CGRect frame = contentView.frame;
			frame.origin.x = (contentView.tag - ARTICLE_CONTENT_VIEW_TAG)*self.scrollView.frame.size.width;
			frame.size = self.scrollView.frame.size;
			contentView.frame = frame;
		}
	}
    
    shouldScroll = YES;
    
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * noOfPages, self.scrollView.frame.size.height)];
    [self.scrollView setContentOffset:CGPointMake(pageIndex*self.scrollView.frame.size.width, 0) animated:NO];
    shouldScroll = NO;
    
}
/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

- (void)dealloc {
    self.scrollView = nil;
    self.parentView = nil;
    self.pages = nil;
}
@end
