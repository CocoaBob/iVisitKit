//
//  UIViewController+extension.h
//  MMVector
//
//  Created by CocoaBob on 15/09/16.
//
//

#import <UIKit/UIKit.h>

@interface UIViewController (Additions)

+ (UIViewController *)toppest;
- (UIViewController *)toppestViewController;
+ (void)dismissCurrentModalViewController;
- (void)dismissSelf;
- (void)dismissSelfAfterDelay:(NSTimeInterval)delay;
- (void)cancelDismissSelfAfterDelay;
- (void)endEditing;

@end
