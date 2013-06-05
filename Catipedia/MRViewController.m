//
//  MRViewController.m
//  Catipedia
//
//  Created by Gio on 05/06/2013.
//  Copyright (c) 2013 Memrise. All rights reserved.
//

#import "MRViewController.h"

#import <MobileCoreServices/UTCoreTypes.h>

@interface MRViewController ()
@property (nonatomic, strong) UIButton *takePictureButton;
- (void)addTakePictureButton;
- (void)loadTakePictureController;
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

@end

@implementation MRViewController (CameraDelegate)

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    UIImage *imageToSave;
    
    if (CFStringCompare((CFStringRef)mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
        imageToSave = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
        // TODO save in custom album
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil , nil);
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end