//
//  iGallerySettingsController.h
//  iGallery
//
//  Created by Matt Wright on 05/10/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface iGallerySettingsController : UIViewController <UITableViewDataSource> {
  UITableView *tableView;
}

@property (nonatomic, retain) UITableView *tableView;

- (IBAction)connect:(id)sender;

@end
