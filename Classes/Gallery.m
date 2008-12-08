//
//  Gallery.m
//  iGallery
//
//  Created by Matt Wright on 04/10/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import "Gallery.h"

@interface Gallery (GalleryPrivate)

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag;

@end

@implementation Gallery

@synthesize galleryURL;
@synthesize delegate;

- (id)initWithGalleryURL:(NSString*)url
{
  return [self initWithGalleryURL:url delegate:nil];
}

- (id)initWithGalleryURL:(NSString*)url delegate:(id)aDelegate
{
  if (self = [self init])
  {
    self.galleryURL = url;
    self.delegate = aDelegate;
    
    messageRef = nil;
  }
  return self;
}

- (NSURLRequest*)requestForCommandDictionary:(NSDictionary*)dict
{
  return [self requestForCommandDictionary:dict imageName:nil];
}

- (NSURLRequest*)requestForCommandDictionary:(NSDictionary*)dict imageName:(NSString*)name
{
  NSMutableDictionary *mutableFormData = [NSMutableDictionary dictionaryWithDictionary:dict];
  NSString *mimeBoundary = @"-----iGalleryMIMEBoundary123412341234121";
  NSString *gURL = [NSString stringWithFormat:@"%@?g2_controller=remote:GalleryRemote", galleryURL];
  
  NSMutableData *cmdTokenData = [NSMutableData data];
  
  if (authToken)
  {
    NSString *cmdTokenPayload = [NSString stringWithFormat:@"--%@\r\n", mimeBoundary];
    cmdTokenPayload = [cmdTokenPayload stringByAppendingFormat:@"Content-Disposition: form-data; name=\"g2_authToken\"\r\n\r\n"];
    cmdTokenPayload = [cmdTokenPayload stringByAppendingFormat:@"%@\r\n", authToken];
    [cmdTokenData appendData:[cmdTokenPayload dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
  }
  
  for (NSString *key in [mutableFormData allKeys])
  {   
    id payloadContent = [mutableFormData objectForKey:key];
    if ([payloadContent isKindOfClass:[NSString class]])
    {
      NSMutableString *payloadFragment = [NSMutableString stringWithFormat:@"--%@\r\n", mimeBoundary];
      [payloadFragment appendFormat:@"Content-Disposition: form-data; name=\"g2_form[%@]\"\r\n\r\n", key];
      [payloadFragment appendFormat:@"%@\r\n", payloadContent];
      [cmdTokenData appendData:[payloadFragment dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    }
    else if ([payloadContent isKindOfClass:[UIImage class]])
    {
      NSMutableData *dataFragment = [NSMutableData data];
      NSMutableString *payloadFragment = [NSMutableString stringWithFormat:@"--%@\r\n", mimeBoundary];
      
      NSString *fileName = name;
      if (!fileName)
      {
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"ddmmyy-HHmm"];
        fileName = [NSString stringWithFormat:@"iPhone-%@.jpg", [[dateFormatter stringFromDate:[NSDate date]] stringByReplacingOccurrencesOfString:@" " withString:@""]];
      }
      
      [payloadFragment appendFormat:@"Content-Disposition: form-data; name=\"g2_form[force_filename]\"\r\n\r\n", key];
      [payloadFragment appendFormat:@"%@\r\n", fileName];
      
      [payloadFragment appendFormat:@"--%@\r\n", mimeBoundary];
      [payloadFragment appendFormat:@"Content-Disposition: form-data; name=\"g2_form[caption]\"\r\n\r\n", key];
      [payloadFragment appendFormat:@"%@\r\n", fileName];
      
      [payloadFragment appendFormat:@"--%@\r\n", mimeBoundary];
      [payloadFragment appendFormat:@"Content-Type: image/jpeg\r\n"];
      [payloadFragment appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n\r\n", key, fileName];
      [dataFragment appendData:[payloadFragment dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
      
      NSData *imageData = UIImageJPEGRepresentation(payloadContent, 0.6);
      [dataFragment appendData:imageData];
      [dataFragment appendData:[@"\r\n" dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
      
      [cmdTokenData appendData:dataFragment];
    }
  }
  [cmdTokenData appendData:[[NSString stringWithFormat:@"--%@\r\n", mimeBoundary] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:gURL]];
  if (!request)
  {
    return nil;
  }
  
  [request setValue:[NSString stringWithFormat:@"%d", [cmdTokenData length]] forHTTPHeaderField:@"Content-Length"];
  [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", mimeBoundary] forHTTPHeaderField:@"Content-Type"];
  [request setHTTPMethod:@"POST"];
  [request setHTTPBody:cmdTokenData];
  
  // Already autoreleased
  return request;
}

- (NSDictionary*)commandDictionaryFromData:(NSData*)data
{
  NSString *connectionReturnString = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
  
  NSArray *cmdTokenArray = [connectionReturnString componentsSeparatedByString:@"\n"];
  NSMutableDictionary *mutableFormData = [NSMutableDictionary dictionary];
  
  if (![[cmdTokenArray objectAtIndex:0] isEqualToString:@"#__GR2PROTO__"])
  {
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(gallery:didError:)])
    {
      NSError *error = [NSError errorWithDomain:@"GalleryError" code:1001 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"No gallery found at address.", NSLocalizedDescriptionKey, nil]];
      [[self delegate] gallery:self didError:error];
    }
    return nil;
  }
  
  for (NSString *token in cmdTokenArray)
  {
    NSArray *split = [token componentsSeparatedByString:@"="];
    if (split.count > 1)
    {
      NSString *value = [split objectAtIndex:1];
      // Fine this is wrong...so sue me
      value = [value stringByReplacingOccurrencesOfString:@"\\" withString:@""];
      
      [mutableFormData setObject:value forKey:[split objectAtIndex:0]];
    }
  }
  
  // Bit hacky but we need to remember the last auth_token we got.
  if ([mutableFormData objectForKey:@"auth_token"])
  {
    [authToken release];
    authToken = [[mutableFormData objectForKey:@"auth_token"] retain];
  }
 
  return mutableFormData;
}

- (BOOL)beginAsyncRequest:(NSURLRequest*)request
{
  return [self beginAsyncRequest:request withTag:0];
}

- (BOOL)beginAsyncRequest:(NSURLRequest*)request withTag:(long)tag
{
  NSError *error;
  socket = [[AsyncSocket alloc] initWithDelegate:self];
  NSURL *url = [request URL];
  int port = [[url port] intValue] != 0 ? [[url port] intValue] : 80;
  
  if (![url host] || ![url scheme] || (port == 0))
  {
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(gallery:didError:)])
    {
      [[self delegate] gallery:self didError:[NSError errorWithDomain:@"GalleryDomain" code:1002 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Invalid URL in request.", NSLocalizedDescriptionKey, nil]]];
    }
    return NO;
  }
  
  if ([socket connectToHost:[url host] onPort:port error:&error])
  {
    // Async socket works with NSData but we can't serialise the data out of the NSURLRequest because its not in the API
    // so we're gonna have to copy the contents out, header by header into a CFHTTPMessageRef and then convert that to data.
    messageRef = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (CFStringRef)@"POST", (CFURLRef)url, kCFHTTPVersion1_1);
    CFHTTPMessageSetHeaderFieldValue(messageRef, (CFStringRef)@"Host", (CFStringRef)[url host]);
    CFHTTPMessageSetHeaderFieldValue(messageRef, (CFStringRef)@"User-Agent", (CFStringRef)@"Gallery 1.0/iPhone");
    
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:url];
    NSDictionary *requestHeaders = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    for (NSString *key in [requestHeaders allKeys])
    {
      CFHTTPMessageSetHeaderFieldValue(messageRef, (CFStringRef)key, (CFStringRef)[requestHeaders valueForKey:key]);
    }
    
    for (NSString *key in [[request allHTTPHeaderFields] allKeys])
    {
      CFHTTPMessageSetHeaderFieldValue(messageRef, (CFStringRef)key, (CFStringRef)[[request allHTTPHeaderFields] valueForKey:key]);
    }
    CFHTTPMessageSetBody(messageRef, (CFDataRef)[request HTTPBody]);
    NSData *data = [(NSData*)CFHTTPMessageCopySerializedMessage(messageRef) autorelease];
    
    CFRelease(messageRef);
    messageRef = nil;
    
    uploadChunkSize = [data length] * 0.1;
    NSData *firstChunk = [data subdataWithRange:NSMakeRange(0, uploadChunkSize)];
    uploadData = [[data subdataWithRange:NSMakeRange(uploadChunkSize, [data length] - uploadChunkSize)] retain];
    
    [socket setUserData:uploadChunkSize];
    [socket writeData:firstChunk withTimeout:-1 tag:tag];
    
    // Keep this incase we need to retransmit
    [lastRequest release];
    lastRequest = [request retain];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    return YES;
  }
  NSLog(@"Failed to connect.");
  return NO;
}

- (id)sendSynchronousCommand:(NSDictionary*)formData error:(NSError**)error
{
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  NSURLRequest *request = [self requestForCommandDictionary:formData];
  NSData *connectionData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:error];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  
  return [self commandDictionaryFromData:connectionData];
}

@end

@implementation Gallery (GalleryPrivate)

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
  // Tell our delegate that we've uploaded some data
  if ([self delegate] && [[self delegate] respondsToSelector:@selector(gallery:didUploadBytes:bytesRemaining:withTag:)])
  {
    [[self delegate] gallery:self didUploadBytes:[sock userData] bytesRemaining:[uploadData length] withTag:tag];
  }

  if ([uploadData length] > 0)
  {
    // We've not completed the current upload yet, lets carry on
    int chunkSize = MIN(uploadChunkSize, [uploadData length]);
    NSData *nextChunk = [uploadData subdataWithRange:NSMakeRange(0, chunkSize)];
    uploadData = [[[uploadData autorelease] subdataWithRange:NSMakeRange(chunkSize, [uploadData length] - chunkSize)] retain];
    
    [sock setUserData:chunkSize];
    [sock writeData:nextChunk withTimeout:-1 tag:tag];
  }
  else
  {
    // We've sent something, probably need to read the response now
    [uploadData release];
    uploadData = nil;
    
    [sock readDataWithTimeout:-1 tag:tag];
  }
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
  if (messageRef == nil)
  {
    // I think we should have a nil whenever we're ready to start reading data...I hope.
    messageRef = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, NO);
  }
  CFHTTPMessageAppendBytes(messageRef, [data bytes], [data length]);
  
  if (CFHTTPMessageIsHeaderComplete(messageRef))
  {
    unsigned int status = CFHTTPMessageGetResponseStatusCode(messageRef);

    // We need the session ID from gallery, so I need the headers to pass to NSHTTPCookieStorage
    NSDictionary *headers = (NSDictionary*)CFHTTPMessageCopyAllHeaderFields(messageRef);
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?g2_controller=remote:GalleryRemote", galleryURL]];
    
    NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:headers forURL:url];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:url mainDocumentURL:nil];
        
    if (status == 200)
    {
      NSData *bodyData = (NSData*)CFHTTPMessageCopyBody(messageRef);
      
      // We got a 200, we don't need the request again
      [lastRequest release];
      lastRequest = nil;
      
      // Get the body of the message, if we've less than Content-Length then we need to 
      // to wait for at least another read.
      if ([bodyData length] < [[headers valueForKey:@"Content-Length"] intValue])
      {
        [sock readDataWithTimeout:-1 tag:tag];
      }
      else
      {
        CFRelease(messageRef);
        messageRef = nil;
        
        if ([self delegate] && [[self delegate] respondsToSelector:@selector(gallery:didRecieveCommandDictionary:withTag:)])
        {
          [[self delegate] gallery:self didRecieveCommandDictionary:[self commandDictionaryFromData:bodyData] withTag:tag];
        }
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
      }
      CFRelease(bodyData);
    }
    else if (status == 302)
    {
      // Got a redirect, alter the headers and retransmit
      NSURL *url = [NSURL URLWithString:[headers valueForKey:@"Location"]];
      NSMutableURLRequest *request = [lastRequest mutableCopy];
      
      [request setURL:url];
      [self beginAsyncRequest:request withTag:tag];
    }
    else
    {
      NSLog(@"%@", headers);
    }
    CFRelease(headers);
  }
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  if ([self delegate] && [[self delegate] respondsToSelector:@selector(gallery:didError:)])
  {
    [[self delegate] gallery:self didError:err];
  }
}

@end
