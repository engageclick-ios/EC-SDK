//
//  PopOverMenuViewController.m
//  VideoAdSample
//
//  Created by Karthik Kumaravel on 5/7/13.
//  Copyright (c) 2013 Karthik Kumaravel. All rights reserved.
//

#import "PopOverMenuViewController.h"

@interface PopOverMenuViewController ()

@property (nonatomic, strong) UITableView *menuTable;

@end

@implementation PopOverMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.menuTable = [[UITableView alloc] initWithFrame:CGRectMake(0, -20, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:self.menuTable];
    self.menuTable.delegate = self;
    self.menuTable.dataSource = self;
    self.menuTable.backgroundColor = [UIColor blackColor];
    [self.menuTable setSeparatorColor:[UIColor blackColor]];
	// Do any additional setup after loading the view.
}


#pragma mark -
#pragma mark TableView Data Source

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor blackColor]];
    return view;
}
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [self.contentArray count];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

#pragma mark - TableView Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Identifier"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Identifier"];
        [cell setBackgroundColor:tableView.backgroundColor];
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell.textLabel setText:[self.contentArray objectAtIndex:indexPath.row]];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedItem = indexPath.row;
    if ([self.delegate respondsToSelector:@selector(popoverDidSelectOption:)])
        [self.delegate performSelector:@selector(popoverDidSelectOption:) withObject:self];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
