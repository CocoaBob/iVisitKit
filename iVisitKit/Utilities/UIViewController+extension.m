//
//  UIViewController+extension.m
//  MMVector
//
//  Created by CocoaBob on 15/09/16.
//
//

#import "UIViewController+extension.h"

@implementation UIViewController (Additions)

+ (UIViewController *)toppest {
    UIApplication *app = [UIApplication sharedApplication];
    return [[([app keyWindow] ?: [[app windows] lastObject]) rootViewController] toppestViewController];
}

- (UIViewController *)toppestViewController {
    return [self toppestViewController: self];
}

- (UIViewController *)toppestViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UIViewController *toppestViewController = [((UINavigationController *)viewController) visibleViewController];
        if (toppestViewController) {
            return [self toppestViewController: toppestViewController];
        }
    }
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        UIViewController *toppestViewController = [((UITabBarController *)viewController) selectedViewController];
        if (toppestViewController) {
            return [self toppestViewController: toppestViewController];
        }
    }
    if ([viewController isKindOfClass:[UISearchController class]]) {
        UIViewController *toppestViewController = [((UISearchController *)viewController) searchResultsController];
        if (toppestViewController) {
            return [self toppestViewController: toppestViewController];
        }
    }
    UIViewController *toppestViewController = [viewController presentedViewController];
    if (toppestViewController) {
        return [self toppestViewController: toppestViewController];
    }
    
    return viewController;
}

+ (void)dismissCurrentModalViewController {
    UIViewController *vc = [UIViewController toppest];
    if (vc.presentingViewController) {
        [vc dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)dismissSelf {
    [self cancelDismissSelfAfterDelay];
    if (self.navigationController &&
        self.navigationController.viewControllers.count > 1 &&
        self.navigationController.viewControllers.lastObject == self) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)dismissSelfAfterDelay:(NSTimeInterval)delay {
    [self cancelDismissSelfAfterDelay];
    [self performSelector:@selector(dismissSelf) withObject:nil afterDelay:delay];
}

- (void)cancelDismissSelfAfterDelay {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissSelf) object:nil];
}

- (void)endEditing {
    [self.view endEditing:YES];
}

@end
