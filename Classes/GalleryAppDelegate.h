//
//  iGalleryAppDelegate.h
//  iGallery
//
//  Created by Matt Wright on 04/10/2008.
//  Copyright Matt Wright Consulting 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Gallery.h"
#import "ImagePicker.h"

@interface GalleryAppDelegate : NSObject <UIApplicationDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
	IBOutlet UIWindow *window;
  
  UIImageView *backgroundImageView;
  ImagePicker *imagePickerController;
  
  UIViewController *rootViewController;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) ImagePicker *imagePickerController;
@property (nonatomic, retain) UIImageView *backgroundImageView;
@property (nonatomic, retain) UIViewController *rootViewController;

- (IBAction)camera:(id)sender;

#pragma mark Debug Functions

- (void)_printUIViewTree:(UIView*)view;
- (void)_printUIViewTree:(UIView*)view withPrefixWhitespace:(NSString*)whitespace;

@end

