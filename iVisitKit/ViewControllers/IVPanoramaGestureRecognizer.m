//
//  IVPanoramaGestureRecognizer.m
//  iVisit360
//
//  Created by CocoaBob on 28/05/15.
//  Copyright (c) 2015 Abvent R&D. All rights reserved.
//

#import "IVPanoramaGestureRecognizer.h"

#import <UIKit/UIGestureRecognizerSubclass.h>
#import "IVHeaders.h"

#define kFPS 60.0
#define kSpeedMax 40.0
#define kPanAnimationDuration 0.8 //in second
#define kInvalidPinchDistance -1
#define kPinchAnimationFrames 10
#define kMaxFOV 80
#define kMinFOV 40

#define kStartSpeedX @"kStartSpeedX"
#define kStartSpeedY @"kStartSpeedY"

@interface IVPanoramaGestureRecognizer ()

@property (nonatomic, assign) UIGestureRecognizerState realState;

@end

@implementation IVPanoramaGestureRecognizer {
    NSTimer *timeOutTimer;
    
    CGPoint beginPosition;
    CGPoint lastTouchesCenter;
    NSInteger lastTouchesCount;
    NSTimeInterval lastTouchTimestamp;
    NSTimeInterval lastTwoTouchesTimeInterval;
    CGFloat lastTwoTouchesOffsetX;
    CGFloat lastTwoTouchesOffsetY;
    
    NSTimer *panAnimationTimer;
    CGFloat panAnimationTimeElapse;
    
    NSTimer *pinchAnimationTimer;
    NSInteger pinchAnimationFramesCount;
    CGFloat pinchAnimationStepDelta;
    CGFloat lastPinchDistance;
}

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    if (self = [super initWithTarget:target action:action]) {
        lastPinchDistance = kInvalidPinchDistance;
    }
    return self;
}

#pragma mark - Override

- (void)setRealState:(UIGestureRecognizerState)realState {
    _realState = realState;
    self.state = realState;
    
    // Reset to possible
    if (realState == UIGestureRecognizerStateFailed ||
        realState == UIGestureRecognizerStateEnded ||
        realState == UIGestureRecognizerStateCancelled) {
        _realState = UIGestureRecognizerStatePossible;
    }
}

- (void)setState:(UIGestureRecognizerState)state {
    if (state == _realState) {
        [super setState:state];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    [self stopTimeoutTimer];
    
    [self stopPanAnimation];
    
    lastTouchTimestamp = event.timestamp;
    
    [self resetPinchDistance];
    
    NSSet *allTouches = [event allTouches];
    if (allTouches) {
        switch (allTouches.count) {
            case 1:
                lastTouchesCenter = beginPosition = [[allTouches anyObject] locationInView:self.view];
                break;
            case 2:
                [self calculateCenterWithTouches:allTouches :&lastTouchesCenter :&lastPinchDistance];
                break;
            default:
                self.realState = UIGestureRecognizerStateFailed;
                break;
        }
        lastTouchesCount = allTouches.count;
    }
    else {
        lastTouchesCount = 0;
        self.realState = UIGestureRecognizerStateFailed;
    }
    
    if (self.realState == UIGestureRecognizerStatePossible) {
        [self startTimeoutTimer];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    [self stopTimeoutTimer];
    
    [self stopPanAnimation];
    lastTouchTimestamp = event.timestamp;
    
    NSSet *allTouches = [event allTouches];
    if (allTouches) {
        if (lastTouchesCount != allTouches.count) {
            [self resetPinchDistance];
            [self resetTouchesCenter];
        }
        
        switch (allTouches.count) {
            case 1:
            {
                NSSet *allTouches = [event allTouches];
                UITouch *touch = [allTouches anyObject];
                CGPoint currentPosition = [touch locationInView:self.view];
                CGFloat distancePower = pow(currentPosition.x - beginPosition.x, 2) + pow(currentPosition.y - beginPosition.y, 2);
                if (distancePower > 25) {
                    [self resetPinchDistance];
                    CGPoint currentTouchCenter = [[allTouches anyObject] locationInView:self.view];
                    [self handlePan:currentTouchCenter];
                    
                    if (self.realState == UIGestureRecognizerStatePossible) {
                        self.realState = UIGestureRecognizerStateBegan;
                    }
                }
                break;
            }
            case 2:
            {
                CGPoint currentTouchCenter;
                CGFloat currPinchDistance;
                [self calculateCenterWithTouches:allTouches :&currentTouchCenter :&currPinchDistance];
                [self handlePan:currentTouchCenter];
                [self handlePinch:currPinchDistance];
                
                if (self.realState == UIGestureRecognizerStatePossible) {
                    self.realState = UIGestureRecognizerStateBegan;
                }
                break;
            }
            default:
            {
                break;
            }
        }
        
        lastTouchesCount = allTouches.count;
    }
    else {
        self.realState = UIGestureRecognizerStateFailed;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    if (touches.count > 2 || touch.tapCount > 2) {
        self.realState = UIGestureRecognizerStateFailed;
        return;
    }
    
    [self touchesFinished:touches withEvent:event];
    
    if (self.realState == UIGestureRecognizerStatePossible ||
        self.realState == UIGestureRecognizerStateBegan ||
        self.realState == UIGestureRecognizerStateChanged) {
        // Do nothing
    } else {
        self.realState = UIGestureRecognizerStateFailed;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    
    [self touchesFinished:touches withEvent:event];
    
    [self stopTimeoutTimer];
    
    self.realState = UIGestureRecognizerStateCancelled;
}

#pragma mark - Touches

- (void)touchesFinished:(NSSet *)touches withEvent:(UIEvent *)event {
    NSSet *allTouches = [event allTouches];
    if (allTouches) {
        UITouch *touch = [allTouches anyObject];
        // Double tap to zoom
        if (allTouches.count == 1 && touch.tapCount == 2 && !panAnimationTimer) {
            CGFloat lastFOV = 0;
            if (self.panoramaDelegate && [self.panoramaDelegate respondsToSelector:@selector(fovForPanoramaGestureRecognizer:)]) {
                lastFOV = [self.panoramaDelegate fovForPanoramaGestureRecognizer:self];
            }
            
            if ((lastFOV - kMinFOV) > 10) { //Zoom In
                pinchAnimationStepDelta = (kMinFOV - lastFOV) / kPinchAnimationFrames; //Zoom In
            }
            else { //Zoom Out
                pinchAnimationStepDelta = (kMaxFOV - lastFOV) / kPinchAnimationFrames; //Zoom Out
            }
            
            [self startPinchAimation];
            
            self.realState = UIGestureRecognizerStateChanged;
        }
        else if (allTouches.count == 1) {
            // Decelerate animation
            if (self.realState == UIGestureRecognizerStateChanged) {
                lastTwoTouchesTimeInterval = event.timestamp - lastTouchTimestamp;
                if (lastTwoTouchesTimeInterval > 0 &&
                    (lastTwoTouchesOffsetX != 0 || lastTwoTouchesOffsetY != 0)) {
                    [self startPanAnimation];
                }
            }
            if (!panAnimationTimer) {
                [self startTimeoutTimer];
            }
        }
        else {
            self.realState = UIGestureRecognizerStateEnded;
        }
    }
    
    //Pan & Pinch
    [self resetPinchDistance];
    [self resetTouchesCenter];
}

#pragma mark - Timeout timer

- (void)startTimeoutTimer {
    timeOutTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(handleTimeOut) userInfo:nil repeats:NO];
}

- (void)stopTimeoutTimer {
    if (timeOutTimer) {
        [timeOutTimer invalidate];
        timeOutTimer = nil;
    }
}

- (void)handleTimeOut {
    [self stopTimeoutTimer];
    if (self.realState == UIGestureRecognizerStatePossible ||
        self.realState == UIGestureRecognizerStateBegan) {
        self.realState = UIGestureRecognizerStateFailed;
    }
    else {
        self.realState = UIGestureRecognizerStateEnded;
    }
}

#pragma mark - Pinch Animation

- (void)animatePinch {
    if (pinchAnimationFramesCount <= 0) {
        [self stopPinchAimation];
        self.realState = UIGestureRecognizerStateEnded;
    }
    else {
        [self didChangeFOV:pinchAnimationStepDelta];
    }
    pinchAnimationFramesCount -= 1;
}

- (void)startPinchAimation {
    [self stopTimeoutTimer];
    if (!pinchAnimationTimer) {
        pinchAnimationFramesCount = kPinchAnimationFrames;
        pinchAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:1/kFPS target:self selector:@selector(animatePinch) userInfo:nil repeats:YES];
    }
}

- (void)stopPinchAimation {
    if (pinchAnimationTimer) {
        [pinchAnimationTimer invalidate];
        pinchAnimationTimer = nil;
    }
}

- (void)handlePinch:(CGFloat)currPinchDistance {
    if (lastPinchDistance == kInvalidPinchDistance) {
        lastPinchDistance = currPinchDistance;
    }
    else {
        CGFloat pinchDistanceDelta = currPinchDistance - lastPinchDistance;
        lastPinchDistance = currPinchDistance;
        [self didChangeFOV:-pinchDistanceDelta / 5.0];
    }
}

#pragma mark - Pan Animation

- (CGFloat)calculateCurrentVelocity:(CGFloat)beginVelocity :(CGFloat)elapsedTime {
    CGFloat normalizedTimeElapse = beginVelocity * ((kPanAnimationDuration - elapsedTime) / kPanAnimationDuration);
    CGFloat tempSpeedSquare = powf(beginVelocity, 2) - powf(normalizedTimeElapse, 2);
    CGFloat tempSpeed = sqrtf((tempSpeedSquare <= 0) ? 0 : tempSpeedSquare);
    tempSpeed = (beginVelocity < 0) ? -tempSpeed : tempSpeed;
    tempSpeed = beginVelocity - tempSpeed;
    CGFloat result = (tempSpeed * beginVelocity <= 0) ? 0 : tempSpeed;
    return result;
}

- (void)calculatePanAnimationSpeed:(CGFloat)panAnimationStartSpeedX :(CGFloat)panAnimationStartSpeedY :(CGFloat *)oSpeedX :(CGFloat *)oSpeedY {
    *oSpeedX = [self calculateCurrentVelocity:panAnimationStartSpeedX :panAnimationTimeElapse];
    *oSpeedY = [self calculateCurrentVelocity:panAnimationStartSpeedY :panAnimationTimeElapse];
}

- (void)animatePan:(NSTimer *)timer {
    panAnimationTimeElapse += 1 / (kFPS * kPanAnimationDuration);
    if (panAnimationTimeElapse >= kPanAnimationDuration) {//mSpeedX == 0 && mSpeedY == 0
        [self stopPanAnimation];
        self.realState = UIGestureRecognizerStateEnded;
        return;
    }
    
    NSDictionary *userInfo = timer.userInfo;
    if (userInfo) {
        CGFloat panAnimationStartSpeedX = [userInfo[kStartSpeedX] doubleValue];
        CGFloat panAnimationStartSpeedY = [userInfo[kStartSpeedY] doubleValue];
        
        CGFloat panAnimationCurrentSpeedX,panAnimationCurrentSpeedY;
        [self calculatePanAnimationSpeed:panAnimationStartSpeedX :panAnimationStartSpeedY :&panAnimationCurrentSpeedX :&panAnimationCurrentSpeedY];
        
        [self didChangeXY:panAnimationCurrentSpeedX / kFPS :panAnimationCurrentSpeedY / kFPS];
    }
}

//We only need the start speed of X and Y to start the pan animation
- (void)startPanAnimation {
    [self stopTimeoutTimer];
    if (panAnimationTimer == nil) {
        CGFloat panAnimationStartSpeedX = lastTwoTouchesOffsetX / lastTwoTouchesTimeInterval;
        CGFloat panAnimationStartSpeedY = lastTwoTouchesOffsetY / lastTwoTouchesTimeInterval;
        if (fabs(panAnimationStartSpeedX) > kSpeedMax) {
            panAnimationStartSpeedX = (panAnimationStartSpeedX < 0) ? -kSpeedMax : kSpeedMax;
        }
        if (fabs(panAnimationStartSpeedY) > kSpeedMax) {
            panAnimationStartSpeedY = (panAnimationStartSpeedY < 0) ? -kSpeedMax : kSpeedMax;
        }
        
        panAnimationTimeElapse = 1 / (kFPS * kPanAnimationDuration);
        
        if (fabs(panAnimationStartSpeedX) > 0.05 || fabs(panAnimationStartSpeedY) > 0.05) {
            panAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:1/kFPS
                                                                 target:self
                                                               selector:@selector(animatePan:)
                                                               userInfo:@{kStartSpeedX:@(panAnimationStartSpeedX),
                                                                          kStartSpeedY:@(panAnimationStartSpeedY)}
                                                                repeats:YES];
        }
        else {
            self.realState = UIGestureRecognizerStateFailed;
        }
    }
}

- (void)stopPanAnimation {
    if (panAnimationTimer != nil) {
        [panAnimationTimer invalidate];
        panAnimationTimer = nil;
        lastTwoTouchesOffsetX = 0;
        lastTwoTouchesOffsetY = 0;
    }
}

#pragma mark - Pinch & Pan

- (void)resetPinchDistance {
    lastPinchDistance = kInvalidPinchDistance;
}

- (void)resetTouchesCenter {
    lastTouchesCenter = CGPointZero;
}

- (void)calculateCenterWithTouches:(NSSet *)allTouches :(CGPoint *)oTouchCenter :(CGFloat *)oPinchDistance {
    if (allTouches.count < 2) {
        return;
    }
    
    NSArray *touchesArray = [allTouches allObjects];
    UITouch *t1 = touchesArray[0];
    UITouch *t2 = touchesArray[1];
    
    CGPoint p1 = [t1 locationInView:self.view];
    CGPoint p2 = [t2 locationInView:self.view];
    
    CGFloat dx = p2.x - p1.x;
    CGFloat dy = p2.y - p1.y;
    
    *oTouchCenter = CGPointMake(p1.x + dx / 2.0, p1.y + dy / 2.0);
    
    *oPinchDistance = sqrt(pow(dx, 2) + pow(dy, 2));
}

- (void)handlePan:(CGPoint)currentTouchCenter {
    if (CGPointEqualToPoint(lastTouchesCenter, CGPointZero)) {
        lastTouchesCenter = currentTouchCenter;
    }
    else {
        CGFloat fovInRadian = 0;
        if (self.panoramaDelegate && [self.panoramaDelegate respondsToSelector:@selector(fovForPanoramaGestureRecognizer:)]) {
            fovInRadian = deg2rad([self.panoramaDelegate fovForPanoramaGestureRecognizer:self]);
        }
        
//        CGFloat scale = [UIScreen mainScreen].scale;
        CGFloat semiViewWidth = CGRectGetWidth(self.view.frame) / 2.0;
        CGFloat semiViewHeight = CGRectGetHeight(self.view.frame) / 2.0;
        
        // The FOV is the fov of the longer side, so we have to use the longer side to calculate the distance
        CGFloat distanceFromCameraToScreen = ((semiViewWidth > semiViewHeight)?semiViewWidth:semiViewHeight) / tan(fovInRadian / 2.0);
        
        CGFloat angleFromTouchPointOneToScreenCenterX = atan((lastTouchesCenter.x - semiViewWidth) / distanceFromCameraToScreen);
        CGFloat angleFromTouchPointTwoToScreenCenterX = atan((currentTouchCenter.x - semiViewWidth) / distanceFromCameraToScreen);
        
        CGFloat angleFromTouchPointOneToScreenCenterY = atan((lastTouchesCenter.y - semiViewHeight) / distanceFromCameraToScreen);
        CGFloat angleFromTouchPointTwoToScreenCenterY = atan((currentTouchCenter.y - semiViewHeight) / distanceFromCameraToScreen);

        lastTouchesCenter = currentTouchCenter;
        
        lastTwoTouchesOffsetX = (angleFromTouchPointTwoToScreenCenterX - angleFromTouchPointOneToScreenCenterX);
        lastTwoTouchesOffsetY = (angleFromTouchPointTwoToScreenCenterY - angleFromTouchPointOneToScreenCenterY);
        
        [self didChangeXY:lastTwoTouchesOffsetX :lastTwoTouchesOffsetY];
    }
}

#pragma mark - Inform Gesture Recognizer's view

- (void)didChangeFOV:(CGFloat)inDeltaFOV {
    _deltaFOV = inDeltaFOV;
    self.realState = UIGestureRecognizerStateChanged;
}

- (void)didChangeXY:(CGFloat)inDeltaX :(CGFloat)inDeltaY {
    _deltaX = inDeltaX;
    _deltaY = inDeltaY;
    self.realState = UIGestureRecognizerStateChanged;
}

@end
