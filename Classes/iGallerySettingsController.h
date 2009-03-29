//
//  iGallerySettingsController.h
//  iGallery
//
//  Created by Matt Wright on 05/10/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Gallery.h"

NSString* const IGSettingsDidChangeNotification;

@interface iGallerySettingsController : UIViewController <UITableViewDataSource, UITextFieldDelegate, UITableViewDelegate> {
  Gallery *gallery;
  
  UITableView *tableView;
  UIScrollView *scrollView;
  
  UIView *activeView;
  
  NSArray *albumArray;
  
  bool updateWantedAlbumList;
  bool showLoadingIndicator;
  bool keyboardShown;
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSArray *albumArray;
@property (nonatomic, retain) Gallery *gallery;

- (BOOL)attemptGalleryUpdate;

- (IBAction)connect:(id)sender;

- (void)update;

- (void)didShowKeyboard:(NSNotification*)notification;
- (void)didHideKeyboard:(NSNotification*)notification;

@end
