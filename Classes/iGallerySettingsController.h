//
//  iGallerySettingsController.h
//  iGallery
//
//  Created by Matt Wright on 05/10/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface iGallerySettingsController : UIViewController <UITableViewDataSource, UITextFieldDelegate, UITableViewDelegate> {
  UITableView *tableView;
  UIScrollView *scrollView;
  
  UIView *activeView;
  
  NSArray *albumArray;
  
  bool isReloading;
  bool keyboardShown;
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSArray *albumArray;

- (BOOL)attemptGalleryUpdate;

- (IBAction)connect:(id)sender;
- (IBAction)albumView:(id)sender;

- (void)update;

- (void)didShowKeyboard:(NSNotification*)notification;
- (void)didHideKeyboard:(NSNotification*)notification;

@end
