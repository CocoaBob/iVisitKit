//
//  MapViewController.m
//  Panorama
//
//  Created by CocoaBob on 12/7/11.
//  Copyright 2011 CocoaBob. All rights reserved.
//

#import "IVMapViewController.h"

@implementation IVMapViewController {
    BOOL isVisible;
    BOOL isFullScreenUIMode;
    NSUInteger currentMapIndex;
    UIColor *_originalNavBarTintColor;
    NSDictionary *_originalNavBarTitleTextAttributes;
}

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

- (instancetype)init {
    return [[UIStoryboard storyboardWithName:@"IVMapStoryboard" bundle:[NSBundle bundleForClass:self.class]] instantiateInitialViewController];
}

#pragma mark - View loading and unloading

- (void)loadView {
	[super loadView];
	
	// Step 1: make the outer paging scroll view
	pagingScrollView = [[UIScrollView alloc] init];
	pagingScrollView.backgroundColor = [UIColor grayColor];
	pagingScrollView.pagingEnabled = YES;
	pagingScrollView.backgroundColor = [UIColor blackColor];
	pagingScrollView.showsVerticalScrollIndicator = NO;
	pagingScrollView.showsHorizontalScrollIndicator = NO;
	pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	pagingScrollView.delegate = self;
	self.view = pagingScrollView;
	// Step 2: prepare to tile content
	recycledPages = [[NSMutableSet alloc] init];
	visiblePages  = [[NSMutableSet alloc] init];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						   target:self
																						   action:@selector(dismissSelf)];
    self.view.contentMode = UIViewContentModeScaleAspectFill;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Full Screen Settings
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeTop;
    if ([self respondsToSelector:@selector(extendedLayoutIncludesOpaqueBars)])
        self.extendedLayoutIncludesOpaqueBars = YES;
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)])
        self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    pagingScrollView = nil;
    recycledPages = nil;
    visiblePages = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    isVisible = YES;
    [super viewWillAppear:animated];

    isFullScreenUIMode = NO;
    [self showBars:YES animated:YES];

	if (self.needPreparationForNewPano) {
		self.needPreparationForNewPano = NO;
        pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
        for (UIView *subView in pagingScrollView.subviews) {
            if ([subView isKindOfClass:[IVMapPageView class]]) {
                [subView removeFromSuperview];
            }
        }
		[recycledPages removeAllObjects];
		[visiblePages removeAllObjects];
	}
	[self scrollToCurrentMap];
	[self tilePages];
    
    // Appearance
    _originalNavBarTintColor = [UINavigationBar appearance].tintColor;
    _originalNavBarTitleTextAttributes = [UINavigationBar appearance].titleTextAttributes;
    [UINavigationBar appearance].tintColor = UIColor.darkGrayColor;
    [UINavigationBar appearance].titleTextAttributes = @{NSForegroundColorAttributeName: UIColor.darkGrayColor};
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    isVisible = NO;
    [super viewWillDisappear:animated];
    [self showBars:YES animated:YES];
    
    // Appearance
    [UINavigationBar appearance].tintColor = _originalNavBarTintColor;
    [UINavigationBar appearance].titleTextAttributes = _originalNavBarTitleTextAttributes;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
	[self cleanEnvironment];
	self.needPreparationForNewPano = YES;
}

- (void)cleanEnvironment {
    @autoreleasepool {
        for (UIView *subView in pagingScrollView.subviews) {
            if ([subView isKindOfClass:[IVMapPageView class]]) {
                [(IVMapPageView *)subView cleanEnvironment];
            }
        }
        [visiblePages makeObjectsPerformSelector:@selector(cleanEnvironment)];
        [recycledPages makeObjectsPerformSelector:@selector(cleanEnvironment)];
    }
}

#pragma mark - Tiling and page configuration

- (void)scrollToCurrentMap {
    IVPanoramaDocument *panoDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
	for (int idx = 0; idx < [panoDoc mapCount];++idx) {
		IVPanoramaMap *panoramaMap = [panoDoc mapAtIndex:idx];
		if ([[panoramaMap correspondingNodes] containsObject:[panoDoc currentNode]]) {
			pagingScrollView.contentOffset = CGPointMake(pagingScrollView.frame.size.width * idx, 0);
            [self updateCurrentBackground];
            [self updateCurrentTitle];
			break;
		}
	}
}

- (void)updateCurrentTitle {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
    if (curDoc.type == IVDocTypePanoramaV5 || curDoc.type == IVDocTypePanorama360) {
        IVPanoramaMap *map = [curDoc mapAtIndex:currentMapIndex];
        NSString *title = map.mapName;
        if (!title) {
            title = [[map.mapPath lastPathComponent] stringByDeletingPathExtension];
        }
        self.navigationItem.title = title;
    } else {
        self.navigationItem.title = nil;
    }
}

- (void)updateCurrentBackground {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGRect visibleBounds = pagingScrollView.bounds;
        NSUInteger newCurrentMapIndex = (NSUInteger)floor((visibleBounds.origin.x + visibleBounds.size.width / 2.0) / visibleBounds.size.width);
        newCurrentMapIndex = MAX(MIN(newCurrentMapIndex, [self imageCount] - 1), 0);
        if (newCurrentMapIndex != currentMapIndex) {
            currentMapIndex = newCurrentMapIndex;
        }

        IVPanoramaDocument *panoDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
        UIImage *mapImage = [panoDoc mapImageAtIndex:currentMapIndex];
        UIImage *mapBackgroundImage = [[IVImageManager shared] backgroundWithImage:mapImage cacheKey:[NSString stringWithFormat:@"%@%lu",[panoDoc uid],(unsigned long)currentMapIndex]];
        if (self.view.layer.contents != (__bridge id)(mapBackgroundImage.CGImage)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.view.layer.contents = (__bridge id)(mapBackgroundImage.CGImage);
            });
        }
    });
}

- (void)tilePages {
    // Calculate which pages are visible
    CGRect visibleBounds = pagingScrollView.bounds;
    NSInteger firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    NSInteger lastNeededPageIndex  = floorf((CGRectGetMaxX(visibleBounds)-1) / CGRectGetWidth(visibleBounds));
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    lastNeededPageIndex  = MIN(lastNeededPageIndex, [self imageCount] - 1);

    // Recycle no-longer-visible pages 
    for (IVMapPageView *page in visiblePages) {
        if (page.index < firstNeededPageIndex || page.index > lastNeededPageIndex) {
            [recycledPages addObject:page];
            [page removeFromSuperview];
        }
    }
    [visiblePages minusSet:recycledPages];
    
    // add missing pages
    for (NSInteger index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) {
        if (![self isDisplayingPageForIndex:index]) {
            IVMapPageView *page = [self dequeueRecycledPage];
            if (page == nil) {
                page = [[IVMapPageView alloc] initWithFrame:self.view.frame];
            }
            [self configurePage:page forIndex:index];
            [pagingScrollView addSubview:page];
            [visiblePages addObject:page];
        }
    }
	for (IVMapPageView *page in visiblePages) {
		[page updateCoverViewPinColor];
		[[page mapScrollView] setNeedsLayout];
		page.frame = [self frameForPageAtIndex:page.index];
	}

    // Update Background
    [self updateCurrentBackground];
    
    // Update Title
    [self updateCurrentTitle];
}

- (IVMapPageView *)dequeueRecycledPage {
    IVMapPageView *page = [recycledPages anyObject];
    if (page) {
//        [[page retain] autorelease];
        [recycledPages removeObject:page];

    }
    return page;
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
    BOOL foundPage = NO;
    for (IVMapPageView *page in visiblePages) {
        if (page.index == index) {
            foundPage = YES;
            break;
        }
    }
    return foundPage;
}

- (void)configurePage:(IVMapPageView *)page forIndex:(NSUInteger)index {
	if (page.index != index) {
		page.index = index;
		page.frame = [self frameForPageAtIndex:index];
		//[page.mapScrollView performSelectorInBackground:@selector(loadMapAtIndex) withObject:nil];
		[page.mapScrollView loadMapAtIndex];
	}
}

#pragma mark - ScrollView delegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self tilePages];
}

#pragma mark - View controller rotation methods

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // here, our pagingScrollView bounds have not yet been updated for the new interface orientation. So this is a good
    // place to calculate the content offset that we will need in the new orientation
    CGFloat offset = pagingScrollView.contentOffset.x;
    CGFloat pageWidth = pagingScrollView.bounds.size.width;
    
    if (pageWidth > 0) {
        if (offset >= 0) {
            firstVisiblePageIndexBeforeRotation = floorf(offset / pageWidth);
            percentScrolledIntoFirstVisiblePage = (offset - (firstVisiblePageIndexBeforeRotation * pageWidth)) / pageWidth;
        } else {
            firstVisiblePageIndexBeforeRotation = 0;
            percentScrolledIntoFirstVisiblePage = offset / pageWidth;
        }
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // recalculate contentSize based on current orientation
        pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
        
        // adjust frames and configuration of each visible page
        for (IVMapPageView *page in visiblePages) {
            CGPoint restorePoint = [page.mapScrollView pointToCenterAfterRotation];
            CGFloat restoreScale = [page.mapScrollView scaleToRestoreAfterRotation];
            
            [page.mapScrollView resetZoomScales];
            [page.mapScrollView restoreCenterPoint:restorePoint scale:restoreScale animated:NO];
        }
        
        // adjust contentOffset to preserve page location based on values collected prior to location
        CGFloat pageWidth = pagingScrollView.bounds.size.width;
        CGFloat newOffset = (firstVisiblePageIndexBeforeRotation * pageWidth) + (percentScrolledIntoFirstVisiblePage * pageWidth);
        pagingScrollView.contentOffset = CGPointMake(newOffset, 0);
        
        // Show/Hide status bar
        if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        } else if (!self.navigationController.navigationBarHidden) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        }
    } completion:nil];
}

#pragma mark - Frame calculations

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    CGRect bounds = pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.origin.x = bounds.size.width * index;
    return pageFrame;
}

- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self imageCount], bounds.size.height);
}

#pragma mark - Image wrangling

- (NSUInteger)imageCount {
    IVPanoramaDocument *panoDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
    return [panoDoc mapCount];
}

#pragma mark - Full Screen toggling

- (void)toggleFullScreen {
    if (!isVisible)
        return;
	isFullScreenUIMode = !isFullScreenUIMode;
    [self showBars:!isFullScreenUIMode animated:YES];
}

- (void)showBars:(BOOL)visible animated:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:!visible animated:animated];
    if (!visible) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES
                                                withAnimation:animated?UIStatusBarAnimationFade:UIStatusBarAnimationNone];
    } else if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO
                                                withAnimation:animated?UIStatusBarAnimationFade:UIStatusBarAnimationNone];
    }
}

@end
