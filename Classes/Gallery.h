/*
 Gallery.h
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
#import <CFNetwork/CFNetwork.h>
#import "AsyncSocket.h"

#define CONNECTION_TIMEOUT  30.0f

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
