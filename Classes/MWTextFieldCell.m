//
//  MWTextFieldCell.m
//  Gallery
//
//  Created by Matt Wright on 25/07/2009.
//  Copyright 2009 Matt Wright Consulting. All rights reserved.
//

#import "MWTextFieldCell.h"

#pragma mark UIColor Additions

@implementation UIColor (TextEntryColor)

+ (UIColor*)textEntryColor
{
  return [UIColor colorWithRed:0.235294117647059 green:0.341176470588235 blue:0.545098039215686 alpha:1.];
}

@end

#pragma mark -
#pragma mark TextField Cell

@implementation MWTextFieldCell

@synthesize textField;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  // this converts the second detailTextLabel property to have a UITextField directly above it. As such,
  // you should pick the right style but not use the detailTextLabel or you'll end up with oddness.
  if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
  {
    // init with a zero frame, we'll lay it out in layoutSubviews
    textField = [[UITextField alloc] initWithFrame:CGRectZero];
    
    // add the textfield to us
    [self.contentView addSubview:textField];
    
    // there isn't much point writing this code twice, so I'm gonna call prepare for reuse here to
    // setup the text field colours, etc
    [self prepareForReuse];
  }
  return self;
}

- (void)dealloc
{
  [textField removeFromSuperview];
  [textField release];
  textField = nil;
  
  [super dealloc];
}

- (void)prepareForReuse
{
  [super prepareForReuse];
  self.textField.font = [UIFont systemFontOfSize:16.0f];
  self.textField.textColor = [UIColor textEntryColor];
  self.textField.backgroundColor = nil;
  self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  // do this the hard way I guess, carve up the content view so we've got two sections. put the text field in at the same height
  // and y as the textLabel
  
  CGRect leftSide, rightSide;
  CGRectDivide(self.contentView.frame, &leftSide, &rightSide, self.textLabel.frame.size.width, CGRectMinXEdge);
  
  textField.frame = CGRectMake(rightSide.origin.x, self.textLabel.frame.origin.y, rightSide.size.width - 20.f, self.textLabel.frame.size.height);
}

@end
