//
//  IVPanoramaNodeTapGestureRecognizer.h
//  iVisit360
//
//  Created by CocoaBob on 05/06/15.
//  Copyright (c) 2015 Abvent R&D. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class IVPanoramaHitTestGestureRecognizer;

@protocol IVPanoramaHitTestGestureRecognizerDelegate <NSObject>

- (id)gestureRecognizer:(IVPanoramaHitTestGestureRecognizer *)gestureRecognizer hitTest:(UITouch *)touch inView:(UIView *)view;

@end

@interface IVPanoramaHitTestGestureRecognizer : UIGestureRecognizer

@property (nonatomic, weak) id<IVPanoramaHitTestGestureRecognizerDelegate> hitTestDelegate;

@property (nonatomic, strong) id hitNode;

@end
