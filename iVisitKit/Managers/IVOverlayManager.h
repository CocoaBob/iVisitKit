//
//  IVOverlayManager.h
//  iVisit 3D
//
//  Created by CocoaBob on 18/10/2013.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVHeaders.h"

@interface IVOverlayManager : NSObject

@property (nonatomic, strong) UIImageView *transitionImageView;

+ (instancetype)shared;

- (void)showActivityViewWithCompletionHandler:(void(^)(void))completionHandler;
- (void)hideActivityView;

@end
