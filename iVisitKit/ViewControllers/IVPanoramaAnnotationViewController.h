//
//  IVPanoramaAnnotationViewController.h
//  iVisit360
//
//  Created by CocoaBob on 15/07/15.
//  Copyright (c) 2015 Abvent R&D. All rights reserved.
//

#import "IVHeaders.h"

@class IVPanoramaAnnotation;

@protocol IVPanoramaAnnotationViewControllerDelegate <NSObject>

- (void)willPresentAnnotationViewController;
- (void)didDismissAnnotationViewController;

@end

#pragma mark -

@interface IVPanoramaAnnotationViewController : UIViewController

@property (nonatomic, weak) id<IVPanoramaAnnotationViewControllerDelegate> delegate;

+ (void)presentFromViewController:(UIViewController *)presentingVC withAnnotation:(IVPanoramaAnnotation *)annotation;

@end
