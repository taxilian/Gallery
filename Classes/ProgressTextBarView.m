/*
 ProgressTextBarView.m
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
