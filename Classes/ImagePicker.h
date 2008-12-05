//
//  ImagePicker.h
//  Gallery
//
//  Created by Matt Wright on 04/12/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ImagePicker : UIImagePickerController {
  BOOL rotationAllowed;
}

@property (nonatomic,assign,getter=isRotationAllowed) BOOL rotationAllowed;

@end
