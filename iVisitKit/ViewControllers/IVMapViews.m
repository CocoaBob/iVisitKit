//
//  IVMapViews.m
//  iVisit 3D
//
//  Created by Bob on 03/07/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVMapViews.h"

#define SCALE_MAX_IPAD 30.0f
#define SCALE_MAX_IPHONE 18.0f
#define SCALE_MIN 0.0f
#define SCALE_STEP 1.0f/120.0f

@implementation IVMapCircleView {
	float scale;
	float scaleMax;
    BOOL isAnimating;
	NSTimer *refreshTimer;
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.autoresizingMask = UIViewAutoresizingNone;
		self.backgroundColor = [UIColor clearColor];
		
		scaleMax = ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?SCALE_MAX_IPAD:SCALE_MAX_IPHONE);
		scale = scaleMax;
		
		isAnimating = NO;
		
	}
	return self;
}

- (void)startAnimation {
	if (!refreshTimer) {
		isAnimating = YES;
		refreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.016667 target:self selector:@selector(performAnimation) userInfo:nil repeats:YES];
	}
}

- (void)performAnimation {
	scale -= SCALE_STEP * scaleMax;
	if (scale <= SCALE_MIN) {
		scale = scaleMax;
		self.alpha = 1.0f;
	}
	
	if (scale < scaleMax / 3.0f) {
		self.alpha -= 0.05f;
	}
    
	[self setNeedsDisplay];
}

- (void)stopAnimation {
	if (refreshTimer) {
		isAnimating = NO;
		[refreshTimer invalidate];
		refreshTimer = nil;
	}
}

- (void)drawRect:(CGRect)rect {
	if (isAnimating) {
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(rect, scale, scale)];
        [path setLineWidth:1.0f];
        [[UIColor redColor] setStroke];
        [path stroke];
	}
}

@end


@interface IVMapPinView ()

@property (nonatomic, assign) Coordinate3D pinCoord;
@property (nonatomic,strong) NSString *nodeID;
@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) UILabel *titleLabel;

@end

#define PIN_TITLE_FONT_SIZE ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?24:18)
#define PIN_ICON_SIZE ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?24:24)

@implementation IVMapPinView {
	BOOL isSelected;
	IVMapCircleView* cView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		self.autoresizingMask = UIViewAutoresizingNone;
        self.backgroundColor = [UIColor clearColor];
				
		_titleLabel = [[UILabel alloc] init];
		_titleLabel.textAlignment = NSTextAlignmentCenter;
		_titleLabel.backgroundColor = [UIColor clearColor];
		_titleLabel.textColor = [UIColor whiteColor];
		_titleLabel.shadowColor = [UIColor blackColor];
		_titleLabel.shadowOffset = CGSizeMake(1, 1);
        _titleLabel.font = [UIFont boldSystemFontOfSize:PIN_TITLE_FONT_SIZE];
		
		[self addSubview:_titleLabel];
		
		if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
			cView = [[IVMapCircleView alloc] initWithFrame:CGRectInset(self.frame, -20.0f, -20.0f)];
		}
		else {
			
			cView = [[IVMapCircleView alloc] initWithFrame:CGRectInset(self.frame, -12.0f, -12.0f)];
		}
		
		[self addSubview:cView];
    }
    return self;
}

- (void)dealloc {
	[cView stopAnimation];
}

- (CGPoint)anchorOffset {
	return CGPointMake(0, ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?-13:-6));//TopLeft is 0,0 BottomRight is 1,1
}

- (UIImage *)nodeImage {
	isSelected = [self.nodeID isEqualToString:[(IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument currentNodeID]];
	if (isSelected) {
		[[self superview] bringSubviewToFront:self];
		[cView startAnimation];
		
		return [[IVImageManager shared] imageForSelectedMapNode];
	}
	else {
		[cView stopAnimation];
		return [[IVImageManager shared] imageForMapNode];
	}
}

- (void)updateImage {
	self.image = [self nodeImage];
}

- (void)setPosition:(CGPoint)newValue {
	self.center = CGPointMake(CGFloor(newValue.x + [self anchorOffset].x), CGFloor(newValue.y + [self anchorOffset].y));
	CGRect selfFrame = self.frame;
	self.frame = CGRectMake(CGFloor(selfFrame.origin.x), CGFloor(selfFrame.origin.y), CGCeil(selfFrame.size.width), CGCeil(selfFrame.size.height));
}

- (void)setTitle:(NSString *)newValue {
	self.titleLabel.text = newValue;
    CGSize textSize = [self.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:PIN_TITLE_FONT_SIZE]}];
	textSize.width += 20;
	self.titleLabel.frame = CGRectMake(CGFloor(self.center.x - textSize.width / 2.0f),  - textSize.height - 2, textSize.width, textSize.height);
}

- (void)setNodeID:(NSString *)newValue {
	_nodeID = newValue;
	[self updateImage];
}

- (void)updateColor:(NSString *)newNodeID {
	if (isSelected != [self.nodeID isEqualToString:newNodeID]) {
		[self updateImage];
		[self setNeedsDisplay];
	}
}

#define ANI_MAX 1.25
#define ANI_MID 1.125
#define ANI_DUR 0.1

- (void)startTapAnimation:(NSString *)pinID {
    if ([pinID isEqualToString:self.nodeID]) {
        [UIView animateWithDuration:ANI_DUR delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.transform = CGAffineTransformMakeScale(ANI_MAX, ANI_MAX);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:ANI_DUR delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.transform = CGAffineTransformMakeScale(1, 1);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:ANI_DUR delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.transform = CGAffineTransformMakeScale(ANI_MID, ANI_MID);
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:ANI_DUR delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                        self.transform = CGAffineTransformMakeScale(1, 1);
                    } completion:^(BOOL finished) {
                        [self startLoadingNode];
                    }];
                }];
            }];
        }];
    }
}

- (void)startLoadingNode {
    [[IVOverlayManager shared] showActivityViewWithCompletionHandler:^{
        IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
        [IVStatusCenter shared].selectedNodeIDOnMap = self.nodeID;
        [[IVPanoramaViewController shared] loadNode:self.nodeID
                                         turnToFace:[curDoc defaultFaceOfNode:[curDoc nodeWithNodeID:self.nodeID]]
                                         completion:^{
                                             [[IVOverlayManager shared] hideActivityView];
                                         }];
        [[UIViewController toppest] dismissSelf];
    }];
}

@end

#pragma mark -

@interface IVMapView ()

@property (nonatomic, weak) IVMapPageView *mapPageView;

@end

@implementation IVMapView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		self.autoresizingMask = UIViewAutoresizingNone;
	}
	return self;
}

- (BOOL)loadMapImage {
	UIImage *mapImage = [(IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument mapImageAtIndex:self.mapPageView.index];
	if (mapImage) {
		self.frame = CGRectMake(0, 0, mapImage.size.width, mapImage.size.height);
		self.image = mapImage;
		return YES;
	}
	else {
		return NO;
	}
}

@end

#pragma mark - 

@interface IVMapCoverView ()

@property (nonatomic, weak) IVMapPageView *mapPageView;

@end

@implementation IVMapCoverView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.userInteractionEnabled = NO;
		self.clipsToBounds = YES;
	}
	return self;
}

- (void)updatePins {
    [self removeAllPinViews];
    
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
	IVPanoramaMap *panoramaMap = [curDoc mapAtIndex:self.mapPageView.index];
	if (panoramaMap) {
		for (IVPanoramaNode *aNode in [panoramaMap correspondingNodes]) {
			int size = PIN_ICON_SIZE;
			IVMapPinView *pinView = [[IVMapPinView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
			pinView.nodeID = [aNode objectForKey:@"id"];
            Coordinate3D coord = (Coordinate3D){0,0,0};
            if (curDoc.type == IVDocTypePanoramaV4 || curDoc.type == IVDocTypePanoramaV5) {
                coord.x = [aNode coordX];
                coord.y = [aNode coordY];
                coord.z = [aNode coordZ];
            } else if (curDoc.type == IVDocTypePanorama360) {
                coord.x = -[aNode coordY];
                coord.y = [aNode coordX];
                coord.z = [aNode coordZ];
            }
			pinView.pinCoord = coord;
			pinView.title = [aNode localizedName];
			[pinView setPosition:CGPointZero];
			[self addSubview:pinView];
		}
	}
}

- (void)updatePositions {
	if (self.mapPageView.mapScrollView.zoomBouncing) {
		[self.mapPageView.mapCoverView hideAllPins];
		return;
	}
	else {
		if (!self.mapPageView.mapScrollView.zoomBouncing && !self.mapPageView.mapScrollView.didDoubleTapToZoom) {
			[self.mapPageView.mapCoverView showAllPins];
		}
	}

    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
	IVPanoramaMap *panoramaMap = [curDoc mapAtIndex:self.mapPageView.index];
	for (IVMapPinView *aPinView in self.subviews) {
		Coordinate3D pinCoord = aPinView.pinCoord;
		CGPoint pinPosition = CGPointMake(self.mapPageView.mapView.bounds.size.width * (pinCoord.x - panoramaMap.xMin) / panoramaMap.xDistance,
										  self.mapPageView.mapView.bounds.size.height * (panoramaMap.yMax - pinCoord.y) / panoramaMap.yDistance);
		CGPoint relativePinPosition = [self.mapPageView.mapView convertPoint:pinPosition toView:self];
		[aPinView setPosition:relativePinPosition];
	}
}

- (void)updateColor:(NSString *)nodeID {
	for (IVMapPinView *aPinView in self.subviews) {
		[aPinView updateColor:nodeID];
	}
}

- (void)startTapAnimationForNodeID:(NSString *)nodeID {
	for (IVMapPinView *aPinView in self.subviews) {
		[aPinView startTapAnimation:nodeID];
	}
}

- (void)hideAllPins {
	for (IVMapPinView *aPinView in self.subviews) {
		[aPinView setHidden:YES];
	}
}

- (void)showAllPins {
	for (IVMapPinView *aPinView in self.subviews) {
		[aPinView setHidden:NO];
	}
}

- (void)removeAllPinViews {
    for (UIView *subView in self.subviews) {
        if ([subView isKindOfClass:[IVMapPinView class]]) {
            [subView removeFromSuperview];
        }
    }
}

@end

#pragma mark - 

@implementation IVMapPageView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
		self.backgroundColor = [UIColor clearColor];
		self.mapScrollView = [[IVMapScrollView alloc] initWithFrame:self.bounds];
		self.mapScrollView.mapPageView = self;
		self.mapView = [[IVMapView alloc] initWithFrame:self.bounds];
		self.mapView.mapPageView = self;
		[self.mapScrollView addSubview:self.mapView];
		[self addSubview:self.mapScrollView];
		self.mapCoverView = [[IVMapCoverView alloc] initWithFrame:self.bounds];
		self.mapCoverView.mapPageView = self;
		[self addSubview:self.mapCoverView];
		self.index = -1;
	}
	return self;
}

- (void)cleanEnvironment {
    @autoreleasepool {
        self.mapView.image = nil;
        [self.mapCoverView removeAllPinViews];
    }
}

- (void)updateCoverViewPinColor {
	[self.mapCoverView updateColor:[(IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument currentNodeID]];
}

@end

#pragma mark - 

@interface IVMapScrollView () <UIScrollViewDelegate>

@end

@implementation IVMapScrollView {
	BOOL isLoadingMap;
	BOOL hasSelectedANode;
    CGFloat minZoomScale,fitZoomScale,maxZoomScale;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.backgroundColor = [UIColor clearColor];
		self.clipsToBounds = YES;
        self.delegate = self;
		self.showsVerticalScrollIndicator = YES;
		self.showsHorizontalScrollIndicator = YES;
        self.indicatorStyle = UIScrollViewIndicatorStyleDefault;
		self.scrollEnabled = YES;
		self.pagingEnabled = NO;
		self.scrollsToTop = NO;
		self.bounces = NO;
		self.alwaysBounceVertical = NO;
		self.alwaysBounceHorizontal = NO;
		self.bouncesZoom = YES;
		self.opaque = YES;
		self.decelerationRate = UIScrollViewDecelerationRateFast;
		
		UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapHandler:)];
		singleTapGestureRecognizer.numberOfTapsRequired = 1;
		singleTapGestureRecognizer.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:singleTapGestureRecognizer];
        
        UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapHandler:)];
        doubleTapGestureRecognizer.numberOfTapsRequired = 2;
        doubleTapGestureRecognizer.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:doubleTapGestureRecognizer];
        [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];

        CBDoubleTapAndPanGestureRecognizer *doubleTapAndPanGestureRecognizer = [[CBDoubleTapAndPanGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAndPanHandler:)];
        [self addGestureRecognizer:doubleTapAndPanGestureRecognizer];
        [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapAndPanGestureRecognizer];
        [doubleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapAndPanGestureRecognizer];

		hasSelectedANode = NO;
    }
    return self;
}

- (void)dealloc {
	[self removeGestureRecognizer:[[self gestureRecognizers] lastObject]];
}

#pragma mark - Override layoutSubviews to center content

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.mapPageView.mapCoverView updatePositions];
}

- (void)setContentOffset:(CGPoint)contentOffset {
    [super setContentOffset:contentOffset];
    [self centerContentView];
}

- (void)centerContentView {
    if ([self.delegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
        UIView *contentView = [self.delegate viewForZoomingInScrollView:self];
        
        CGPoint newCenter;
        newCenter.x = MAX(CGRectGetWidth(contentView.frame), CGRectGetWidth(self.bounds)) / 2.0f;
        newCenter.y = MAX(CGRectGetHeight(contentView.frame), CGRectGetHeight(self.bounds)) / 2.0f;
        contentView.center = newCenter;
    }
}

#pragma mark - UIScrollView delegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.mapPageView.mapView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
	if (self.didDoubleTapToZoom) {
		[self.mapPageView.mapCoverView hideAllPins];
	}
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
	self.didDoubleTapToZoom = NO;
	[self.mapPageView.mapCoverView updatePositions];
	//[self.mapPageView.mapCoverView showAllPins];
}

#pragma mark - Configure scrollView to display new image (tiled or not)

- (void)loadMapAtIndex {
    @autoreleasepool {
        if (!isLoadingMap) {
            isLoadingMap = YES;
            self.zoomScale = 1.0f;// reset our zoomScale to 1.0 before doing any further calculations
            self.mapPageView.mapView.hidden = YES;
            self.mapPageView.mapCoverView.hidden = YES;
            if ([self.mapPageView.mapView loadMapImage]) {
                self.contentSize = self.mapPageView.mapView.frame.size;
                [self resetZoomScales];
                self.zoomScale = fitZoomScale;
                [self.mapPageView.mapCoverView updatePins];
                self.mapPageView.mapView.hidden = NO;
                self.mapPageView.mapCoverView.hidden = NO;
            }
            isLoadingMap = NO;
        }
    }
}

- (void)resetZoomScales {
    CGSize minSize = CGSizeMake(64, 64);
    CGSize fitSize = self.bounds.size;
    CGSize imageSize = self.mapPageView.mapView.bounds.size;

    minZoomScale = MIN(minSize.width / imageSize.width, minSize.height / imageSize.height);
    fitZoomScale = MIN(fitSize.width / imageSize.width, fitSize.height / imageSize.height);
    maxZoomScale = 2.0 / [[UIScreen mainScreen] scale];
    
    // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
    if (minZoomScale > maxZoomScale) {
        minZoomScale = maxZoomScale;
    }
    
    self.maximumZoomScale = maxZoomScale;
    self.minimumZoomScale = minZoomScale;
}

#pragma mark - Methods called during rotation to preserve the zoomScale and the visible portion of the image

// returns the center point, in image coordinate space, to try to restore after rotation.
- (CGPoint)pointToCenterAfterRotation {
    CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    return [self convertPoint:boundsCenter toView:self.mapPageView.mapView];
}

// returns the zoom scale to attempt to restore after rotation.
- (CGFloat)scaleToRestoreAfterRotation {
    CGFloat contentScale = self.zoomScale;
    
    // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
    // allowable scale when the scale is restored.
    if (contentScale <= minZoomScale + FLT_EPSILON)
        contentScale = 0;
    if (contentScale == fitZoomScale)
        contentScale = 0;
    
    return contentScale;
}

- (CGPoint)maximumContentOffset {
    CGSize contentSize = self.contentSize;
    CGSize boundsSize = self.bounds.size;
    return CGPointMake(contentSize.width - boundsSize.width, contentSize.height - boundsSize.height);
}

- (CGPoint)minimumContentOffset {
    return CGPointZero;
}

// Adjusts content offset and scale to try to preserve the old zoomscale and center.
- (void)restoreCenterPoint:(CGPoint)oldCenter scale:(CGFloat)oldScale animated:(BOOL)animated {
    // Step 1: restore zoom scale, first making sure it is within the allowable range.
    self.zoomScale = MIN(maxZoomScale, MAX(fitZoomScale, oldScale));
    
    // Step 2: restore center point, first making sure it is within the allowable range.
    
    // 2a: convert our desired center point back to our own coordinate space
    CGPoint boundsCenter = [self convertPoint:oldCenter fromView:self.mapPageView.mapView];
    // 2b: calculate the content offset that would yield that center point
    CGPoint offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0,
                                 boundsCenter.y - self.bounds.size.height / 2.0);
    // 2c: restore offset, adjusted to be within the allowable range
    CGPoint maxOffset = [self maximumContentOffset];
    CGPoint minOffset = [self minimumContentOffset];
    offset.x = MAX(minOffset.x, MIN(maxOffset.x, offset.x));
    offset.y = MAX(minOffset.y, MIN(maxOffset.y, offset.y));
    [self setContentOffset:offset animated:animated];
}

#pragma mark - Routines

- (void)singleTapHandler:(UITapGestureRecognizer *)gestureRecognizer {
	CGPoint touchLocation = [gestureRecognizer locationInView:self.mapPageView.mapView];
	IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
	IVPanoramaMap *panoramaMap = [curDoc mapAtIndex:self.mapPageView.index];
	CGPoint relativeLocationInMap = CGPointMake((touchLocation.x * panoramaMap.xDistance / self.mapPageView.mapView.bounds.size.width) + panoramaMap.xMin,
												panoramaMap.yMax - (touchLocation.y * panoramaMap.yDistance / self.mapPageView.mapView.bounds.size.height));
	static const int radiusInPixel = 24;//(<- 18 ->NodeCenter<- 18 ->)
	unsigned int touchAreaRadius = ((radiusInPixel * 2 / [[UIScreen mainScreen] scale]) / self.zoomScale) * panoramaMap.xDistance / self.mapPageView.mapView.bounds.size.width;
	unsigned int touchAreaRadiusSquare = pow(touchAreaRadius, 2);
	unsigned int closestDistanceSquare = touchAreaRadiusSquare;
	NSString *closestNodeID = nil;
	for (IVPanoramaNode *aNode in [panoramaMap correspondingNodes]) {
        CGFloat nodeCoordX = 0, nodeCoordY = 0;
        if (curDoc.type == IVDocTypePanoramaV4 || curDoc.type == IVDocTypePanoramaV5) {
            nodeCoordX = [aNode coordX];
            nodeCoordY = [aNode coordY];
        } else if (curDoc.type == IVDocTypePanorama360) {
            nodeCoordX = -[aNode coordY];
            nodeCoordY = [aNode coordX];
        }
		unsigned int dX = CGAbs(relativeLocationInMap.x - nodeCoordX);
		unsigned int dY = CGAbs(relativeLocationInMap.y - nodeCoordY);
		
		if (dX > touchAreaRadius || dY > touchAreaRadius )
			continue;
		
		unsigned int distanceSquare = pow(dX, 2) + pow(dY, 2);
		
		if (distanceSquare <= touchAreaRadiusSquare) {
			if (distanceSquare < closestDistanceSquare) {
				closestDistanceSquare = distanceSquare;
				closestNodeID = [aNode objectForKey:@"id"];
			}
		}
	}
    
	if (closestNodeID && !hasSelectedANode && ![closestNodeID isEqualToString:curDoc.currentNodeID]) {
		hasSelectedANode = YES;
		[[[self mapPageView] mapCoverView] startTapAnimationForNodeID:closestNodeID];
		[self.mapPageView.mapCoverView updateColor:closestNodeID];
	}
    else {
        [[IVMapViewController shared] toggleFullScreen];
    }
}

- (void)doubleTapHandler:(UITapGestureRecognizer *)gestureRecognizer {
	self.didDoubleTapToZoom = YES;
	CGPoint tapLocation = [gestureRecognizer locationInView:self.mapPageView.mapView];
	if (self.zoomScale >= 1/[[UIScreen mainScreen] scale]) {
        [self setZoomScale:(self.zoomScale == fitZoomScale)?1:fitZoomScale animated:YES];
	}
	else {
		CGRect zoomRect = self.bounds;
		zoomRect.size.width *= [[UIScreen mainScreen] scale];
		zoomRect.size.height *= [[UIScreen mainScreen] scale];
		zoomRect.origin.x = tapLocation.x - (zoomRect.size.width / 2.0f);
		zoomRect.origin.y = tapLocation.y - (zoomRect.size.height / 2.0f);
		[self zoomToRect:zoomRect animated:YES];
	}
}

- (void)doubleTapAndPanHandler:(id)sender {
    CBDoubleTapAndPanGestureRecognizer *gesture = sender;
    if (gesture.state == UIGestureRecognizerStateChanged) {
        self.zoomScale *= gesture.scale;
    }
}

@end
