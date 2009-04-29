//
//  UIDevice+Extras.m
//  Gallery
//
//  Created by Matt Wright on 28/04/2009.
//  Copyright 2009 Matt Wright Consulting. All rights reserved.
//

#import "UIDevice+Extras.h"


@implementation UIDevice (Extras)

- (BOOL)isVersionThreePointOS
{
  return [[[self systemVersion] substringToIndex:2] isEqual:@"3."];
}

@end
