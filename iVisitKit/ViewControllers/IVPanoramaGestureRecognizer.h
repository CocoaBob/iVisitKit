//
//  IVPanoramaGestureRecognizer.h
//  iVisit360
//
//  Created by CocoaBob on 28/05/15.
//  Copyright (c) 2015 Abvent R&D. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class IVPanoramaGestureRecognizer;

@protocol IVPanoramaGestureRecognizerDelegate <NSObject>

- (CGFloat)fovForPanoramaGestureRecognizer:(IVPanoramaGestureRecognizer *)panoramaGestureRecognizer;

@end

@interface IVPanoramaGestureRecognizer : UIGestureRecognizer

@property (nonatomic, weak) id<IVPanoramaGestureRecognizerDelegate> panoramaDelegate;

@property (nonatomic, assign) CGFloat deltaFOV;
@property (nonatomic, assign) CGFloat deltaX;
@property (nonatomic, assign) CGFloat deltaY;

@end
