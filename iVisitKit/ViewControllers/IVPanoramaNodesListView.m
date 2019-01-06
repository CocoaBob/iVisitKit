//
//  IVPanoramaNodesListView.m
//  iVisit 3D
//
//  Created by Bob on 03/07/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVPanoramaNodesListView.h"

#pragma mark -

@interface IVNodeVersionsView () <IVNodesListViewDelegate>

@end

@implementation IVNodeVersionsView {
    IVVersionedNodesListView *_nodesListView;
    NSMutableArray *_nodeVersions;
}

+ (void)presentWithNode:(IVPanoramaNode *)node fromPageView:(IVNodesListPageView *)pageView {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    IVNodeVersionsView *versionsView = [[IVNodeVersionsView alloc] initWithFrame:keyWindow.bounds];
    versionsView.sourcePageView = pageView;
    
    [keyWindow addSubview:versionsView];
    [versionsView prepareNodesListView];
    [pageView hideBackgroundLayers];
    [UIView animateWithDuration:0.15
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         versionsView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
                         [versionsView showNodesListView];
                     }
                     completion:nil];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissSelf)];
        tapGestureRecognizer.numberOfTapsRequired = 1;
        tapGestureRecognizer.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:tapGestureRecognizer];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          [UIView animateWithDuration:0.3
                                                                                delay:0
                                                                              options:UIViewAnimationOptionCurveEaseInOut
                                                                           animations:^{
                                                                                  [self updateNodesListFrame];
                                                                              }
                                                                           completion:nil];
                                                      }];
    }
    return self;
}

- (void)setSourcePageView:(IVNodesListPageView *)pageView {
    _sourcePageView = pageView;
    
    // Update versions
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
    NSArray *versions = [curDoc versionsOfNodeID:_sourcePageView.nodeID];
    if (versions) {
        _nodeVersions = [versions mutableCopy];
        [self selectNodeVersion:_sourcePageView.nodeID];
    } else {
        _nodeVersions = nil;
    }
}

- (void)selectNodeVersion:(NSString *)nodeID {
    if ([_nodeVersions containsObject:nodeID]) {
        [_nodeVersions removeObject:nodeID];
        [_nodeVersions addObject:nodeID];
    }
}

- (void)dismissSelf {
    [UIView animateWithDuration:0.15
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.backgroundColor = [UIColor clearColor];
                         [self hideNodesListView];
                     }
                     completion:^(BOOL finished) {
                         [self removeFromSuperview];
                         [_sourcePageView showBackgroundLayers];
                     }];
    
}

- (void)prepareNodesListView {
    _nodesListView = [[IVVersionedNodesListView alloc] initWithFrame:CGRectZero];
    _nodesListView.isVertical = YES;
    _nodesListView.alwaysBounce = NO;
    _nodesListView.delegate = self;
    
    [self addSubview:_nodesListView];
    
    // Prepare all pages
    [self updateNodesListFrame];
    [_nodesListView updateContentSizeForPagingScrollView];
    [_nodesListView updateAllPages];
    
    // Set original frame
    CGRect pageViewFrame = [self convertRect:_sourcePageView.frame fromView:_sourcePageView.superview];
    pageViewFrame = CGRectInset(pageViewFrame, -NODE_PAGE_MARGIN_INSET, -NODE_PAGE_MARGIN_INSET);
    _nodesListView.frame = pageViewFrame;
    
    // Move all pages to the begin position before animation
    [_nodesListView resetPageViewPositions];
}

- (void)showNodesListView {
    // Set final frame
    [self updateNodesListFrame];
    [_nodesListView tilePages];
}

- (void)hideNodesListView {
    CGRect pageViewFrame = [self convertRect:_sourcePageView.frame fromView:_sourcePageView.superview];
    pageViewFrame = CGRectInset(pageViewFrame, -NODE_PAGE_MARGIN_INSET, -NODE_PAGE_MARGIN_INSET);
    _nodesListView.frame = pageViewFrame;
    IVNodesListPageView *pageView = [_nodesListView bringPageViewToFrontWithNodeID:_sourcePageView.nodeID];
    pageView.selected = YES;
    [_nodesListView resetPageViewPositions];
}

- (void)updateNodesListFrame {
    CGRect pageViewFrame = [self convertRect:_sourcePageView.frame fromView:_sourcePageView.superview];
    CGFloat pageViewSize = CGRectGetWidth(_sourcePageView.frame) + NODE_PAGE_MARGIN_INSET * 2;
    CGFloat expectedHeight = pageViewSize * [self numberOfNodes];
    CGFloat frameHeight = MIN(expectedHeight, CGRectGetMaxY(pageViewFrame));
    
    CGRect frame = CGRectMake(CGRectGetMinX(pageViewFrame) - NODE_PAGE_MARGIN_INSET,
                              CGRectGetMaxY(pageViewFrame) - frameHeight + NODE_PAGE_MARGIN_INSET,
                              pageViewSize,
                              frameHeight);
    _nodesListView.frame = frame;
}

#pragma mark - IVNodesListViewDelegate

- (NSUInteger)numberOfNodes {
    return _nodeVersions?_nodeVersions.count:0;
}

- (NSString *)nodeIDAtIndex:(NSUInteger)nodeIndex {
    if (_nodeVersions && nodeIndex < _nodeVersions.count) {
        return _nodeVersions[nodeIndex];
    } else {
        return nil;
    }
}

- (NSUInteger)indexOfNodeID:(NSString *)nodeID {
    return [_nodeVersions indexOfObject:nodeID];
}

- (BOOL)shouldDisplayPageViewBackground {
    return NO;
}

- (BOOL)isSelected:(NSString *)nodeID {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
    return [curDoc.currentNodeID isEqualToString:_sourcePageView.nodeID] && [_sourcePageView.nodeID isEqualToString:nodeID];
}

- (void)didSelectPageView:(IVNodesListPageView *)pageView {
    NSString *nextNodeID = pageView.nodeID;
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
    if (![curDoc.currentNodeID isEqualToString:nextNodeID]) {
        BOOL wasSelected = _sourcePageView.isSelected;
        [self selectNodeVersion:nextNodeID];
        
        IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
        [curDoc replaceVisibleNodeID:_sourcePageView.nodeID withNextVersionNodeID:nextNodeID];
        [_sourcePageView setNodeID:nextNodeID];
        [_sourcePageView loadNode:wasSelected]; // If the source view wasn't selected, it means it's not from the same versioned node
        [self dismissSelf];
    } else {
        [self dismissSelf];
    }
}

- (void)didLongSelectPageView:(IVNodesListPageView *)pageView {
    
}

@end

#pragma mark -

#define STACK_STYLE 2

@implementation IVNodesListPageView {
	BOOL _isOpening;
    CALayer *_contentLayer;
    NSArray *_bgLayers;
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        
        // Content Layer
        _contentLayer = [CALayer layer];
        _contentLayer.anchorPoint = CGPointMake(0.5, 0.5);
        _contentLayer.contentsGravity = kCAGravityResizeAspectFill;
        _contentLayer.borderWidth = 2;
        [self.layer addSublayer:_contentLayer];
		
        // Gestures
		UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTaped:)];
		tapGestureRecognizer.numberOfTapsRequired = 1;
		tapGestureRecognizer.numberOfTouchesRequired = 1;
		[self addGestureRecognizer:tapGestureRecognizer];
        
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
        [self addGestureRecognizer:longPressGestureRecognizer];
    }
	return self;
}

#pragma mark - Properties

- (IVNodesListBaseView *)nodesListView {
    IVNodesListBaseView *nodesListView = (IVNodesListBaseView *)self.superview.superview;
    return nodesListView;
}

- (void)setSelected:(BOOL)selected {
    _selected = selected;
    
    // Update layers' colors
    _contentLayer.borderColor = [UIColor colorWithWhite:_selected?1:0.67 alpha:1].CGColor;
    for (CALayer *bgLayer in _bgLayers) {
        bgLayer.borderColor = [UIColor colorWithWhite:_selected?0.9:0.67 alpha:1].CGColor;
    }
}

#pragma mark - Background layers

#if STACK_STYLE == 0 || STACK_STYLE == 2
- (CALayer *)newBGLayer {
#elif STACK_STYLE == 1
- (CALayer *)bgLayerWithRotation:(CGFloat)rotation {
#endif
    
    CALayer *bgLayer = [CALayer layer];
    bgLayer.backgroundColor = [UIColor grayColor].CGColor;
    bgLayer.borderWidth = 2;
    bgLayer.borderColor = [UIColor colorWithWhite:0.67 alpha:1].CGColor;
    bgLayer.allowsEdgeAntialiasing = YES;
    bgLayer.anchorPoint = CGPointMake(0.5, 0.5);
    
#if STACK_STYLE == 1
    bgLayer.affineTransform = CGAffineTransformMakeRotation(rotation);
#endif
    
    return bgLayer;
    
#if STACK_STYLE == 0 || STACK_STYLE == 2
}
#elif STACK_STYLE == 1
}
#endif

- (void)showBackgroundLayers {
    if (_backgroundEnabled && self.layer.sublayers.count > 0) {
        for (CALayer *bgLayer in _bgLayers) {
            [self.layer insertSublayer:bgLayer atIndex:0];
        }
    }
}

- (void)hideBackgroundLayers {
    for (CALayer *bgLayer in _bgLayers) {
        [bgLayer removeFromSuperlayer];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _contentLayer.frame = self.bounds;
    for (int i = 0;i < _bgLayers.count;++i) {
        CALayer *bgLayer = _bgLayers[i];
#if STACK_STYLE == 0
        CGFloat harmonicSeriesSum = log(i+1) + 0.5772156649;
        CGFloat inset = CGRectGetHeight(_contentLayer.bounds) * 0.015 * (harmonicSeriesSum + 1);
        bgLayer.bounds = CGRectInset(_contentLayer.bounds, inset, inset);
        bgLayer.position = CGPointMake(_contentLayer.position.x, _contentLayer.position.y - inset * 2);
#elif STACK_STYLE == 1
        bgLayer.anchorPoint  = CGPointMake(0, 1);
        bgLayer.bounds = _contentLayer.bounds;
        bgLayer.position = CGPointMake(_contentLayer.position.x - CGRectGetWidth(bgLayer.bounds) / 2.0,
                                       _contentLayer.position.y + CGRectGetHeight(bgLayer.bounds) / 2.0);
#elif STACK_STYLE == 2
#define STACK_MARGIN 2
#define STACK_INSET 4
        bgLayer.anchorPoint  = CGPointMake(0, 0);
        bgLayer.position = CGPointMake(STACK_INSET * (i + 1), -STACK_MARGIN * (i + 1));
        bgLayer.bounds = CGRectMake(0, 0, CGRectGetWidth(_contentLayer.bounds) - STACK_INSET * (i + 1) * 2, 1);
#endif
    }
}

#pragma mark - Node ID and content

- (void)updateContent {
	IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
    _contentLayer.contents = (__bridge id)([curDoc thumbnailImageOfNode:_nodeID].CGImage);
}

- (void)setNodeID:(NSString *)nodeID {
    _nodeID = nodeID;
    [self updateContent];
    
    // Update background
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
    IVPanoramaNode *node = [curDoc nodeWithNodeID:_nodeID];
    if ([node isVersioned]) {
        NSArray *versions = [curDoc versionsOfNodeID:_nodeID];
#if STACK_STYLE == 0 || STACK_STYLE == 2
        if (versions.count == 2) {
            _bgLayers = @[[self newBGLayer]];
        } else if (versions.count == 3) {
            _bgLayers = @[[self newBGLayer],[self newBGLayer]];
        } else if (versions.count > 3) {
            _bgLayers = @[[self newBGLayer],[self newBGLayer],[self newBGLayer]];
        }
#elif STACK_STYLE == 1
        CGFloat rotationStep = M_PI / 48.0;
        if (versions.count == 2) {
            _bgLayers = @[[self bgLayerWithRotation:rotationStep * log(2)]];
        } else if (versions.count == 3) {
            _bgLayers = @[[self bgLayerWithRotation:rotationStep * log(2)],
                          [self bgLayerWithRotation:rotationStep * log(3)]];
        } else if (versions.count > 3) {
            _bgLayers = @[[self bgLayerWithRotation:rotationStep * log(2)],
                          [self bgLayerWithRotation:rotationStep * log(3)],
                          [self bgLayerWithRotation:rotationStep * log(4)]];
        }
#endif
        [self showBackgroundLayers];
    } else {
        [self hideBackgroundLayers];
    }
}

- (void)loadNode:(BOOL)isFromSameNode {
	if (!_isOpening) {
        _isOpening = YES;
        [[IVOverlayManager shared] showActivityViewWithCompletionHandler:^{
            IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
            IVPanoramaNode* node = [curDoc nodeWithNodeID:_nodeID];
            BOOL wasV4Mode = curDoc.isV4NaviMode;
            if (isFromSameNode) {
                curDoc.isV4NaviMode = YES;
            }
            [[IVPanoramaViewController shared] loadNode:_nodeID
                                             turnToFace:isFromSameNode?FaceUnchange:[curDoc defaultFaceOfNode:node]
                                             completion:^{
                                                 [[IVOverlayManager shared] hideActivityView];
                                                 _isOpening = NO;
                                                 if (isFromSameNode) {
                                                     curDoc.isV4NaviMode = wasV4Mode;
                                                 }
                                             }];
        }];
	}
}

#pragma mark - Handler Gesture Recognizers

- (void)singleTaped:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        [[self nodesListView] didSelectPageView:self];
    }
}

- (void)longPressed:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [[self nodesListView] didLongSelectPageView:self];
    }
}

@end

#pragma mark -

@interface IVNodesListBaseView () <UIScrollViewDelegate>

@property (nonatomic,strong) UIScrollView *pagingScrollView;

@property (nonatomic,strong) NSMutableSet *recycledPages;
@property (nonatomic,strong) NSMutableSet *visiblePages;

- (void)updateAllPages;

@end

@implementation IVNodesListBaseView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initializeNodesListBaseView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initializeNodesListBaseView];
    }
    return self;
}

- (void)initializeNodesListBaseView {
    self.listInsets = UIEdgeInsetsZero;
    
    // Step 1: make the outer paging scroll view
    _pagingScrollView = [[UIScrollView alloc] init];
    _pagingScrollView.clipsToBounds = NO;
    _pagingScrollView.pagingEnabled = NO;
    _pagingScrollView.bounces = YES;
    _pagingScrollView.alwaysBounceHorizontal = YES;
    _pagingScrollView.backgroundColor = [UIColor clearColor];
    _pagingScrollView.showsVerticalScrollIndicator = NO;
    _pagingScrollView.showsHorizontalScrollIndicator = NO;
    _pagingScrollView.delegate = self;
    _pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_pagingScrollView];
    
    // Step 2: prepare to tile content
    _recycledPages = [NSMutableSet new];
    _visiblePages  = [NSMutableSet new];
}

- (void)setIsVertical:(BOOL)isVertical {
    _isVertical = isVertical;
    
    [self setAlwaysBounce:_alwaysBounce];
}

- (void)setListInsets:(UIEdgeInsets)listInsets {
    _listInsets = listInsets;
    
    CGRect frame = [self bounds];
    UIEdgeInsets insets = self.listInsets;
    frame.size.height -= (insets.bottom + insets.top);
    frame.origin.y += insets.bottom;
    frame.size.width -= (insets.left + insets.right);
    frame.origin.x += insets.left;
    _pagingScrollView.frame = frame;
}
    
- (void)setAlwaysBounce:(BOOL)alwaysBounce {
    _alwaysBounce = alwaysBounce;
    
    if (_isVertical) {
        _pagingScrollView.alwaysBounceVertical = _alwaysBounce;
        _pagingScrollView.alwaysBounceHorizontal = NO;
    } else {
        _pagingScrollView.alwaysBounceVertical = NO;
        _pagingScrollView.alwaysBounceHorizontal = _alwaysBounce;
    }
}

#pragma mark - UIView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!CGRectContainsPoint(_pagingScrollView.frame, point) &&
         CGRectContainsPoint(self.bounds, point)) {
        return _pagingScrollView;
    }
    
    return [super hitTest:point	withEvent:event];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Update scroll view insest to center its content
    if (_isVertical) {
        _pagingScrollView.contentInset = UIEdgeInsetsZero;
    } else {
        CGFloat inset = (CGRectGetWidth(_pagingScrollView.frame) - _pagingScrollView.contentSize.width) / 2.0;
        inset = MAX(0, inset);
        _pagingScrollView.contentInset = UIEdgeInsetsMake(0, inset, 0, inset);
    }
}

#pragma mark - View loading and unloading

- (void)removeAllPageViews {
    @autoreleasepool {
        for (UIView *subView in _pagingScrollView.subviews) {
            if ([subView isKindOfClass:[IVNodesListPageView class]]) {
                [subView removeFromSuperview];
            }
        }
    }
}

- (void)cleanEnvironment {
    [self removeAllPageViews];
}

#pragma mark - Tiling and page configuration

- (CGFloat)pageWidth {
    if (_isVertical) {
        return _pagingScrollView.frame.size.width;
    } else {
        return _pagingScrollView.frame.size.height;
    }
}

- (CGFloat)pageHeight {
    if (_isVertical) {
        return _pagingScrollView.frame.size.width;
    } else {
        return _pagingScrollView.frame.size.height;
    }
}

- (void)tilePages {
    // Calculate which pages are visible
    CGRect visibleBounds = _pagingScrollView.bounds;
    NSInteger firstNeededPageIndex,lastNeededPageIndex;
    if (_isVertical) {
        firstNeededPageIndex = floorf(CGRectGetMinY(visibleBounds) / [self pageHeight]);
        lastNeededPageIndex  = floorf((CGRectGetMaxY(visibleBounds)-1) / [self pageHeight]);
    } else {
        firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / [self pageWidth]);
        lastNeededPageIndex  = floorf((CGRectGetMaxX(visibleBounds)-1) / [self pageWidth]);
    }
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    lastNeededPageIndex  = MIN(lastNeededPageIndex, [self.delegate numberOfNodes] - 1);
    
    // Recycle no-longer-visible pages
    for (IVNodesListPageView *page in self.visiblePages) {
        NSUInteger nodeIndex = [self.delegate indexOfNodeID:page.nodeID];
        if (nodeIndex < firstNeededPageIndex || nodeIndex > lastNeededPageIndex) {
            [self.recycledPages addObject:page];
            [page removeFromSuperview];
        }
    }
    [self.visiblePages minusSet:self.recycledPages];
    
    // add missing pages
    for (NSInteger idx = firstNeededPageIndex; idx <= lastNeededPageIndex; idx++) {
        if (![self isDisplayingPageForIndex:idx]) {
            IVNodesListPageView *page = [self dequeueRecycledPage];
            if (page == nil) {
                page = [[IVNodesListPageView alloc] initWithFrame:CGRectZero];
            }
            
            page.backgroundEnabled = [self.delegate shouldDisplayPageViewBackground];
            page.nodeID = [self.delegate nodeIDAtIndex:idx];
            
            [_pagingScrollView addSubview:page];
            [self.visiblePages addObject:page];
        }
    }
    
    // Update positions and status
    for (IVNodesListPageView *page in self.visiblePages) {
        page.frame = [self frameForPageAtIndex:[self.delegate indexOfNodeID:page.nodeID]];
        page.selected = [self.delegate isSelected:page.nodeID];
    }
}

- (IVNodesListPageView *)dequeueRecycledPage {
    IVNodesListPageView *page = [self.recycledPages anyObject];
    if (page) {
        [self.recycledPages removeObject:page];
    }
    return page;
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
    BOOL foundPage = NO;
    for (IVNodesListPageView *page in self.visiblePages) {
        NSUInteger nodeIndex = [self.delegate indexOfNodeID:page.nodeID];
        if (nodeIndex == index) {
            foundPage = YES;
            break;
        }
    }
    return foundPage;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self tilePages];
}

#pragma mark - Frame calculations

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    CGRect pageFrame = CGRectMake(0, 0, [self pageWidth], [self pageHeight]);
    if (_isVertical) {
        pageFrame.origin.y = pageFrame.size.height * index;
    } else {
        pageFrame.origin.x = pageFrame.size.width * index;
    }
    pageFrame = CGRectInset(pageFrame, NODE_PAGE_MARGIN_INSET, NODE_PAGE_MARGIN_INSET);
    return pageFrame;
}

- (void)updateContentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    if (_isVertical) {
        CGFloat contentSizeHeight = [self pageHeight] * [self.delegate numberOfNodes];
        _pagingScrollView.contentSize = CGSizeMake([self pageWidth] ,contentSizeHeight);
    } else {
        CGFloat contentSizeWidth = [self pageWidth] * [self.delegate numberOfNodes];
        _pagingScrollView.contentSize = CGSizeMake(contentSizeWidth, [self pageHeight]);
    }
}

#pragma mark -

- (void)updateAllPages {
    [self removeAllPageViews];
    [self.recycledPages removeAllObjects];
    [self.visiblePages removeAllObjects];
    [self updateContentSizeForPagingScrollView];
    [self tilePages];
}

- (void)updateSelectionStatus {
    for (UIView *subView in self.pagingScrollView.subviews) {
        if ([subView isKindOfClass:[IVNodesListPageView class]]) {
            IVNodesListPageView *pageView = (IVNodesListPageView *)subView;
            pageView.selected = [self.delegate isSelected:pageView.nodeID];
        }
    }
}

- (void)didSelectPageView:(IVNodesListPageView *)pageView {
    [self.delegate didSelectPageView:pageView];
}

- (void)didLongSelectPageView:(IVNodesListPageView *)pageView {
    [self.delegate didLongSelectPageView:pageView];
}

@end

#pragma mark -

@implementation IVVersionedNodesListView

- (void)resetPageViewPositions {
    for (UIView *subView in self.pagingScrollView.subviews) {
        if ([subView isKindOfClass:[IVNodesListPageView class]]) {
            IVNodesListPageView *pageView = (IVNodesListPageView *)subView;
            pageView.frame = [self frameForPageAtIndex:0];
        }
    }
}

- (IVNodesListPageView *)bringPageViewToFrontWithNodeID:(NSString *)nodeID {
    for (UIView *subView in self.pagingScrollView.subviews) {
        if ([subView isKindOfClass:[IVNodesListPageView class]]) {
            IVNodesListPageView *pageView = (IVNodesListPageView *)subView;
            if ([pageView.nodeID isEqualToString:nodeID]) {
                [self.pagingScrollView bringSubviewToFront:pageView];
                return pageView;
            }
        }
    }
    return nil;
}

@end

#pragma mark -

typedef NS_ENUM (NSInteger, IVNodesListPosition) {
    IVNodesListPositionAll = 0,
    IVNodesListPositionBar,
    IVNodesListPositionHidden
};

@interface IVPanoramaNodesListView ()

@property (nonatomic,weak) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (nonatomic,weak) IBOutlet UILabel *pageNameLabel;
@property (nonatomic,weak) IBOutlet UIView *handleView;
@property (nonatomic,weak) IBOutlet UIButton *toggleButton1,*toggleButton2;

@end

@implementation IVPanoramaNodesListView {
    BOOL _isPageScrollViewHidden;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    // UI
    self.listInsets = UIEdgeInsetsMake(0, 0, 26, 0);
    
    // Notifications
    IVPanoramaNodesListView *__weak weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kNodeSelectionDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      NSString *selectedNodeID = [note object];
                                                      [weakSelf updateNodeInfoWithNodeID:selectedNodeID];
                                                      [weakSelf updateSelectionStatus];
                                                      [weakSelf updateNodesListOffsetWithNodeID:selectedNodeID];
                                                  }];
    
    // Gestures
    UISwipeGestureRecognizer *swipeUpListGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(animateUnfoldPageScrollView)];
    swipeUpListGesture.direction = UISwipeGestureRecognizerDirectionUp;
    swipeUpListGesture.numberOfTouchesRequired = 1;
    [_handleView addGestureRecognizer:swipeUpListGesture];
    
    UISwipeGestureRecognizer *swipeDownListGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(animateFoldPageScrollView)];
    swipeDownListGesture.direction = UISwipeGestureRecognizerDirectionDown;
    swipeDownListGesture.numberOfTouchesRequired = 1;
    [_handleView addGestureRecognizer:swipeDownListGesture];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (CGRectContainsPoint(_toggleButton1.frame, point)) {
        return _toggleButton1;
    }
    else if (CGRectContainsPoint(_toggleButton2.frame, point)) {
        return _toggleButton2;
    }
    else if (CGRectContainsPoint(_handleView.frame, point)) {
        return _handleView;
    }
	
	return [super hitTest:point	withEvent:event];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateNodesListOffsetWithNodeID:[(IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument currentNodeID]];
}

#pragma mark - Show/Hide nodes list view

- (void)updatePosition:(IVNodesListPosition)position {
    switch (position) {
        case IVNodesListPositionAll:
            _bottomConstraint.constant = 0;
            break;
        case IVNodesListPositionBar:
            _bottomConstraint.constant = -[self pageHeight];
            break;
        case IVNodesListPositionHidden:
            _bottomConstraint.constant = -CGRectGetHeight(self.frame);
            break;
        default:
            break;
    }
    [self.superview setNeedsLayout];
    [self.superview layoutIfNeeded];
}

- (void)setPageScrollViewPosition {
	if (DefaultsGet(bool,kShowNodesListView)) {
        [self updatePosition:IVNodesListPositionAll];
	}
    else {
        [self updatePosition:IVNodesListPositionBar];
	}
}

// Show when entering panorama view.
- (void)animateShowPageScrollView:(void(^)(BOOL finished))completionHandler {
    _isPageScrollViewHidden = NO;
    [UIView animateWithDuration:(CGFloat)UINavigationControllerHideShowBarDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self setPageScrollViewPosition];
                     } completion:completionHandler];
}

- (void)hidePageScrollView {
    [self updatePosition:IVNodesListPositionHidden];
}

// Hide when leaving panorama view.
- (void)animateHidePageScrollView:(void(^)(BOOL finished))completionHandler {
    _isPageScrollViewHidden = YES;
    [UIView animateWithDuration:(CGFloat)UINavigationControllerHideShowBarDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self hidePageScrollView];
                     } completion:completionHandler];
}

- (IBAction)togglePageScrollView:(id)sender {
    if (!_isPageScrollViewHidden) {
        DefaultsSet(Bool,kShowNodesListView,!DefaultsGet(bool,kShowNodesListView));
        [self animateShowPageScrollView:nil];
    }
}

- (void)animateUnfoldPageScrollView {
    if (!_isPageScrollViewHidden) {
        DefaultsSet(Bool,kShowNodesListView,YES);
        [self animateShowPageScrollView:nil];
    }
}

- (void)animateFoldPageScrollView {
    if (!_isPageScrollViewHidden) {
        DefaultsSet(Bool,kShowNodesListView,NO);
        [self animateShowPageScrollView:nil];
    }
}

#pragma mark - Node position and status

- (void)updateNodeInfoWithNodeID:(NSString *)selectedNodeID {
	IVPanoramaNode *node = [(IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument nodeWithNodeID:selectedNodeID];
	_pageNameLabel.text = [node localizedName];
}

- (void)updateNodesListOffsetWithNodeID:(NSString *)selectedNodeID {
	NSUInteger pageIndex = [(IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument indexOfNodeID:selectedNodeID];
	if (pageIndex != NSNotFound) {
		if (self.pagingScrollView.frame.size.width < self.pagingScrollView.contentSize.width) {
			[self.pagingScrollView scrollRectToVisible:CGRectMake([self pageWidth] * pageIndex - CGFloor(self.pagingScrollView.bounds.size.width - [self pageWidth]) / 2.0f, 0, self.pagingScrollView.bounds.size.width, self.pagingScrollView.bounds.size.height) animated:YES];
		}
		else {
			self.pagingScrollView.contentOffset = CGPointMake(-CGFloor((self.pagingScrollView.frame.size.width - self.pagingScrollView.contentSize.width)/2.0f), 0);
		}
	}
}

- (void)updateAllPages {
    [super updateAllPages];
    [self updateNodesListOffsetWithNodeID:[(IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument currentNodeID]];
}

@end
