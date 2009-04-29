//
//  Gallery.h
//  iGallery
//
//  Created by Matt Wright on 04/10/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CFNetwork/CFNetwork.h>
#import "AsyncSocket.h"

#define CONNECTION_TIMEOUT  15.0f

@interface Gallery : NSObject {
  AsyncSocket *socket;
  id delegate;
  
  NSData *uploadData;
  
  NSString *galleryURL;
  NSString *authToken;
  
  NSString *username;
  NSString *password;
  
  NSURLRequest *lastRequest;
  CFHTTPMessageRef messageRef;
  
  int uploadChunkSize;
  int connectionTag;
  
  BOOL haveAttemptedHTTPAuth;
}

@property (nonatomic,retain) NSString *galleryURL;
@property (nonatomic,assign) id delegate;

@property (retain) NSString *username;
@property (retain) NSString *password;

- (id)initWithGalleryURL:(NSString*)url;
- (id)initWithGalleryURL:(NSString*)url delegate:(id)delegate;

- (NSURLRequest*)requestForCommandDictionary:(NSDictionary*)dict;
- (NSURLRequest*)requestForCommandDictionary:(NSDictionary*)dict imageName:(NSString*)name;
- (NSDictionary*)commandDictionaryFromData:(NSData*)data;

- (BOOL)beginAsyncRequest:(NSURLRequest*)request;
- (BOOL)beginAsyncRequest:(NSURLRequest*)request withTag:(long)tag;

- (id)sendSynchronousCommand:(NSDictionary*)formData error:(NSError**)error;

@end

@interface NSObject (GalleryDelegates)

- (void)gallery:(Gallery*)gallery didRecieveCommandDictionary:(NSDictionary*)dictionary withTag:(long)tag;
- (void)gallery:(Gallery*)gallery didUploadBytes:(long)count bytesRemaining:(long)remaining withTag:(long)tag;
- (void)gallery:(Gallery*)gallery didError:(NSError*)error;

@end
