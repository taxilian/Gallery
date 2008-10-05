//
//  ProgressTextBarView.h
//  iGallery
//
//  Created by Matt Wright on 05/10/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ProgressTextBarView : UIView {
  UIProgressView *progressView;
  UITextField *textField;
}

@property (nonatomic,retain) UIProgressView *progressView;
@property (nonatomic,retain) UITextField *textField;

@end
