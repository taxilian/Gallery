//
//  iGalleryPhotoController.m
//  iGallery
//
//  Created by Matt Wright on 04/10/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import "iGalleryPhotoController.h"
#import "Gallery.h"

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
  self.title = @"iGallery";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStyleDone target:self action:@selector(upload:)];
}

- (IBAction)upload:(id)sender
{
  // TEST
  Gallery *gallery = [[Gallery alloc] initWithGalleryURL:@"http://gallery.sysctl.co.uk/main.php"];
  NSLog(@"%@", [gallery sendSynchronousCommand:[NSDictionary dictionaryWithObjectsAndKeys:@"login", @"cmd", @"matt", @"uname", @"FTPyjFJN", @"password", nil]]);
  NSLog(@"%@", [gallery sendSynchronousCommand:[NSDictionary dictionaryWithObjectsAndKeys:image, @"g2_userfile", @"2752", @"set_albumName", @"add-item", @"cmd", nil]]);
  
  // TEST
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
