//
//  iGalleryPhotoController.m
//  iGallery
//
//  Created by Matt Wright on 04/10/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import "iGalleryPhotoController.h"
#import "Gallery.h"
#import "ProgressTextBarView.h"
#import "UIImage+Extras.h"

@implementation iGalleryPhotoController

@synthesize image;

/*
// Override initWithNibName:bundle: to load the view using a nib file then perform additional customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

// Implement loadView to create a view hierarchy programmatically.
- (void)loadView {
  [super loadView];
  self.title = @"iGallery";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStyleDone target:self action:@selector(upload:)];
}

- (IBAction)upload:(id)sender
{
  NSError *error;
  UIToolbar *uploadStatusToolbar = [[UIToolbar alloc] init];
  float progressIncrements = 1.0 / 5.0;

  // Lets get the size of the toolbar as default.
  [uploadStatusToolbar sizeToFit];
  CGFloat toolbarHeight = uploadStatusToolbar.frame.size.height;
  CGRect viewBounds = self.view.bounds;
  
  uploadStatusToolbar.barStyle = UIBarStyleBlackTranslucent;
  [uploadStatusToolbar setFrame:CGRectMake(CGRectGetMinX(viewBounds), CGRectGetMinY(viewBounds) + CGRectGetHeight(viewBounds) - toolbarHeight, CGRectGetWidth(viewBounds), toolbarHeight)];
  
  // Make a toolbar progress view thingy
  CGRect toolbarBounds = uploadStatusToolbar.bounds;
  ProgressTextBarView *progressTextView = [[ProgressTextBarView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(toolbarBounds) * 0.6, CGRectGetHeight(toolbarBounds) * 0.8)];
  progressTextView.textField.text = @"Initialising...";
  progressTextView.progressView.progress = progressIncrements;
  
  // Set the toolbar up, <- variable space -> <- progress -> <- variable space ->
  // Makes sure it is centered nicely
  [uploadStatusToolbar setItems:[NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                 [[UIBarButtonItem alloc] initWithCustomView:progressTextView],
                                 [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], nil]];
  
  [self.view addSubview:uploadStatusToolbar];
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  
  // Replace the "upload" button with a spinning indicator
  UIActivityIndicatorView *loadingIndicator = [[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)] autorelease];
  [loadingIndicator startAnimating];
  [loadingIndicator sizeToFit];
  loadingIndicator.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                       UIViewAutoresizingFlexibleRightMargin |
                                       UIViewAutoresizingFlexibleTopMargin |
                                       UIViewAutoresizingFlexibleBottomMargin);
  
  UIBarButtonItem *loadingBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingIndicator];
  loadingBarButtonItem.style = UIBarButtonItemStyleBordered;
  
  // Lots of stuff probably needs a display by now anyway.
  [self.navigationItem setRightBarButtonItem:loadingBarButtonItem animated:YES];
  [self.navigationController.navigationBar setNeedsDisplay];
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *galleryURL = [defaults valueForKey:@"gallery_url"];
  NSString *galleryUsername = [defaults valueForKey:@"username"];
  NSString *galleryPassword = [defaults valueForKey:@"password"];
  NSString *galleryID = [defaults valueForKey:@"albumID"];
  
  if ((!galleryURL || !galleryUsername || !galleryPassword) ||
      ([galleryURL isEqual:@""] || [galleryUsername isEqual:@""] || [galleryPassword isEqual:@""]))
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Credentials Error" message:@"You have not setup your gallery details." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Settings", nil] autorelease];
    [alert show];
    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStyleDone target:self action:@selector(upload:)] autorelease] animated:YES];
    return;
  }
  
  progressTextView.textField.text = @"Logging in...";
  progressTextView.progressView.progress += progressIncrements;
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  
  Gallery *gallery = [[Gallery alloc] initWithGalleryURL:galleryURL];
  NSDictionary *resultDictionary = [gallery sendSynchronousCommand:[NSDictionary dictionaryWithObjectsAndKeys:galleryPassword, @"password", galleryUsername, @"uname", @"login", @"cmd", nil] error:&error];
  NSLog(@"result %@, error %@", resultDictionary, error);
  
  if (error)
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Connection Error" message:[[error localizedDescription] capitalizedString] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
    [alert show];
    
    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStyleDone target:self action:@selector(upload:)] autorelease] animated:YES];
    
    // Get rid of our toolbar now
    [UIView beginAnimations:@"ToolbarHide" context:(void*)uploadStatusToolbar];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:context:)];
    uploadStatusToolbar.alpha = 0.0;
    [UIView commitAnimations];
    
    return;
  }
  
  if ([[resultDictionary valueForKey:@"status"] intValue] != 0)
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Gallery Error" message:[resultDictionary valueForKey:@"status_text"] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
    [alert show];

    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStyleDone target:self action:@selector(upload:)] autorelease] animated:YES];
    
    // Get rid of our toolbar now
    [UIView beginAnimations:@"ToolbarHide" context:(void*)uploadStatusToolbar];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:context:)];
    uploadStatusToolbar.alpha = 0.0;
    [UIView commitAnimations];
    
    return;
  }
  
  progressTextView.textField.text = @"Rotating...";
  progressTextView.progressView.progress += progressIncrements;
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  
  UIImage *rotatedImage = [image rotateImage];
  
  progressTextView.textField.text = @"Uploading...";
  progressTextView.progressView.progress += progressIncrements;
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  
  resultDictionary = [gallery sendSynchronousCommand:[NSDictionary dictionaryWithObjectsAndKeys:rotatedImage, @"g2_userfile", galleryID, @"set_albumName", @"add-item", @"cmd", nil] error:&error];
  
  if (error)
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Connection Error" message:[[error localizedDescription] capitalizedString] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
    [alert show];
    
    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStyleDone target:self action:@selector(upload:)] autorelease] animated:YES];
    
    // Get rid of our toolbar now
    [UIView beginAnimations:@"ToolbarHide" context:(void*)uploadStatusToolbar];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:context:)];
    uploadStatusToolbar.alpha = 0.0;
    [UIView commitAnimations];
    
    return;
  }
  
  if ([[resultDictionary valueForKey:@"status"] intValue] != 0)
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Gallery Error" message:[resultDictionary valueForKey:@"status_text"] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
    [alert show];
    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStyleDone target:self action:@selector(upload:)] autorelease] animated:YES];
    return;
  }
  
  [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStyleDone target:self action:@selector(upload:)] autorelease] animated:YES];

  // Get rid of our toolbar now
  [UIView beginAnimations:@"ToolbarHide" context:(void*)uploadStatusToolbar];
  [UIView setAnimationDuration:0.25];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(animationDidStop:context:)];
  uploadStatusToolbar.alpha = 0.0;
  [UIView commitAnimations];
}
  
- (void)animationDidStop:(NSString *)animationID finished:(BOOL)flag context:(void *)context
{
  if ([animationID isEqual:@"ToolbarHide"])
  {
    NSLog(@"%@, %@", animationID, context);
    UIToolbar *toolbar = (UIToolbar*)context;
    [toolbar removeFromSuperview];
  }
}

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
    [super viewDidLoad];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [super dealloc];
}


@end
