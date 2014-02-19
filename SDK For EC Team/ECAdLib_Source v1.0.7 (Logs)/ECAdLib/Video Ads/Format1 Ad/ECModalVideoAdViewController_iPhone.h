//
//  ECModalVideoAdViewController_iPhone.h
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/7/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ECModalVideoAdViewController_iPhone : UIViewController<UIActionSheetDelegate>
@property (nonatomic, assign) id delegate;
@property (nonatomic, strong) NSMutableDictionary *responseDict;
@property (nonatomic, strong) NSString *basePath;
@end
