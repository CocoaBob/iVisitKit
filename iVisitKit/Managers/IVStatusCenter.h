//
//  IVStatusCenter.h
//  iVisit 3D
//
//  Created by Bob on 04/07/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVHeaders.h"

@interface IVStatusCenter : NSObject

@property (nonatomic, assign) BOOL didLaunch;
@property (nonatomic, assign) BOOL isTransitionViewVisible;
@property (nonatomic, assign) BOOL isDeviceMotionActive;
@property (nonatomic, assign) BOOL isOpeningDocument;
@property (nonatomic, assign) BOOL isRotatingScreen;
@property (nonatomic, assign) BOOL isDismissingModalViewController;

@property (nonatomic, strong) NSString *selectedNodeIDOnMap;

@property (nonatomic, assign) float rotationAngleVerticalBeforeWarning, rotationAngleHorizontalBeforeWarning, fovBeforeWarning;

+ (instancetype)shared;

+ (NSUInteger)totalMemoryAvailable;

@end
