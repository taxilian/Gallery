//
//  iGallerySettingsController.m
//  iGallery
//
//  Created by Matt Wright on 05/10/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import "iGallerySettingsController.h"
#import "CQPreferencesTextCell.h"

@implementation iGallerySettingsController

@synthesize tableView;

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
  
  self.title = @"Settings";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(connect:)];
  
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
  self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
  self.tableView.dataSource = self;
  //self.tableView.delegate = self;
  
  [self.view addSubview:self.tableView];
}

- (IBAction)connect:(id)sender
{
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Incorrect Settings" message:@"Unable to retrieve album list from server." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
  [alertView show];
}

#pragma mark Tableview Datasource

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{ 
  switch ([indexPath indexAtPosition:0])
  {
    case 0:
    {
      CQPreferencesTextCell *cell = (CQPreferencesTextCell*)[aTableView dequeueReusableCellWithIdentifier:@"CQPreferencesTextCell"];
      if (!cell)
      {
        cell = [[CQPreferencesTextCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"CQPreferencesTextCell"];
      }
      
      [cell setLabel:@"URL"];
      [cell setPlaceholder:@"http://www.somewhere.com/main.php"];
      [cell setKeyboardType:UIKeyboardTypeURL];
      
      return cell;
    }
    
    // U/P group
    case 1:
    {
      CQPreferencesTextCell *cell = (CQPreferencesTextCell*)[aTableView dequeueReusableCellWithIdentifier:@"CQPreferencesTextCell"];
      if (!cell)
      {
        cell = [[CQPreferencesTextCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"CQPreferencesTextCell"];
      }
      NSArray *rowNames = [NSArray arrayWithObjects:@"Username", @"Password", nil];
      
      [cell setLabel:[rowNames objectAtIndex:[indexPath indexAtPosition:1]]];
      [cell setPlaceholder:[rowNames objectAtIndex:[indexPath indexAtPosition:1]]];
      
      if ([indexPath indexAtPosition:1] == 1)
      {
        [cell setSecureTextEntry:YES];
      }
      
      return cell;
    }
      
    default:
    {
      UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
      if (!cell)
      {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"UITableViewCell"];
      }
      return cell;
    }
  }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    // The URL group has one row
    case 0:
      return 1;
    // The username/password group has two rows
    case 1:
      return 2;
    default:
      return 0;
  }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  switch (section) {
    case 0:
      return @"Gallery URL";
    case 1:
      return @"Authentication";
    default:
      return nil;
  }
}

/*
// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


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
