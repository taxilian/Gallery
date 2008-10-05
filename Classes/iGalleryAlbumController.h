//
//  iGalleryAlbumController.h
//  iGallery
//
//  Created by Matt Wright on 05/10/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface iGalleryAlbumController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
  UITableView *tableView;
  NSArray *tableItems;
  NSIndexPath *selectedIndexPath;
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSArray *tableItems;
@property (nonatomic, copy) NSIndexPath *selectedIndexPath;

@end
