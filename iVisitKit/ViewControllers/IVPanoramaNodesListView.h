//
//  IVPanoramaNodesListView.h
//  iVisit 3D
//
//  Created by Bob on 03/07/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVHeaders.h"

@interface IVNodesListPageView : UIView

@property (nonatomic, assign) BOOL backgroundEnabled;
@property (nonatomic, strong) NSString *nodeID;
@property (nonatomic, assign, getter=isSelected) BOOL selected;

- (void)loadNode:(BOOL)isFromSameNode;

- (void)showBackgroundLayers;
- (void)hideBackgroundLayers;

@end

#pragma mark -

@class IVPanoramaNode;

@interface IVNodeVersionsView : UIView

@property (nonatomic, weak) IVNodesListPageView *sourcePageView;

+ (void)presentWithNode:(IVPanoramaNode *)node fromPageView:(IVNodesListPageView *)pageView;

@end

#pragma mark -

@protocol IVNodesListViewDelegate <NSObject>

- (NSUInteger)numberOfNodes;
- (NSString *)nodeIDAtIndex:(NSUInteger)nodeIndex;
- (NSUInteger)indexOfNodeID:(NSString *)nodeID;
- (BOOL)shouldDisplayPageViewBackground;
- (BOOL)isSelected:(NSString *)nodeID;
- (void)didSelectPageView:(IVNodesListPageView *)pageView;
- (void)didLongSelectPageView:(IVNodesListPageView *)pageView;

@end

@interface IVNodesListBaseView : UIView

@property (nonatomic, weak) IBOutlet id<IVNodesListViewDelegate> delegate;

@property (nonatomic, strong) UIScrollView *pagingScrollView;
@property (nonatomic, assign) BOOL isVertical;
@property (nonatomic, assign) BOOL alwaysBounce;
@property (nonatomic, assign) UIEdgeInsets listInsets;

- (void)tilePages;
- (void)removeAllPageViews;
- (void)updateAllPages;

- (void)didSelectPageView:(IVNodesListPageView *)pageView;
- (void)didLongSelectPageView:(IVNodesListPageView *)pageView;

- (void)updateContentSizeForPagingScrollView;

- (void)cleanEnvironment;

@end

#pragma mark -

@interface IVVersionedNodesListView : IVNodesListBaseView

- (void)resetPageViewPositions;
- (IVNodesListPageView *)bringPageViewToFrontWithNodeID:(NSString *)nodeID;

@end

#pragma mark -

@interface IVPanoramaNodesListView : IVNodesListBaseView

- (void)hidePageScrollView;
- (void)animateShowPageScrollView:(void(^)(BOOL finished))completionHandler;
- (void)animateHidePageScrollView:(void(^)(BOOL finished))completionHandler;

- (void)updateNodesListOffsetWithNodeID:(NSString *)selectedNodeID;

- (void)setupToggleButtons;
- (void)updateSafeAreaBottom;

@end
