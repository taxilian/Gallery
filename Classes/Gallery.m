/*
 Gallery.,
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

#import "Gallery.h"
#import "NSData+Extras.h"

#import <netdb.h>

//#define LOG_CONNECTIONS   1

#ifdef LOG_CONNECTIONS
# define ConnLog(x...) NSLog(@"ConnLog: %@", [NSString stringWithFormat:x])
#else
# define ConnLog(x, ...)
#endif

@interface NSURLRequest (SomePrivateAPIs)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(id)fp8;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)fp8 forHost:(id)fp12;
@end

@implementation Gallery

@synthesize galleryURL;
@synthesize delegate;
@synthesize username;
@synthesize password;

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
    
    connection = nil;
    messageRef = nil;
    haveAttemptedHTTPAuth = NO;
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
  NSString *gURL = galleryURL;
  if ([gURL rangeOfString:@"?g2_controller=remote:GalleryRemote"].location == NSNotFound)
  {
    gURL = [gURL stringByAppendingString:@"?g2_controller=remote:GalleryRemote"];
  }
  
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
  [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[[request URL] host]];
  
  // Already autoreleased
  return request;
}

- (NSDictionary*)commandDictionaryFromData:(NSData*)data
{
  NSString *connectionReturnString = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
  
  NSArray *cmdTokenArray = [connectionReturnString componentsSeparatedByString:@"\n"];
  NSMutableDictionary *mutableFormData = [NSMutableDictionary dictionary];
  
  int cmdTokenStart = 0;
  BOOL foundCmdTokenStart = NO;
  
  for (cmdTokenStart = 0; cmdTokenStart < [cmdTokenArray count]; cmdTokenStart++)
  {
    if ([[cmdTokenArray objectAtIndex:cmdTokenStart] isEqual:@"#__GR2PROTO__"])
    {
      foundCmdTokenStart = YES;
      break;
    }
  }
  
  if (!foundCmdTokenStart)
  {
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(gallery:didError:)])
    {
      NSError *error = [NSError errorWithDomain:@"GalleryDomain" code:1001 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"No gallery found at address, or invalid response received.", NSLocalizedDescriptionKey, nil]];
      [[self delegate] gallery:self didError:error];
    }
    return nil;
  }
  
  for (NSString *token in cmdTokenArray)
  {
    if (cmdTokenStart > 0)
    {
      cmdTokenStart--;
      continue;
    }
    
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

- (BOOL)beginAsyncRequest:(NSURLRequest*)request withTag:(long)theTag
{
  connectionRequest = [request retain];
  connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
  if (!connection)
  {
    ConnLog(@"Invalid request");
    return NO;
  }
  
  [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
  connectionData = [[NSMutableData alloc] init];
  connectionTag = theTag;
  
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  
  ConnLog(@"Begin request");
  [connection start];
  ConnLog(@"Request dispatched.");
  return YES;
}

@end

@implementation Gallery (GalleryPrivate)

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
  if (self.delegate && [self.delegate respondsToSelector:@selector(gallery:didUploadBytes:bytesRemaining:withTag:)])
  {
    [self.delegate gallery:self didUploadBytes:bytesWritten bytesRemaining:(totalBytesExpectedToWrite-totalBytesWritten) withTag:connectionTag];
  }
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
  if (redirectResponse)
  {
    NSMutableURLRequest *req = [connectionRequest mutableCopy];
    [req setURL:[request URL]];
    self.galleryURL = [request.URL absoluteString];
    
    return [req autorelease];
  }
  
  return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
  if ([challenge proposedCredential])
  {
    // we've tried this once already, bomb out and let it fail
    [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
  }
  else
  {
    // grab the u/p for the gallery and try that
    NSURLCredential *credential = [NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceForSession];
    [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
  }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  [connectionData appendData:data];
}

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSHTTPURLResponse *)response
{
  if ([response statusCode] > 299)
  {
    NSString *desc = [NSString stringWithFormat:@"The webserver returned the following error: \"%d %@\"", [response statusCode], [[NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]] capitalizedString]];
    NSError *httpError = [NSError errorWithDomain:NSOSStatusErrorDomain code:[response statusCode] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:desc, NSLocalizedDescriptionKey, nil]];
    [self connection:aConnection didFailWithError:httpError];
    [aConnection cancel];
  }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
  NSDictionary *commandDict = [self commandDictionaryFromData:connectionData];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  [connectionData release];
  connectionData = nil;
  connection = nil;
  
  if (commandDict && [self delegate] && [[self delegate] respondsToSelector:@selector(gallery:didRecieveCommandDictionary:withTag:)])
  {
    [[self delegate] gallery:self didRecieveCommandDictionary:commandDict withTag:connectionTag];
  }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)err
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  if (err)
  {    
    if ([[err domain] isEqualToString:@"kCFStreamErrorDomainNetDB"])
    {
      switch ([err code])
      {
        case EAI_NONAME:
          err = [NSError errorWithDomain:[err domain] code:[err code] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"No internet connection found. Please try again.", NSLocalizedDescriptionKey, nil]];
          break;
      }
    }
    
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(gallery:didError:)])
    {
      [[self delegate] gallery:self didError:err];
    }
  }
}

@end
