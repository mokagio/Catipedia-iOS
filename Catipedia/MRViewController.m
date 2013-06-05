//
//  MRViewController.m
//  Catipedia
//
//  Created by Gio on 05/06/2013.
//  Copyright (c) 2013 Memrise. All rights reserved.
//

#import "MRViewController.h"

#import "MRTakePictureControllerViewController.h"

@interface MRViewController ()
@property (nonatomic, strong) UIButton *takePictureButton;
- (void)addTakePictureButton;
- (void)loadTakePictureController;
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
    MRTakePictureControllerViewController *viewController = [[MRTakePictureControllerViewController alloc] init];
    [self presentViewController:viewController animated:YES completion:nil];
}

@end
