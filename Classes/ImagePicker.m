/*
 ImagePicker.h
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

- (BOOL)_isSupportedInterfaceOrientation:(int)fp8
{
  return [self shouldAutorotateToInterfaceOrientation:fp8];
}

// Override to allow orientations other than the default portrait orientation.
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//  // Return YES for supported orientations
//  if (rotationAllowed)
//  {
//    return ((interfaceOrientation == UIInterfaceOrientationPortrait) ||
//            (interfaceOrientation == UIInterfaceOrientationLandscapeRight) ||
//            (interfaceOrientation == UIInterfaceOrientationLandscapeLeft));
//  }
//  return (interfaceOrientation == UIInterfaceOrientationPortrait);
//}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [super dealloc];
}


@end
