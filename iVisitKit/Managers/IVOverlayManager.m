//
//  IVOverlayManager.m
//  iVisit 3D
//
//  Created by CocoaBob on 18/10/2013.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVOverlayManager.h"

@interface IVOverlayManager ()

@property (nonatomic, strong) UIView *mHUDPromptView;

@end

@implementation IVOverlayManager {
	UIImageView *mLaunchSplashView;
}

#pragma mark - Object Lifecycle

+ (instancetype)shared {
    static id __sharedInstance = nil;
    if (__sharedInstance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            __sharedInstance = [[[self class] alloc] init];
        });
    }
    return __sharedInstance;
}

#pragma mark - Prompt Indicator View

- (UIView *)promptView {
	if (!self.mHUDPromptView) {
        NSUInteger promptViewSize = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?160:128;
		self.mHUDPromptView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, promptViewSize, promptViewSize)];
        self.mHUDPromptView.opaque = NO;
        self.mHUDPromptView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		self.mHUDPromptView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
		self.mHUDPromptView.layer.cornerRadius = 8;
		
		UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		activityIndicator.center = self.mHUDPromptView.center;
        [activityIndicator startAnimating];
		[self.mHUDPromptView addSubview:activityIndicator];
	}
	return self.mHUDPromptView;
}

- (void)showActivityViewWithCompletionHandler:(void(^)(void))completionHandler {
    UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
    
    [self promptView].center = mainWindow.center;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainWindow addSubview:[self promptView]];
        [UIView animateWithDuration:0.1f
                         animations:^{
                             [self promptView].alpha = 1;
                         }
                         completion:^(BOOL finished) {
                             if (completionHandler) {
                                 completionHandler();
                             }
                         }];
    });
}

- (void)hideActivityView {
    [UIView animateWithDuration:0.1f
                     animations:^{
                         [self promptView].alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [[self promptView] removeFromSuperview];
                     }];
}

@end
