//
//  SideSwipeTableViewCell.h
//  SideSwipeTableView
//
//  Created by Peter Boctor on 4/13/11.
//  Copyright 2011 Peter Boctor. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SideSwipeTableViewCell : UITableViewCell
{
  BOOL supressDeleteButton;
}

@property (nonatomic) BOOL supressDeleteButton;

@end
