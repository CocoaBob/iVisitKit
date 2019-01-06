//
//  IVBaseDocumentViewController.m
//  iVisit 3D
//
//  Created by Bob on 20/09/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVBaseDocumentViewController.h"

#import "IVHeaders.h"

@interface IVBaseDocumentViewController ()

@end

@implementation IVBaseDocumentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Full Screen Settings
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeAll;
    if ([self respondsToSelector:@selector(extendedLayoutIncludesOpaqueBars)])
        self.extendedLayoutIncludesOpaqueBars = YES;
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)])
        self.automaticallyAdjustsScrollViewInsets = NO;


    if ([self.navigationController.navigationBar respondsToSelector:@selector(barTintColor)])
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

    [[self currentOpeningDocument] createCache];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[self currentOpeningDocument] emptyCache];
}

#pragma mark - UI

- (void)showBars:(BOOL)isVisible animated:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:!isVisible animated:animated];
    if (!isVisible) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES
                                                withAnimation:animated?UIStatusBarAnimationFade:UIStatusBarAnimationNone];
    } else if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO
                                                withAnimation:animated?UIStatusBarAnimationFade:UIStatusBarAnimationNone];
    }
}

#pragma mark -

- (void)cleanEnvironment {
    @autoreleasepool {
        
    }
}

#pragma mark - 

- (id)currentOpeningDocument {
    return [IVDocumentManager shared].currentOpeningDocument;
}

- (void)loadDocument {

}

- (void)loadDocumentWithCompletionHandler:(void(^)(void))completionHandler {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self loadDocument];
        if (completionHandler) {
            completionHandler();
        }
    });
}

@end
