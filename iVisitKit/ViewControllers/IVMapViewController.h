//
//  MapViewController.h
//  Panorama
//
//  Created by CocoaBob on 12/7/11.
//  Copyright 2011 CocoaBob. All rights reserved.
//

#import "IVHeaders.h"

@class IVMapPageView;

@interface IVMapViewController : UIViewController <UIScrollViewDelegate> {
    UIScrollView *pagingScrollView;
    
    NSMutableSet *recycledPages;
    NSMutableSet *visiblePages;
	
    // These values are stored off before we start rotation so we adjust our content offset appropriately during rotation
    int           firstVisiblePageIndexBeforeRotation;
    CGFloat       percentScrolledIntoFirstVisiblePage;
}

@property (nonatomic, assign) BOOL needPreparationForNewPano;

+ (instancetype)shared;

- (void)cleanEnvironment;

- (void)configurePage:(IVMapPageView *)page forIndex:(NSUInteger)index;
- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;

- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (CGSize)contentSizeForPagingScrollView;

- (void)tilePages;
- (IVMapPageView *)dequeueRecycledPage;

- (NSUInteger)imageCount;

- (void)toggleFullScreen;

@end

