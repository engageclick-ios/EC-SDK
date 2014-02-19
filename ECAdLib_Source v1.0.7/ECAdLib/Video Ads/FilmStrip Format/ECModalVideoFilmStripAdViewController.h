//
//  ECModalVideoFilmStripAdViewController.h
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/16/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ECModalVideoFilmStripAdViewController : UIViewController <UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, assign) id delegate;
@property (nonatomic, strong) NSMutableDictionary *imageDict;
@property (nonatomic, strong) NSMutableDictionary *responseDict;
@property (nonatomic, strong) NSString *basePath;
@property (nonatomic, strong) NSMutableDictionary *socialImages;
@property (nonatomic, strong) NSMutableDictionary *socialFBImages;

@property (nonatomic, strong) NSMutableDictionary *fbContentDict;
@property (nonatomic, strong) NSMutableDictionary *twitterContentDict;

- (NSMutableDictionary *)getImageDict;


- (void)pullDownViewMoved:(CGPoint)offset;
- (void)pullDownViewEnded:(CGPoint)offset;
- (void)pulDownViewCanceled:(CGPoint)offset;

@end
