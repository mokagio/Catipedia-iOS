//
//  MRNewCatViewController.m
//  Catipedia
//
//  Created by Gio on 08/06/2013.
//  Copyright (c) 2013 Memrise. All rights reserved.
//

typedef void (^Callback)();

#import "MRNewCatViewController.h"

#import "CatipediaConstants.h"
#import "MRCredentialManager.h"

#import <AFAmazonS3Client/AFAmazonS3Client.h>
#import <AFNetworking/AFNetworking.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <MobileCoreServices/UTCoreTypes.h>

@interface MRNewCatViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

- (void)loadImagePicker;

- (void)saveImagetoLibrary:(UIImage *)image;
- (void)uploadImage:(UIImage *)image;
- (void)uploadPictureFromPath:(NSString *)picturePath;

- (UIImage *)treatedImage:(UIImage *)originalImage;

- (void)dismissWithSuccessState;
- (void)dismissWithFailAndError:(NSError *)error;

@end

@implementation MRNewCatViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadImagePicker];
}

#pragma mark - 

- (void)loadImagePicker
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

- (void)dismissWithSuccessState
{
    [self removeHUDs];
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)dismissWithFailAndError:(NSError *)error
{
    [self removeHUDs];
    NSLog(@"Failed with error: %@", error);
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)removeHUDs
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

#pragma mark -

- (void)saveImagetoLibrary:(UIImage *)image;
{
    MBProgressHUD *progress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    progress.mode = MBProgressHUDModeIndeterminate;
    progress.labelText = @"Saving to camera roll";
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeImageToSavedPhotosAlbum:[image CGImage]
                              orientation:(ALAssetOrientation)[image imageOrientation]
                          completionBlock:^(NSURL *assetURL, NSError *error){
                              if (error) {
                                  [self dismissWithFailAndError:error];
                              } else {
                                  [self removeHUDs];
                                  [self uploadImage:image];
                              }
                          }];

}

- (void)uploadImage:(UIImage *)image
{
    // Save image to temp file beacuse damned iOS doesn't allow us to access the Camera Roll
    // (?)
    UIImage *resizedImage = [self treatedImage:image];
    NSData *data = UIImageJPEGRepresentation(resizedImage, 0.25);
    NSString *fileName = [NSString stringWithFormat:@"temp-%f.jpeg", [[NSDate date] timeIntervalSince1970]];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:fileName];
    BOOL success = [data writeToFile:path atomically:YES];
    if (success) {
        [self uploadPictureFromPath:path];
    } else {
        [self dismissWithFailAndError:nil];
    }
}

- (void)uploadPictureFromPath:(NSString *)picturePath
{
    AFAmazonS3Client *httpClient = [[AFAmazonS3Client alloc] initWithAccessKeyID:[MRCredentialManager S3KeyID]
                                                                          secret:[MRCredentialManager S3Secret]];
    httpClient.bucket = kBucket;
    
    NSString *destinationPath = @"/"; // only one that works so far...
    //    destinationPath = @"https://s3.amazonaws.com/catipedia.memrise.com/public/";
    //    destinationPath = @"public/";
    [httpClient postObjectWithFile:picturePath
                   destinationPath:destinationPath
                        parameters:@{@"Content-Type":@"image/jpeg", @"acl":@"public-read"}
                          progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
                              NSLog(@"%f%% Uploaded", (totalBytesWritten / (totalBytesExpectedToWrite * 1.0f) * 100));
                          } success:^(id responseObject) {
                              
                              NSString *imageLink = [NSString stringWithFormat:@"%@%@", kStorageBaseURL, [picturePath lastPathComponent]];
                              NSDictionary *params = @{kCatWordKey:@"dummy-name", kCatPictureURLKey:imageLink};
                              
                              AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kBaseURL]];
                              NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST"
                                                                                      path:[NSString stringWithFormat:@"%@%@", kBaseURL, kCatsAddEndPoint]
                                                                                parameters:params];
                              AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
                              [httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
                              [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                                  NSLog(@"Upload Complete");
                                  [self dismissWithSuccessState];
                              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                  [self dismissWithFailAndError:error];
                              }];
                              [operation start];
                          } failure:^(NSError *error) {
                              [self dismissWithFailAndError:error]; 
                          }];
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
        [self saveImagetoLibrary:imageToSave];
    }
}


@end
