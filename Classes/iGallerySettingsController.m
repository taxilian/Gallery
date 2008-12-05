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

#define urlTAG 1
#define usernameTAG 2
#define passwordTAG 3

enum 
{
  GalleryProgressLogin,
  GalleryProgressFetch
};

@interface iGallerySettingsController (Private)

- (void)displayErrorFromDictionary:(NSDictionary*)dictionary;
- (void)displayAlbumList;

@end


@implementation iGallerySettingsController

@synthesize tableView;
@synthesize albumArray;
@synthesize gallery;

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
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowKeyboard:) name:@"UIKeyboardDidShowNotification" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didHideKeyboard:) name:@"UIKeyboardDidHideNotification" object:nil];
  
  self.title = @"Settings";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(connect:)];
  
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
  self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  
  self.gallery = [[Gallery alloc] initWithGalleryURL:nil delegate:self];
  
  showLoadingIndicator = NO;
  updateWantedAlbumList = NO;
  
  [self.view addSubview:tableView];
}

- (void)showLoadingIndicators
{
  UIActivityIndicatorView *toolbarLoadingIndicator = [[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)] autorelease];
  
  [toolbarLoadingIndicator startAnimating];
  [toolbarLoadingIndicator sizeToFit];
  
  toolbarLoadingIndicator.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                              UIViewAutoresizingFlexibleRightMargin |
                                              UIViewAutoresizingFlexibleTopMargin |
                                              UIViewAutoresizingFlexibleBottomMargin);
  
  UIBarButtonItem *loadingBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbarLoadingIndicator];
  loadingBarButtonItem.style = UIBarButtonItemStyleBordered;
  
  [self.navigationItem setRightBarButtonItem:loadingBarButtonItem animated:YES];
  
  // We can't directly access the indicator in the tableView because of cell re-use. So set a flag and reload (force cell refresh)
  // the tableview.
  showLoadingIndicator = YES;
  [tableView reloadData];
}

- (void)hideLoadingIndicators
{
  [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(connect:)] autorelease] animated:YES];
  
  showLoadingIndicator = NO;
  [tableView reloadData];
}

- (BOOL)attemptGalleryUpdate
{
  [self showLoadingIndicators];
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *url = [defaults valueForKey:@"gallery_url"];
  NSString *username = [defaults valueForKey:@"username"];
  NSString *password = [defaults valueForKey:@"password"];
  
  if ((!url || !username || !password) ||
      ([url isEqual:@""] || [username isEqual:@""] || [password isEqual:@""]))
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Unable to login" message:@"You must supply credentials before attempting to load Gallery data." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
    [alert show];
    
    return NO;
  }
  self.gallery.galleryURL = url;
  
  NSURLRequest *request = [gallery requestForCommandDictionary:[NSDictionary dictionaryWithObjectsAndKeys:password, @"password", username, @"uname", @"login", @"cmd", nil]];
  if (![gallery beginAsyncRequest:request withTag:GalleryProgressLogin])
  {
    return NO;
  }
  return YES;
}

- (void)gallery:(Gallery*)thisGallery didRecieveCommandDictionary:(NSDictionary*)dictionary withTag:(long)tag
{
  if (dictionary == nil)
  {
    // We got an error, just stop here
    return;
  }
  
  if ([[dictionary valueForKey:@"status"] intValue] != 0)
  {
    updateWantedAlbumList = NO;
    [self displayErrorFromDictionary:dictionary];
    [self hideLoadingIndicators];
    return;
  }
  
  switch (tag)
  {
    case GalleryProgressLogin:
    {
      NSURLRequest *request = [gallery requestForCommandDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"yes", @"no_perms", @"fetch-albums-prune", @"cmd", nil]];
      [gallery beginAsyncRequest:request withTag:GalleryProgressFetch];
      break;
    }
    case GalleryProgressFetch:
    {
      int currentAlbum, albumCount = [[dictionary valueForKey:@"album_count"] intValue];
      NSArray *albums = [NSArray array];
      
      for (currentAlbum = 1; currentAlbum < (albumCount + 1); currentAlbum++)
      {
        NSMutableDictionary *itemData = [NSMutableDictionary dictionary];
        [itemData setValue:[dictionary valueForKey:[NSString stringWithFormat:@"album.name.%d", currentAlbum]] forKey:@"name"];
        [itemData setValue:[dictionary valueForKey:[NSString stringWithFormat:@"album.title.%d", currentAlbum]] forKey:@"title"];
        [itemData setValue:[dictionary valueForKey:[NSString stringWithFormat:@"album.parent.%d", currentAlbum]] forKey:@"parent"];
        albums = [albums arrayByAddingObject:itemData];
      }
      self.albumArray = albums;
      [tableView reloadData];
      
      // We're done here, hide the spinningness
      [self hideLoadingIndicators];
      
      if (updateWantedAlbumList)
      {
        // Bit of a hack, we actually had clicked the album list before starting all this
        // so we need to simulate that now.
        
        updateWantedAlbumList = NO;
        [self displayAlbumList];
      }
      
      break;
    }
    default:
      // Foo
      break;
  }
}

- (void)gallery:(Gallery*)aGallery didError:(NSError*)error
{
  UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error connect to Gallery" message:[error localizedDescription] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
  [alert show];
  
  updateWantedAlbumList = NO;
  [self hideLoadingIndicators];
}

- (void)displayErrorFromDictionary:(NSDictionary*)dictionary
{
  UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Unable to login" message:[dictionary valueForKey:@"status_text"] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
  [alert show];
}

- (void)displayAlbumList
{  
  if (!albumArray)
  {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"No album list loaded from Gallery" message:@"Please press refresh before attempting to choose a new album." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
    [alert show];
    return;
  }
  iGalleryAlbumController *albumController = [[iGalleryAlbumController alloc] init];
  albumController.tableItems = albumArray;
  [self.navigationController pushViewController:albumController animated:YES];  
}

- (IBAction)connect:(id)sender
{
  [self attemptGalleryUpdate];
}

#pragma mark Keyboard Notifications

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
  // All the textfields we've got are inside a doodah inside a cell. The cell is really what we want to centre around.
  activeView = textField;
  return YES;
}

- (void)didShowKeyboard:(NSNotification*)notification
{
  if (keyboardShown)
  {
    return;
  }
  
  NSArray *indexPathArray = [tableView indexPathsForRowsInRect:[tableView convertRect:activeView.frame fromView:activeView]];
  NSValue *boundsValue = [[notification userInfo] objectForKey:UIKeyboardBoundsUserInfoKey];
  CGRect keyboardBounds = [boundsValue CGRectValue];
   
  CGRect tableViewFrame = [tableView frame];
  tableViewFrame.size.height -= keyboardBounds.size.height;
  tableView.frame = tableViewFrame;
  
  if ([indexPathArray count] > 0)
  {
    [tableView scrollToRowAtIndexPath:[indexPathArray objectAtIndex:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
  }
  keyboardShown = YES;
}

- (void)didHideKeyboard:(NSNotification*)notification
{
  NSValue *boundsValue = [[notification userInfo] objectForKey:UIKeyboardBoundsUserInfoKey];
  CGRect keyboardBounds = [boundsValue CGRectValue];
  
  CGRect tableViewFrame = [tableView frame];
  tableViewFrame.size.height += keyboardBounds.size.height;
  
  [UIView beginAnimations:@"tableView" context:nil];
  tableView.frame = tableViewFrame;
  [UIView commitAnimations];
  
  keyboardShown = NO;
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
      
      //cell.textAlignment = UITextAlignmentRight;
      cell.font = [UIFont systemFontOfSize:17.];
      cell.textColor = [UIColor colorWithRed:0.235294117647059 green:0.341176470588235 blue:0.545098039215686 alpha:1.];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      
      cell.text = ([[NSUserDefaults standardUserDefaults] valueForKey:@"albumTitle"]) ? [[NSUserDefaults standardUserDefaults] valueForKey:@"albumTitle"] : @"None";
      
      if (showLoadingIndicator)
      {
        UIActivityIndicatorView *loadingIndicator = [[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20.0, 20.0)] autorelease];
        [loadingIndicator startAnimating];
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [loadingIndicator sizeToFit];
        loadingIndicator.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
        cell.accessoryView = loadingIndicator;
      }
      else
      {
        cell.accessoryView = nil;
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
  if ([newIndexPath indexAtPosition:0] == 2)
  {
    if (albumArray)
    {
      [tableView deselectRowAtIndexPath:[aTableView indexPathForSelectedRow] animated:YES];
      [self displayAlbumList];
    }
    else
    {
      [tableView deselectRowAtIndexPath:[aTableView indexPathForSelectedRow] animated:NO];
      
      updateWantedAlbumList = YES;
      [self attemptGalleryUpdate];
      return;
    }
    // displayAlbumList will be called later by the other end of the async socket work.
  }
  else
  {
    [tableView deselectRowAtIndexPath:[aTableView indexPathForSelectedRow] animated:NO];
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
  switch (section)
  {
    case 0:
      return @"You should include the /main.php at the\nend of the address.";
    case 1:
    case 2:
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
  if ([textField isDescendantOfView:[tableView viewWithTag:urlTAG]])
  {
    CQPreferencesTextCell *cell = (CQPreferencesTextCell*)[tableView viewWithTag:urlTAG];
    NSString *url = ([cell.text rangeOfString:@"http://"].location == NSNotFound) ? [@"http://" stringByAppendingString:cell.text] : cell.text;
    cell.text = url;
    [[NSUserDefaults standardUserDefaults] setValue:url forKey:@"gallery_url"];
  }
  else if ([textField isDescendantOfView:[tableView viewWithTag:usernameTAG]])
  {
    CQPreferencesTextCell *cell = (CQPreferencesTextCell*)[tableView viewWithTag:usernameTAG];
    [[NSUserDefaults standardUserDefaults] setValue:cell.text forKey:@"username"];
  }
  else if ([textField isDescendantOfView:[tableView viewWithTag:passwordTAG]])
  {
    CQPreferencesTextCell *cell = (CQPreferencesTextCell*)[tableView viewWithTag:passwordTAG];
    [[NSUserDefaults standardUserDefaults] setValue:cell.text forKey:@"password"];    
  }
  else
  {
    NSLog(@"Warning: textFieldDidEndEditing not expected. (%@)", textField);
  }
  [[NSUserDefaults standardUserDefaults] synchronize];
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
