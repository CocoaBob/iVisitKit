//
//  NSString+Additions.m
//  iVisit360
//
//  Created by CocoaBob on 23/07/15.
//  Copyright (c) 2015 Abvent R&D. All rights reserved.
//

#import "NSString+Additions.h"

@implementation NSString (Additions)

- (NSArray *)subStringsBetweenStartTag:(NSString *)startTag andEndTag:(NSString *)endTag {
    NSMutableArray *returnValue = [NSMutableArray new];
    if (self.length > 0) {
        NSScanner *scanner = [[NSScanner alloc] initWithString:self];
        NSUInteger scanPosition = 0;
        while (scanPosition < self.length) {
            NSString* scanString = @"";
            scanner.scanLocation = scanPosition;
            @try {
                // If nothing to scan
                if (![scanner scanUpToString:startTag intoString:nil]) {
                    break;
                }
                // If scans to the end
                if (scanner.scanLocation >= self.length) {
                    break;
                }
                scanner.scanLocation += [startTag length];
                // If nothing to scan
                if (![scanner scanUpToString:endTag intoString:&scanString]) {
                    break;
                }
                scanPosition = scanner.scanLocation + [endTag length];
                if (scanString.length > 0) {
                    [returnValue addObject:scanString];
                }
            }
            @catch (NSException *exception) {
                NSLog(@"%s %@ %@",__PRETTY_FUNCTION__, exception.name, exception.reason);
                break;
            }
        }
    }
    return returnValue;
}

@end
