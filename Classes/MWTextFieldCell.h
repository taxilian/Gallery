//
//  MWTextFieldCell.h
//  Gallery
//
//  Created by Matt Wright on 25/07/2009.
//  Copyright 2009 Matt Wright Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWTableViewCell.h"

@interface UIColor (TextEntryColor)

+ (UIColor*)textEntryColor;

@end


@interface MWTextFieldCell : MWTableViewCell {
  UITextField *textField;
}

@property (readonly) UITextField *textField;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
- (void)dealloc;

- (void)prepareForReuse;
- (void)layoutSubviews;

@end
