//
//  ImagePicker.m
//  Gallery
//
//  Created by Matt Wright on 04/12/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import "ImagePicker.h"


@implementation ImagePicker

@synthesize rotationAllowed;

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView 
{
  [super loadView];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
  [super viewDidLoad];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  // Return YES for supported orientations
  if (rotationAllowed)
  {
    return ((interfaceOrientation == UIInterfaceOrientationPortrait) ||
            (interfaceOrientation == UIInterfaceOrientationLandscapeRight) ||
            (interfaceOrientation == UIInterfaceOrientationLandscapeLeft));
  }
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
