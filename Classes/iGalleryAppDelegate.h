//
//  iGalleryAppDelegate.h
//  iGallery
//
//  Created by Matt Wright on 04/10/2008.
//  Copyright Matt Wright Consulting 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Gallery.h"

@interface iGalleryAppDelegate : NSObject <UIApplicationDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
	IBOutlet UIWindow *window;
  
  UIImageView *backgroundImageView;
  UIImagePickerController *imagePickerController;
  
  UIViewController *rootViewController;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UIImagePickerController *imagePickerController;
@property (nonatomic, retain) UIImageView *backgroundImageView;
@property (nonatomic, retain) UIViewController *rootViewController;

- (IBAction)camera:(id)sender;

@end

