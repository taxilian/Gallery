//
//  Gallery.h
//  iGallery
//
//  Created by Matt Wright on 04/10/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface Gallery : NSObject {
  NSString *galleryURL;
  NSString *authToken;
}

@property (nonatomic,retain) NSString *galleryURL;

- (id)initWithGalleryURL:(NSString*)url;

- (id)sendSynchronousCommand:(NSDictionary*)formData;

@end
