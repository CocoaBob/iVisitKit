//
//  NSString+Additions.h
//  iVisit360
//
//  Created by CocoaBob on 23/07/15.
//  Copyright (c) 2015 Abvent R&D. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Additions)

- (NSArray *)subStringsBetweenStartTag:(NSString *)startTag andEndTag:(NSString *)endTag;

@end
