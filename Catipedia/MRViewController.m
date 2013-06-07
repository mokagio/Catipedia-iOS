//
//  MRViewController.m
//  Catipedia
//
//  Created by Gio on 05/06/2013.
//  Copyright (c) 2013 Memrise. All rights reserved.
//

#import "MRViewController.h"

#import "MRCredentialManager.h"
#import <AFNetworking/AFNetworking.h>
#import <AFAmazonS3Client/AFAmazonS3Client.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <MobileCoreServices/UTCoreTypes.h>

static NSString *kServerBaseURL = @"http://catipedia-server.herokuapp.com/";
static NSString *kCatsListURL = @"";
static NSString *kBucket = @"catipedia.memrise.com";

static const CGFloat kToastMessageInterval = 1.0;

@interface MRViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UIButton *takePictureButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MBProgressHUD *toastMessage;
@property (nonatomic, strong) NSMutableArray *cats;
- (void)addTakePictureButton;
- (void)loadTakePictureController;
- (void)uploadPictureFromPath:(NSString *)picturePath;
- (UIImage *)treatedImage:(UIImage *)originalImage;
- (void)showSuccessToast;
- (void)showFailToast;
- (void)removeToastMessage;

- (void)addTable;
- (void)fetchCats;
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
    self.takePictureButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.takePictureButton.frame = CGRectMake(0, 0, 160, 80);
    CGPoint center = self.view.center;
    center.y = self.view.frame.size.height - self.takePictureButton.frame.size.height / 2 - 140;
    self.takePictureButton.center = center;
    [self.takePictureButton setTitle:@"Take Picture" forState:UIControlStateNormal];
    [self.takePictureButton addTarget:self
                               action:@selector(loadTakePictureController)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.takePictureButton];
}

- (void)addTable
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

- (void)fetchCats
{
    MBProgressHUD *loadingHUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    loadingHUD.labelText = @"looking for cats";
    loadingHUD.mode = MBProgressHUDModeIndeterminate;
    self.takePictureButton.hidden = YES;
    
    NSURL *url = [NSURL URLWithString:kCatsListURL];
    NSURLRequest *versionRequest = [NSURLRequest requestWithURL:url];
    AFJSONRequestOperation *localVersionOperation = \
    [AFJSONRequestOperation JSONRequestOperationWithRequest:versionRequest
                                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                        NSArray *cats = [(NSDictionary *)JSON valueForKey:@"results"];
                                                        
                                                        NSMutableArray *temp = [NSMutableArray array];
                                                        for (NSDictionary *cat in cats) {
                                                            [temp addObject:cat];
                                                        }
                                                        self.cats = temp;
                                                        [self.tableView reloadData];
                                                        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                                        self.takePictureButton.hidden = NO;
                                                        
                                                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                        NSLog(@"JSON failure - %@", error);
                                                        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                                        self.takePictureButton.hidden = NO;
                                                    }];
    [localVersionOperation start];
}

- (void)loadTakePictureController
{
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        cameraUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    cameraUI.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeImage, nil];
    cameraUI.allowsEditing = NO;
    cameraUI.delegate = self;
    
    [self presentViewController:cameraUI animated:YES completion:nil];
}

- (void)uploadPictureFromPath:(NSString *)picturePath
{
    AFAmazonS3Client *httpClient = [[AFAmazonS3Client alloc] initWithAccessKeyID:[MRCredentialManager S3KeyID]
                                                                          secret:[MRCredentialManager S3Secret]];
    httpClient.bucket = kBucket;
    
    NSString *destinationPath = [NSString stringWithFormat:@"/"];
    [httpClient postObjectWithFile:picturePath
                   destinationPath:destinationPath
                        parameters:nil
                          progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
                              NSLog(@"%f%% Uploaded", (totalBytesWritten / (totalBytesExpectedToWrite * 1.0f) * 100));
                          } success:^(id responseObject) {
                              [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                              [self showSuccessToast];
                              NSLog(@"Upload Complete");
                          } failure:^(NSError *error) {
                              [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                              [self showFailToast];
                              NSLog(@"Error: %@", error);
                          }];
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

- (UIImage *)treatedImage:(UIImage *)originalImage
{
    UIImage *resizedImage = [originalImage copy];
    CGFloat scaleFactor = 0.25;
    CGFloat resizedHeight = resizedImage.size.height * scaleFactor;
    CGFloat resizedWidth = resizedImage.size.width * scaleFactor;
    CGSize resizedSize = CGSizeMake(resizedWidth, resizedHeight);
    UIGraphicsBeginImageContextWithOptions(resizedSize, NO, 0.0f);
    [resizedImage drawInRect:CGRectMake(0, 0, resizedSize.width, resizedSize.height)];
    resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

#pragma mark - UIImagePickerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if (CFStringCompare((CFStringRef)mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
        UIImage *imageToSave = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
        
        // Save image to library
        MBProgressHUD *progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        progress.mode = MBProgressHUDModeIndeterminate;
        progress.labelText = @"uploading";
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageToSavedPhotosAlbum:[imageToSave CGImage]
                                  orientation:(ALAssetOrientation)[imageToSave imageOrientation]
                              completionBlock:^(NSURL *assetURL, NSError *error){
                                  if (error) {
                                      [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                      [self showFailToast];
                                      NSLog(@"There was an error saving to camera roll");
                                  } else {
                                      // Save image to temp file beacuse damned iOS doesn't allow us to access the Camera Roll
                                      // (?)
                                      UIImage *resizedImage = [self treatedImage:imageToSave];
                                      
                                      NSData *data = UIImageJPEGRepresentation(resizedImage, 0.25);
                                      NSString *fileName = [NSString stringWithFormat:@"temp-%f.jpg", [[NSDate date] timeIntervalSince1970]];
                                      NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                      NSString *documentsDirectory = [paths objectAtIndex:0];
                                      NSString *path = [documentsDirectory stringByAppendingPathComponent:fileName];
                                      BOOL success = [data writeToFile:path atomically:YES];
                                      if (success) {
                                          [self uploadPictureFromPath:path];
                                      } else {
                                          [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                          [self showFailToast];
                                          NSLog(@"There was an error saving the temp file");
                                      }
                                  }
                              }];
    }
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
    
    cell.textLabel.text = @"Cat Word Here";
    
    return cell;
}

@end