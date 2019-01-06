//
//  IVPanoramaNodeTapGestureRecognizer.m
//  iVisit360
//
//  Created by CocoaBob on 05/06/15.
//  Copyright (c) 2015 Abvent R&D. All rights reserved.
//

#import "IVPanoramaHitTestGestureRecognizer.h"

#import <UIKit/UIGestureRecognizerSubclass.h>

@interface IVPanoramaHitTestGestureRecognizer ()

@property (nonatomic, assign) CGPoint beginPosition;

@end

@implementation IVPanoramaHitTestGestureRecognizer {
    NSTimer *_waitingTimer;
    BOOL _isTouchEnded;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    NSSet *allTouches = [event allTouches];
    UITouch *touch = [allTouches anyObject];
    if (self.state != UIGestureRecognizerStatePossible ||
        allTouches.count != 1 ||
        touch.tapCount != 1 ||
        ![self.hitTestDelegate respondsToSelector:@selector(gestureRecognizer:hitTest:inView:)]) {
        self.state = UIGestureRecognizerStateFailed;
        [self stopWaitingTimer];
        return;
    }
    
    _isTouchEnded = NO;
    self.hitNode = [self.hitTestDelegate gestureRecognizer:self hitTest:touch inView:self.view];
    if (self.hitNode) {
        _beginPosition = [touch locationInView:self.view];
        [self startWaitingTimer];
    } else {
        self.state = UIGestureRecognizerStateFailed;
        [self stopWaitingTimer];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    NSSet *allTouches = [event allTouches];
    UITouch *touch = [allTouches anyObject];
    CGPoint currentPosition = [touch locationInView:self.view];
    CGFloat distancePower = pow(currentPosition.x - _beginPosition.x, 2) + pow(currentPosition.y - _beginPosition.y, 2);
    if (distancePower > 100) {
        [self stopWaitingTimer];
        [super touchesCancelled:touches withEvent:event];
        self.state = UIGestureRecognizerStateFailed;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    if (_waitingTimer) {
        _isTouchEnded = YES;
    } else {
        self.state = UIGestureRecognizerStateEnded;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    
    self.state = UIGestureRecognizerStateCancelled;
    
    [self stopWaitingTimer];
}

#pragma mark - Waiting timer

- (void)startWaitingTimer {
    _waitingTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(handleWaiting) userInfo:nil repeats:NO];
}

- (void)stopWaitingTimer {
    if (_waitingTimer) {
        [_waitingTimer invalidate];
        _waitingTimer = nil;
    }
}

- (void)handleWaiting {
    [self stopWaitingTimer];
    if (self.state == UIGestureRecognizerStatePossible) {
        self.state = UIGestureRecognizerStateBegan;
        if (_isTouchEnded) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.state = UIGestureRecognizerStateEnded;
            });
        }
    }
}

@end
