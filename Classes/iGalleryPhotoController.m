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
@synthesize toolbar;

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

- (void)showToolbar
{
  toolbar = [[UIToolbar alloc] init];
  
  // Lets get the size of the toolbar as default.
  [toolbar sizeToFit];
  CGFloat toolbarHeight = toolbar.frame.size.height;
  CGRect viewBounds = self.view.bounds;
  
  toolbar.barStyle = UIBarStyleBlackTranslucent;
  [toolbar setFrame:CGRectMake(CGRectGetMinX(viewBounds), CGRectGetMinY(viewBounds) + CGRectGetHeight(viewBounds) - toolbarHeight, CGRectGetWidth(viewBounds), toolbarHeight)];  
  [self.view addSubview:toolbar];
}

- (void)updateToolbar
{
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
}

- (void)hideToolbar
{
  // Get rid of our toolbar now
  [UIView beginAnimations:@"ToolbarHide" context:(void*)toolbar];
  [UIView setAnimationDuration:0.25];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(animationDidStop:context:)];
  toolbar.alpha = 0.0;
  [UIView commitAnimations];  
}

- (IBAction)upload:(id)sender
{
  NSError *error;
  float progressIncrements = 1.0 / 4.0;
  
  [self showToolbar];
  
  // Make a toolbar progress view thingy
  CGRect toolbarBounds = toolbar.bounds;
  ProgressTextBarView *progressTextView = [[ProgressTextBarView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(toolbarBounds) * 0.6, CGRectGetHeight(toolbarBounds) * 0.8)];
  progressTextView.textField.text = @"Initialising...";
  progressTextView.progressView.progress = 0.0;
  
  // Set the toolbar up, <- variable space -> <- progress -> <- variable space ->
  // Makes sure it is centered nicely
  [toolbar setItems:[NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                     [[UIBarButtonItem alloc] initWithCustomView:progressTextView],
                     [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], nil]];
  
  [self updateToolbar];
  
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
  [self.navigationController.navigationBar drawRect:self.navigationController.navigationBar.frame];
  
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
    [self hideToolbar];
    
    return;
  }
  
  progressTextView.textField.text = @"Logging in...";
  progressTextView.progressView.progress += progressIncrements;
  [self updateToolbar];
  
  Gallery *gallery = [[Gallery alloc] initWithGalleryURL:galleryURL];
  NSDictionary *resultDictionary = [gallery sendSynchronousCommand:[NSDictionary dictionaryWithObjectsAndKeys:galleryPassword, @"password", galleryUsername, @"uname", @"login", @"cmd", nil] error:&error];
  NSLog(@"result %@, error %@", resultDictionary, error);
  
  if (error)
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Connection Error" message:[[error localizedDescription] capitalizedString] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
    [alert show];
    
    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStyleDone target:self action:@selector(upload:)] autorelease] animated:YES];
    [self hideToolbar];
    return;
  }
  
  if ([[resultDictionary valueForKey:@"status"] intValue] != 0)
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Gallery Error" message:[resultDictionary valueForKey:@"status_text"] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
    [alert show];

    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStyleDone target:self action:@selector(upload:)] autorelease] animated:YES];
    [self hideToolbar];
    return;
  }
  
  progressTextView.textField.text = @"Rotating...";
  progressTextView.progressView.progress += progressIncrements;
  [self updateToolbar];
  
  UIImage *rotatedImage = [image rotateImage];
  
  progressTextView.textField.text = @"Uploading...";
  progressTextView.progressView.progress += progressIncrements;
  [self updateToolbar];
  
  resultDictionary = [gallery sendSynchronousCommand:[NSDictionary dictionaryWithObjectsAndKeys:rotatedImage, @"g2_userfile", galleryID, @"set_albumName", @"add-item", @"cmd", nil] error:&error];
  
  if (error)
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Connection Error" message:[[error localizedDescription] capitalizedString] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
    [alert show];
    
    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStyleDone target:self action:@selector(upload:)] autorelease] animated:YES];
    [self hideToolbar];
    return;
  }
  
  if ([[resultDictionary valueForKey:@"status"] intValue] != 0)
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Gallery Error" message:[resultDictionary valueForKey:@"status_text"] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
    [alert show];
    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStyleDone target:self action:@selector(upload:)] autorelease] animated:YES];
    [self hideToolbar];
    return;
  }
  
  [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStyleDone target:self action:@selector(upload:)] autorelease] animated:YES];
  [self hideToolbar];
}
  
- (void)animationDidStop:(NSString *)animationID finished:(BOOL)flag context:(void *)context
{
  if ([animationID isEqual:@"ToolbarHide"])
  {
    NSLog(@"%@, %@", animationID, context);
    UIToolbar *contextToolbar = (UIToolbar*)context;
    [contextToolbar removeFromSuperview];
    [contextToolbar release];
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
  [image release];
  [super dealloc];
}


@end
