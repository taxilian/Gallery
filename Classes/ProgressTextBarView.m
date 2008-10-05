//
//  ProgressTextBarView.m
//  iGallery
//
//  Created by Matt Wright on 05/10/2008.
//  Copyright 2008 Matt Wright Consulting. All rights reserved.
//

#import "ProgressTextBarView.h"


@implementation ProgressTextBarView

@synthesize progressView;
@synthesize textField;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
      CGRect bounds = self.bounds;
      
      self.backgroundColor = [UIColor clearColor];
      
      self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
      self.progressView.progress = 0.5;
      [self addSubview:progressView];
            
      self.textField = [[UITextField alloc] init];
      self.textField.text = @"Test";
      self.textField.textAlignment = UITextAlignmentCenter;
      self.textField.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
      self.textField.textColor = [UIColor lightTextColor];
      
      [self addSubview:textField];
      [self.textField sizeToFit];
      
      bounds.size.height = self.progressView.bounds.size.height + self.textField.bounds.size.height + 4.0;
      bounds.size.width = self.progressView.bounds.size.width + 2.0;

      self.bounds = bounds;
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    // Drawing code
}

- (void)layoutSubviews
{
  CGRect viewBounds = self.bounds;
    
  CGRect topRect = CGRectMake(CGRectGetMinX(viewBounds), CGRectGetMinY(viewBounds), self.progressView.bounds.size.width, CGRectGetHeight(viewBounds) / 2.0);
  CGRect bottomRect = CGRectMake(CGRectGetMinX(viewBounds), CGRectGetMaxY(viewBounds) - self.progressView.bounds.size.height, self.progressView.bounds.size.width, self.progressView.bounds.size.height);
  
  [self.textField setFrame:topRect];
  [self.progressView setFrame:bottomRect];
}


- (void)dealloc {
    [super dealloc];
}


@end
