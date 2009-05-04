/*
 iGalleryAlbumController.m
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

#import "iGalleryAlbumController.h"
#import "iGallerySettingsController.h"

@implementation iGalleryAlbumController

@synthesize tableView;
@synthesize tableItems;
@synthesize selectedIndexPath;

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
  self.title = @"Albums";
  
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  
  [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
  self.tableView.frame = self.view.bounds;
}

#pragma mark Datasource

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:@"Cell"];
  if (!cell)
  {
    cell = [[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"Cell"];
  }
  
  NSDictionary *rowDictionary = [tableItems objectAtIndex:[indexPath indexAtPosition:1]];
  cell.text = [rowDictionary objectForKey:@"title"];
  if ([[NSUserDefaults standardUserDefaults] objectForKey:@"albumID"])
  {
    if ([[rowDictionary objectForKey:@"name"] isEqual:[[NSUserDefaults standardUserDefaults] objectForKey:@"albumID"]])
    {
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
      self.selectedIndexPath = indexPath;
    }
    else
    {
      cell.accessoryType = UITableViewCellAccessoryNone;
    }
  }
  
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [tableItems count];
}

#pragma mark Delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *newCell = [aTableView cellForRowAtIndexPath:indexPath];
  UITableViewCell *previousCell = [aTableView cellForRowAtIndexPath:self.selectedIndexPath];
  
  [aTableView deselectRowAtIndexPath:indexPath animated:YES];
  
  previousCell.accessoryType = UITableViewCellAccessoryNone;
  newCell.accessoryType = UITableViewCellAccessoryCheckmark;
  
  self.selectedIndexPath = indexPath;
  NSDictionary *selectedItemDictionary = [tableItems objectAtIndex:[indexPath indexAtPosition:1]];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  [defaults setValue:[selectedItemDictionary valueForKey:@"name"] forKey:@"albumID"];
  [defaults setValue:[selectedItemDictionary valueForKey:@"title"] forKey:@"albumTitle"];
  [defaults synchronize];
  [[NSNotificationCenter defaultCenter] postNotificationName:IGSettingsDidChangeNotification object:nil];
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
