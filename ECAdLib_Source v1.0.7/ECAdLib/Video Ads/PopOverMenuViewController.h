//
//  PopOverMenuViewController.h
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/7/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PopOverMenuViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray *contentArray;
@property (nonatomic, assign) id delegate;
@property int selectedItem;

@end
