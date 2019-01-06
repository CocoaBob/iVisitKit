//
//  IVMapViews.h
//  iVisit 3D
//
//  Created by Bob on 03/07/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVHeaders.h"

@class IVMapScrollView;

@interface IVMapCircleView : UIView
@end

#pragma mark - 

@interface IVMapPinView : UIImageView
@end

#pragma mark - 

@interface IVMapView : UIImageView
@end

#pragma mark - 

@interface IVMapCoverView : UIView

- (void)updatePositions;
- (void)removeAllPinViews;

@end

#pragma mark - 

@interface IVMapPageView : UIView

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) IVMapView *mapView;
@property (nonatomic, strong) IVMapCoverView *mapCoverView;
@property (nonatomic, strong) IVMapScrollView *mapScrollView;

- (void)updateCoverViewPinColor;
- (void)cleanEnvironment;

@end

#pragma mark - 

@interface IVMapScrollView : UIScrollView

@property (nonatomic, assign) BOOL didDoubleTapToZoom;
@property (nonatomic, weak) IVMapPageView *mapPageView;

- (void)loadMapAtIndex;
- (void)resetZoomScales;

- (CGPoint)pointToCenterAfterRotation;
- (CGFloat)scaleToRestoreAfterRotation;
- (void)restoreCenterPoint:(CGPoint)oldCenter scale:(CGFloat)oldScale animated:(BOOL)animated;

@end
