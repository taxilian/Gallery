//
//  iGalleryAppDelegate.m
//  iGallery
//
//  Created by Matt Wright on 04/10/2008.
//  Copyright Matt Wright Consulting 2008. All rights reserved.
//

#import "iGalleryAppDelegate.h"
#import "iGalleryPhotoController.h"
#import "iGallerySettingsController.h"
#import "iGalleryAlbumController.h"

@implementation iGalleryAppDelegate

@synthesize window;
@synthesize imagePickerController;
@synthesize backgroundImageView;
@synthesize rootViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
  application.statusBarStyle = UIStatusBarStyleBlackTranslucent;
  window.backgroundColor = [UIColor blackColor];
  
  backgroundImageView = [[UIImageView alloc] initWithFrame:window.bounds];
  [window addSubview:backgroundImageView];
  
  imagePickerController = [[UIImagePickerController alloc] init];
  imagePickerController.delegate = self;
  
  [window addSubview:imagePickerController.view];
	[window makeKeyAndVisible];
}

- (IBAction)camera:(id)sender
{
  imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
}

- (IBAction)settings:(id)sender
{
  iGallerySettingsController *settingsController = [[iGallerySettingsController alloc] init];
  [imagePickerController pushViewController:settingsController animated:YES];
}

- (void)dealloc {
	[window release];
	[super dealloc];
}

#pragma mark Navigation Delegates

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  if ([viewController isKindOfClass:[iGallerySettingsController class]])
  {
    [(iGallerySettingsController*)viewController update];
  }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  // The nav controller uses private API classes to implement its viewControllers. So we'll recognise them by className string
  // that way I can override the contents each pane's navigation bar.
  if (!self.rootViewController && [viewController.title isEqualToString:@"Photo Albums"])
  {
    self.rootViewController = viewController;
  }
  
  navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
  
  if ([viewController isEqual:self.rootViewController])
  {
    viewController.title = @"iGallery";
    
    // Blank placeholder, gets replaced (yeah, wasteful, whatever), with a camera item if we have a camera available.
    viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(settings:)];
    viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
      viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(camera:)];
    }

  }
  else if ([viewController isKindOfClass:[iGalleryPhotoController class]] || 
           [viewController isKindOfClass:[iGallerySettingsController class]] ||
           [viewController isKindOfClass:[iGalleryAlbumController class]])
  {
    // Do nothing
  }
  else
  {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.25];
    backgroundImageView.image = nil;
    [UIView commitAnimations];
    viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  }
}

#pragma mark Image Picker Delegates

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
  if (!CGSizeEqualToSize(image.size, backgroundImageView.bounds.size))
  {
    float heightScale = backgroundImageView.bounds.size.height / image.size.height;
    
    CGRect newImageViewBounds;
    newImageViewBounds.origin = CGPointZero;
    newImageViewBounds.size.width = image.size.width * heightScale;
    newImageViewBounds.size.height = image.size.height * heightScale;
    
    backgroundImageView.bounds = newImageViewBounds;
  }
  
  if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
  {
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.rootViewController = nil;
  }
  
  iGalleryPhotoController *photoController = [[iGalleryPhotoController alloc] init];
  photoController.image = image;
  
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.25];
  backgroundImageView.image = image;
  [UIView commitAnimations];
    
  [imagePickerController pushViewController:photoController animated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  // I removed the cancel button, muwhahaha!
}

@end
