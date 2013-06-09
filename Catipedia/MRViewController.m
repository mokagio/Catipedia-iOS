//
//  MRViewController.m
//  Catipedia
//
//  Created by Gio on 05/06/2013.
//  Copyright (c) 2013 Memrise. All rights reserved.
//

#import "MRViewController.h"

#import "CatipediaConstants.h"
#import "MRNewCatViewController.h"

#import <AFNetworking/AFNetworking.h>
#import <FrameAccessor/FrameAccessor.h>
#import <MBProgressHUD/MBProgressHUD.h>

static NSString *kPlaceholderImageName = @"placeholder";
static const CGFloat kToastMessageInterval = 1.0;

@interface MRViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MBProgressHUD *toastMessage;
@property (nonatomic, strong) NSMutableArray *cats;

- (void)addTakePictureButton;
- (void)addTable;

- (void)fetchCats;

- (void)loadTakePictureController;

- (void)showSuccessToast;
- (void)showFailToast;
- (void)removeToastMessage;

@end

@implementation MRViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.cats = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Catipedia";
    self.view.backgroundColor = [UIColor lightGrayColor];
    [self addTable];
    [self addTakePictureButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self fetchCats];
}

- (void)addTakePictureButton
{   
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                             target:self
                                                                             action:@selector(loadTakePictureController)];
    self.navigationItem.rightBarButtonItem = addItem;
}

- (void)addTable
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.origin = CGPointZero;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

- (void)fetchCats
{
    MBProgressHUD *loadingHUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    loadingHUD.labelText = @"looking for cats";
    loadingHUD.mode = MBProgressHUDModeIndeterminate;
    
    NSURL *url = [NSURL URLWithString:kCatsListURL];
    NSURLRequest *versionRequest = [NSURLRequest requestWithURL:url];
    AFJSONRequestOperation *localVersionOperation = \
    [AFJSONRequestOperation JSONRequestOperationWithRequest:versionRequest
                                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                        NSArray *cats = [(NSDictionary *)JSON valueForKey:kCatsJSONKey];
                                                        
                                                        NSMutableArray *temp = [NSMutableArray array];
                                                        for (NSDictionary *cat in cats) {
                                                            [temp addObject:cat];
                                                        }
                                                        self.cats = temp;
                                                        [self.tableView reloadData];
                                                        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                                        
                                                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                        NSLog(@"JSON failure - %@", error);
                                                        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                                    }];
    [localVersionOperation start];
}

- (void)loadTakePictureController
{
    MRNewCatViewController *viewController = [[MRNewCatViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:NO];
}

- (void)showSuccessToast
{
    [self showToastWithMessage:@"Done"];
}

- (void)showFailToast
{
    [self showToastWithMessage:@"Failed"];
}

- (void)showToastWithMessage:(NSString *)message
{
    self.toastMessage = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.toastMessage.mode = MBProgressHUDModeText;
    self.toastMessage.labelText = message;
    
    [self performSelector:@selector(removeToastMessage) withObject:nil afterDelay:kToastMessageInterval];
}

- (void)removeToastMessage
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

#pragma mark - UITableViewControllerDelegate


#pragma mark - UITableViewController DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.cats count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    NSDictionary *cat = [self.cats objectAtIndex:indexPath.row];
    cell.textLabel.text = [cat valueForKey:kCatWordKey];
    
    NSURL *imageURL = [NSURL URLWithString:[cat valueForKey:kCatPictureURLKey]];
    [cell.imageView setImageWithURL:imageURL
                   placeholderImage:[UIImage imageNamed:kPlaceholderImageName]];
    
    return cell;
}

@end