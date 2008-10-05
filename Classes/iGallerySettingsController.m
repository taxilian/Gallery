//
//  iGallerySettingsController.m
//  iGallery
//
//  Created by Matt Wright on 05/10/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import "iGallerySettingsController.h"

#import "iGalleryAlbumController.h"
#import "CQPreferencesTextCell.h"
#import "Gallery.h"

#define urlTAG 1
#define usernameTAG 2
#define passwordTAG 3

@implementation iGallerySettingsController

@synthesize tableView;
@synthesize albumArray;

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
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:@"UIKeyboardWillShowNotification" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:@"UIKeyboardWillHideNotification" object:nil];
  
  self.title = @"Settings";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(connect:)];
  
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
  self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  
  scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
  scrollView.contentSize = self.tableView.bounds.size;
  scrollView.showsVerticalScrollIndicator = YES;
  
  [scrollView addSubview:self.tableView];
  
  [self.view addSubview:scrollView];
}

- (IBAction)connect:(id)sender
{
  NSError *error;
  UIActivityIndicatorView *loadingIndicator = [[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)] autorelease];
  [loadingIndicator startAnimating];
  [loadingIndicator sizeToFit];
  loadingIndicator.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                       UIViewAutoresizingFlexibleRightMargin |
                                       UIViewAutoresizingFlexibleTopMargin |
                                       UIViewAutoresizingFlexibleBottomMargin);
  
  UIBarButtonItem *loadingBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingIndicator];
  loadingBarButtonItem.style = UIBarButtonItemStyleBordered;
  
  [self.navigationItem setRightBarButtonItem:loadingBarButtonItem animated:YES];
  
  // Blegh, we haven't got a -display on iPhone. So set needs display and let the runloop run while we do it.
  // If it turns out to be shit, we might have to make it a thread.
  [self.navigationController.navigationBar setNeedsDisplay];
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *url = [defaults valueForKey:@"gallery_url"];
  NSString *username = [defaults valueForKey:@"username"];
  NSString *password = [defaults valueForKey:@"password"];
  
  if ((!url || !username || !password) ||
      ([url isEqual:@""] || [username isEqual:@""] || [password isEqual:@""]))
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Unable to login" message:@"You must supply credentials before attempting to load Gallery data." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
    [alert show];
    
    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(connect:)] autorelease] animated:YES];
    return;
  }
  
  Gallery *gallery = [[Gallery alloc] initWithGalleryURL:url];
  NSDictionary *returnData = [gallery sendSynchronousCommand:[NSDictionary dictionaryWithObjectsAndKeys:password, @"password", username, @"uname", @"login", @"cmd", nil] error:&error];
  
  if (error)
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Connection Error" message:[[error localizedDescription] capitalizedString] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
    [alert show];
    
    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(connect:)] autorelease] animated:YES];      
    return;
  }
  
  if ([[returnData valueForKey:@"status"] intValue] != 0)
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Unable to login" message:[returnData valueForKey:@"status_text"] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
    [alert show];
    
    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(connect:)] autorelease] animated:YES];
    return;
  }

  returnData = [gallery sendSynchronousCommand:[NSDictionary dictionaryWithObjectsAndKeys:@"yes", @"no_perms", @"fetch-albums-prune", @"cmd", nil] error:&error];
  if (error)
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Connection Error" message:[[error localizedDescription] capitalizedString] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
    [alert show];
    
    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(connect:)] autorelease] animated:YES];      
    return;
  }
  
  if ([[returnData valueForKey:@"status"] intValue] != 0)
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Unable to login" message:[returnData valueForKey:@"status_text"] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
    [alert show];
    
    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(connect:)] autorelease] animated:YES];
    return;
  }
  
  int albumCount = [[returnData valueForKey:@"album_count"] intValue];
  int currentAlbum;
  
  NSArray *albums = [NSArray array];
  for (currentAlbum = 1; currentAlbum < (albumCount + 1); currentAlbum++)
  {
    NSMutableDictionary *albumData = [NSMutableDictionary dictionary];
    [albumData setValue:[returnData valueForKey:[NSString stringWithFormat:@"album.name.%d", currentAlbum]] forKey:@"name"];
    [albumData setValue:[returnData valueForKey:[NSString stringWithFormat:@"album.title.%d", currentAlbum]] forKey:@"title"];
    [albumData setValue:[returnData valueForKey:[NSString stringWithFormat:@"album.parent.%d", currentAlbum]] forKey:@"parent"];
    albums = [albums arrayByAddingObject:albumData];
  }
    
  self.albumArray = albums;
  [tableView reloadData];
  
  [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(connect:)] autorelease] animated:YES];
}

- (IBAction)albumView:(id)sender
{

}

#pragma mark Keyboard Notifications

- (void)willShowKeyboard:(NSNotification*)notification
{
  NSLog(@"Show");
  CGRect keyboardBounds;
  CGRect scrollViewBounds = [scrollView bounds];
  
  NSValue *boundsValue = [[notification userInfo] objectForKey:UIKeyboardBoundsUserInfoKey];
  [boundsValue getValue:&keyboardBounds];
  
  scrollViewBounds.size.height -= keyboardBounds.size.height;
  
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.25];
  tableView.frame = scrollViewBounds;
  [UIView commitAnimations];
}

- (void)willHideKeyboard:(NSNotification*)notification
{
  NSLog(@"Hide");
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.25];
  tableView.frame = self.view.bounds;
  [UIView commitAnimations];  
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
      [cell setAutocorrectionType:UITextAutocorrectionTypeNo];
      [cell setAutocapitalizationType:UITextAutocapitalizationTypeNone];
      
      [[cell textField] setDelegate:self];
      [[cell textField] setReturnKeyType:UIReturnKeyDone];
      [[cell textField] setTag:urlTAG];
      
      [cell setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"gallery_url"]];

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
      [cell setAutocorrectionType:UITextAutocorrectionTypeNo];
      [cell setAutocapitalizationType:UITextAutocapitalizationTypeNone];

      [[cell textField] setDelegate:self];
      [[cell textField] setReturnKeyType:UIReturnKeyDone];
      
      switch ([indexPath indexAtPosition:1])
      {
        case 0:
          [cell setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"username"]];
          [[cell textField] setTag:usernameTAG];
          break;          
        case 1:
          [cell setSecureTextEntry:YES];
          [cell setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"password"]];
          [[cell textField] setTag:passwordTAG];
          break;
        default:
          break;
      }

      return cell;
    }
      
    case 2:
    {
      UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
      if (!cell)
      {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"UITableViewCell"];
      }
      
      cell.textAlignment = UITextAlignmentRight;
      cell.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
      cell.textColor = [UIColor colorWithRed:0.235294117647059 green:0.341176470588235 blue:0.545098039215686 alpha:1.];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      
      if ([[NSUserDefaults standardUserDefaults] valueForKey:@"albumTitle"])
      {
        cell.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"albumTitle"];
      }
      else
      {
        cell.text = @"None";
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

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath
{
  [tableView deselectRowAtIndexPath:[aTableView indexPathForSelectedRow] animated:YES];
  
  if (albumArray)
  {
    iGalleryAlbumController *albumController = [[iGalleryAlbumController alloc] init];
    albumController.tableItems = albumArray;
    [self.navigationController pushViewController:albumController animated:YES];
  }
  else
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"No album list loaded from Gallery" message:@"Please press refresh before attempting to choose a new album." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
    [alert show];
  }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 3;
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
    case 2:
      return 1;
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
    case 2:
      return @"Upload Album";
    default:
      return nil;
  }
}

- (void)update
{
  [self.tableView reloadData];
}

#pragma mark Textview Delegates

- (void)textFieldDidEndEditing:(UITextField *)textField
{
  CQPreferencesTextCell *urlCell = (CQPreferencesTextCell*)[tableView viewWithTag:urlTAG];
  CQPreferencesTextCell *usernameCell = (CQPreferencesTextCell*)[tableView viewWithTag:usernameTAG];
  CQPreferencesTextCell *passwordCell = (CQPreferencesTextCell*)[tableView viewWithTag:passwordTAG];
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setValue:urlCell.text forKey:@"gallery_url"];
  [defaults setValue:usernameCell.text forKey:@"username"];
  [defaults setValue:passwordCell.text forKey:@"password"];
  
  [defaults synchronize];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  return YES;
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
