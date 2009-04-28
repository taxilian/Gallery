//
//  NSArray+Extras.m
//  Gallery
//
//  Created by Matt Wright on 28/04/2009.
//  Copyright 2009 Matt Wright Consulting. All rights reserved.
//

#import "NSArray+Extras.h"


@implementation NSArray (Extras)

- (NSArray*)arrayOfStringsStartingWithString:(NSString*)string
{
  NSMutableArray *array = [NSMutableArray array];
  for (id item in self)
  {
    if ([item isKindOfClass:[NSString class]])
    {
      if (([item length] >= [string length]) &&
          ([[item substringToIndex:[string length]] isEqual:string]))
      {
        [array addObject:item];
      }
    }
  }
  return [NSArray arrayWithArray:array];
}

@end
