/*
 GalleryAppDelegate.m
 Copyright (c) 2009 Matt Wright.
 
 Gallery is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import "GalleryAppDelegate.h"
#import "iGalleryPhotoController.h"
#import "iGallerySettingsController.h"
#import "iGalleryAlbumController.h"

#import "UIDevice+Extras.h"

extern const char * class_getName(Class cls);

#import "Beacon.h"

@class PLLibraryViewController;
@class PLAlbumViewController;

@interface UIWindow (RotationPrivates)

- (void)forceUpdateInterfaceOrientation;

@end

@implementation GalleryAppDelegate

@synthesize window;
@synthesize imagePickerController;
@synthesize backgroundImageView;
@synthesize rootViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
  [Beacon initAndStartBeaconWithApplicationCode:@"7cb67f8268de949c106fdcd678419d7e" useCoreLocation:NO useOnlyWiFi:NO];
  
  application.statusBarStyle = UIStatusBarStyleBlackTranslucent;
  window.backgroundColor = [UIColor blackColor];
  
  backgroundImageView = [[UIImageView alloc] initWithFrame:window.bounds];
  [window addSubview:backgroundImageView];
  
  imagePickerController = [[ImagePicker alloc] init];
  imagePickerController.delegate = self;
  imagePickerController.rotationAllowed = YES;
  
  [window addSubview:imagePickerController.view];
	[window makeKeyAndVisible];
}

- (void)applicationWillTerminate:(UIApplication *)application {
  [[Beacon shared] endBeacon];
}

- (IBAction)camera:(id)sender
{
  imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
}

- (IBAction)settings:(id)sender
{
  iGallerySettingsController *settingsController = [[[iGallerySettingsController alloc] initWithNibName:nil bundle:nil] autorelease];
  UINavigationController *settingsNavController = [[[UINavigationController alloc] initWithRootViewController:settingsController] autorelease];
  [imagePickerController presentModalViewController:settingsNavController animated:YES];
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
  imagePickerController.rotationAllowed = NO;
  if (!strcmp(class_getName([viewController class]), "PLLibraryViewController") ||
      // The class was renamed in 3.0
      !strcmp(class_getName([viewController class]), "PLUILibraryViewController"))
  {
    viewController.title = @"Gallery";
    navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    
    // Blank placeholder, gets replaced (yeah, wasteful, whatever), with a camera item if we have a camera available.
    viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(settings:)];
    viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
      viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(camera:)];
    }
  }
  else if ([viewController isKindOfClass:[iGalleryPhotoController class]])
  {
    navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    imagePickerController.rotationAllowed = YES;
  }
  else if ([viewController isKindOfClass:[iGallerySettingsController class]] ||
           [viewController isKindOfClass:[iGalleryAlbumController class]])
  {
    //[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
    navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
  }
  else
  {
    //[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
    navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.25];
    backgroundImageView.image = nil;
    [UIView commitAnimations];
    viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  }
}

#pragma mark Image Picker Delegates

- (void)autosizeBackgroundImage:(UIImage*)image
{
  CGRect iPhoneBounds = [[UIScreen mainScreen] bounds];
  
  if (([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight) ||
      ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft))
  {
    float w = iPhoneBounds.size.height;
    float h = iPhoneBounds.size.width;
    iPhoneBounds.size.width = w;
    iPhoneBounds.size.height = h;
  }
  
  if (!CGSizeEqualToSize(image.size, iPhoneBounds.size))
  {
    float heightScale = (image.size.height < image.size.width) ? (iPhoneBounds.size.width / image.size.width) : (iPhoneBounds.size.height / image.size.height);
    
    CGRect newImageViewBounds;
    newImageViewBounds.origin = CGPointZero;
    newImageViewBounds.size.width = image.size.width * heightScale;
    newImageViewBounds.size.height = image.size.height * heightScale;
    
    backgroundImageView.bounds = newImageViewBounds;
  }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
  [self autosizeBackgroundImage:image];
  
  iGalleryPhotoController *photoController = [[[iGalleryPhotoController alloc] initWithNibName:nil bundle:nil] autorelease];
  photoController.image = image;
  
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.25];
  backgroundImageView.image = image;
  [UIView commitAnimations];
  
  [imagePickerController pushViewController:photoController animated:YES];
  
  if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
  {
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.rootViewController = nil;
    
    // Save the image out to the device
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
  }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
  {
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.rootViewController = nil;
  }
}

- (void)application:(UIApplication *)application didChangeStatusBarOrientation:(UIInterfaceOrientation)oldStatusBarOrientation
{
  switch ([application statusBarOrientation])
  {
    case UIInterfaceOrientationLandscapeLeft:
      backgroundImageView.transform = CGAffineTransformMakeRotation(-3.1412/2);
      break;
    case UIInterfaceOrientationLandscapeRight:
      backgroundImageView.transform = CGAffineTransformMakeRotation(3.1412/2);
      break;
    case UIInterfaceOrientationPortrait:
      backgroundImageView.transform = CGAffineTransformIdentity;
      break;
  }
  [self autosizeBackgroundImage:backgroundImageView.image];
}

@end
