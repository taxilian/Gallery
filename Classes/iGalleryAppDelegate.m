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

@implementation iGalleryAppDelegate

@synthesize window;
@synthesize imagePickerController;
@synthesize backgroundImageView;
@synthesize rootViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
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
  
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  // The nav controller uses private API classes to implement its viewControllers. So we'll recognise them by className string
  // that way I can override the contents each pane's navigation bar.
  if (!self.rootViewController && [viewController.title isEqualToString:@"Photo Albums"])
  {
    self.rootViewController = viewController;
  }
  
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
  else if ([viewController isKindOfClass:[iGalleryPhotoController class]] || [viewController isKindOfClass:[iGallerySettingsController class]])
  {
    // Do nothing
  }
  else
  {
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
  
  iGalleryPhotoController *photoController = [[iGalleryPhotoController alloc] init];
  photoController.image = image;
  backgroundImageView.image = image;
  
  [imagePickerController pushViewController:photoController animated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  // I removed the cancel button, muwhahaha!
}

@end
