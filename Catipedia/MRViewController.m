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
static NSString *kBucket = @"catipedia.memrise.com";

static const CGFloat kToastMessageInterval = 1.0;

@interface MRViewController ()
@property (nonatomic, strong) UIButton *takePictureButton;
@property (nonatomic, strong) MBProgressHUD *toastMessage;
- (void)addTakePictureButton;
- (void)loadTakePictureController;
- (void)uploadPictureFromPath:(NSString *)picturePath;
- (void)removeToastMessage;
@end

@interface MRViewController (CameraDelegate) <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@end

@implementation MRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Catipedia";
    self.view.backgroundColor = [UIColor lightGrayColor];
    [self addTakePictureButton];
}

- (void)addTakePictureButton
{
    self.takePictureButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.takePictureButton.frame = CGRectMake(0, 0, 160, 80);
    self.takePictureButton.center = self.view.center;
    [self.takePictureButton setTitle:@"Take Picture" forState:UIControlStateNormal];
    [self.takePictureButton addTarget:self
                               action:@selector(loadTakePictureController)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.takePictureButton];
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
    
    NSString *destinationPath = [NSString stringWithFormat:@"test/"];
    [httpClient postObjectWithFile:picturePath
                   destinationPath:destinationPath
                        parameters:nil
                          progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
                              NSLog(@"%f%% Uploaded", (totalBytesWritten / (totalBytesExpectedToWrite * 1.0f) * 100));
                          } success:^(id responseObject) {
                              [self dismissViewControllerAnimated:YES completion:^{
                                  NSLog(@"Upload Complete");
                              }];
                          } failure:^(NSError *error) {
                              [self dismissViewControllerAnimated:YES completion:^{
                                  NSLog(@"Error: %@", error);
                              }];
                          }];
}

- (void)showFeedbackToast
{
    self.toastMessage = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.toastMessage.mode = MBProgressHUDModeText;
    self.toastMessage.labelText = @"Picture Saved";
    self.toastMessage.yOffset = 100;
    
    [self performSelector:@selector(removeToastMessage) withObject:nil afterDelay:kToastMessageInterval];
}

- (void)removeToastMessage
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

@end

@implementation MRViewController (CameraDelegate)

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if (CFStringCompare((CFStringRef)mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
        UIImage *imageToSave = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
        
        // Save image to library
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageToSavedPhotosAlbum:[imageToSave CGImage]
                                  orientation:(ALAssetOrientation)[imageToSave imageOrientation]
                              completionBlock:^(NSURL *assetURL, NSError *error){
                                  if (error) {
                                      NSLog(@"error");
                                      [picker dismissViewControllerAnimated:YES completion:nil];
                                  } else {
                                      // Save image to temp file beacuse damned iOS doesn't allow us to access the Camera Roll
                                      // (?)
                                      UIImage *resizedImage = [imageToSave copy];
                                      CGFloat scaleFactor = 0.25;
                                      CGFloat resizedHeight = resizedImage.size.height * scaleFactor;
                                      CGFloat resizedWidth = resizedImage.size.width * scaleFactor;
                                      CGSize resizedSize = CGSizeMake(resizedWidth, resizedHeight);
                                      UIGraphicsBeginImageContextWithOptions(resizedSize, NO, 0.0f);
                                      [resizedImage drawInRect:CGRectMake(0, 0, resizedSize.width, resizedSize.height)];
                                      resizedImage = UIGraphicsGetImageFromCurrentImageContext();
                                      UIGraphicsEndImageContext();
                                      
                                      NSData *data = UIImageJPEGRepresentation(resizedImage, 0.5);
                                      NSString *fileName = [NSString stringWithFormat:@"temp-%f.jpg", [[NSDate date] timeIntervalSince1970]];
                                      NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                      NSString *documentsDirectory = [paths objectAtIndex:0];
                                      NSString *path = [documentsDirectory stringByAppendingPathComponent:fileName];
                                      BOOL success = [data writeToFile:path atomically:YES];
                                      if (success) {
                                          [self uploadPictureFromPath:path];
                                      } else {
                                          [picker dismissViewControllerAnimated:YES completion:^{
                                              NSLog(@"There was an error");
                                          }];
                                      }
                                  }
                              }];
    }
}

@end