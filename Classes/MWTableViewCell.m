//
//  MWTableViewCell.m
//  Gallery
//
//  Created by Matt Wright on 26/07/2009.
//  Copyright 2009 Matt Wright Consulting. All rights reserved.
//

#import "MWTableViewCell.h"


@implementation MWTableViewCell

@synthesize verticalDivider;

- (void)prepareForReuse
{
  [super prepareForReuse];
  verticalDivider = -1.0f;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  if (verticalDivider > 0.0f)
  {
    CGRect bounds = [self bounds];
    CGRect leftSide, rightSide;
    
    CGRectDivide(bounds, &leftSide, &rightSide, verticalDivider, CGRectMinXEdge);
    
    CGRect textLabelFrame = self.textLabel.frame;
    CGRect detailLabelFrame = self.detailTextLabel.frame;
    
    textLabelFrame.origin.x = 10;
    textLabelFrame.size.width = (leftSide.size.width - 10 - 5);
    detailLabelFrame.origin.x = textLabelFrame.origin.x + textLabelFrame.size.width + 10;
    detailLabelFrame.size.width = bounds.size.width - (detailLabelFrame.origin.x + 30);
    
    self.textLabel.frame = textLabelFrame;
    self.detailTextLabel.frame = detailLabelFrame;
  }
}

@end
