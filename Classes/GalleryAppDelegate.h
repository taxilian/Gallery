/*
 GalleryAppDelegate.h
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

#pragma mark Subview Drilling Functions

- (UIView*)subViewOf:(UIView*)view atIndex:(int)index ofClass:(Class)aClass;

#pragma mark Debug Functions

- (void)_printUIViewTree:(UIView*)view;
- (void)_printUIViewTree:(UIView*)view withPrefixWhitespace:(NSString*)whitespace;

@end

