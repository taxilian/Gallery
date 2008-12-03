//
//  Gallery.h
//  iGallery
//
//  Created by Matt Wright on 04/10/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncSocket.h"

@interface Gallery : NSObject {
  AsyncSocket *socket;
  id delegate;
  
  NSString *galleryURL;
  NSString *authToken;
  
  CFHTTPMessageRef messageRef;
}

@property (nonatomic,retain) NSString *galleryURL;
@property (nonatomic,assign) id delegate;

- (id)initWithGalleryURL:(NSString*)url;
- (id)initWithGalleryURL:(NSString*)url delegate:(id)delegate;

- (NSURLRequest*)requestForCommandDictionary:(NSDictionary*)dict;
- (NSDictionary*)commandDictionaryFromData:(NSData*)data;

- (BOOL)beginAsyncRequest:(NSURLRequest*)request;
- (BOOL)beginAsyncRequest:(NSURLRequest*)request withTag:(long)tag;

- (id)sendSynchronousCommand:(NSDictionary*)formData error:(NSError**)error;

@end

@interface NSObject (GalleryDelegates)

- (void)didRecieveCommandDictionary:(NSDictionary*)dictionary withTag:(long)tag;

@end
