//
//  PanoramaViewController.h
//  Panorama
//
//  Created by CocoaBob on 4/7/11.
//  Copyright 2011 CocoaBob. All rights reserved.
//

#import "IVHeaders.h"

#import "IVBaseDocumentViewController.h"

@interface IVPanoramaViewController : IVBaseDocumentViewController

+ (instancetype)shared;

@end

#pragma mark -

@interface IVPanoramaViewController (DeviceMotion)

- (void)setupMotion;
- (void)teardownMotion;
- (void)stopDeviceMotions;

- (IBAction)toggleDeviceMotion:(id)sender;

@end

#pragma mark -

#import "IVPanoramaGestureRecognizer.h"
#import "IVPanoramaHitTestGestureRecognizer.h"

@class IVPanoramaOverlayScene;

@interface  IVPanoramaViewController (Scene) <SCNSceneRendererDelegate, IVPanoramaGestureRecognizerDelegate, IVPanoramaHitTestGestureRecognizerDelegate>

- (void)setupScene;
- (void)setupSceneBeforeAnimation;

- (void)getCameraAngleH:(CGFloat *)angleH angleV:(CGFloat *)angleV;
- (void)setCameraAngleH:(CGFloat)angleH angleV:(CGFloat)angleV;

- (void)animateToStartAngleAndFOV;
- (void)loadNode:(NSString *)nodeID turnToFace:(FaceTo)face completion:(void(^)(void))completion;

- (void)inverseFovIfNeeded;
- (void)updateOverlaySize;

@end

@interface IVPanoramaViewController (Overlays)

- (void)addNodes;
- (void)addAnnotations2D;
- (void)addLogo;
- (void)updateOverlays;
- (void)updateOverlayLogoPosition;
- (void)updateOverlayLogoVisibility:(BOOL)animated;

@end

@interface IVPanoramaViewController (Annotation3D)

- (void)setupAnnotation3D;

- (void)addAnnotations3D;
- (void)removeAnnotations3D;

- (void)pauseVideos;
- (void)playVideos;

- (IBAction)toggleMute:(id)sender;
- (IBAction)togglePlayPause:(id)sender;

@end

#define SCNMatrix4MultiplyVector4(matrix, vector) SCNVector4Make(matrix.m11 * vector.x + matrix.m21 * vector.y + matrix.m31 * vector.z + matrix.m41 * vector.w,\
                                                                 matrix.m12 * vector.x + matrix.m22 * vector.y + matrix.m32 * vector.z + matrix.m42 * vector.w,\
                                                                 matrix.m13 * vector.x + matrix.m23 * vector.y + matrix.m33 * vector.z + matrix.m43 * vector.w,\
                                                                 matrix.m14 * vector.x + matrix.m24 * vector.y + matrix.m34 * vector.z + matrix.m44 * vector.w)

#define SCNMatrix4Print(string,matrix) NSLog(@"%@\n%012.6f\t%012.6f\t%012.6f\t%012.6f\n%012.6f\t%012.6f\t%012.6f\t%012.6f\n%012.6f\t%012.6f\t%012.6f\t%012.6f\n%012.6f\t%012.6f\t%012.6f\t%012.6f",string,matrix.m11,matrix.m12,matrix.m13,matrix.m14,matrix.m21,matrix.m22,matrix.m23,matrix.m24,matrix.m31,matrix.m32,matrix.m33,matrix.m34,matrix.m41,matrix.m42,matrix.m43,matrix.m44)

#define SCNMatrix4To3Print(string,matrix) NSLog(@"%@\n%08.6f\t%08.6f\t%08.6f\n%08.6f\t%08.6f\t%08.6f\n%08.6f\t%08.6f\t%08.6f",string,matrix.m11,matrix.m12,matrix.m13,matrix.m21,matrix.m22,matrix.m23,matrix.m31,matrix.m32,matrix.m33)

@interface IVPanoramaViewController (Helpers)

- (CGFloat)normalizeVector:(SCNVector3 *)vector;
- (CGFloat)getClosestEquivalentAngleRelativeToAngle:(CGFloat)fromAngle fromAngle:(CGFloat)toAngle;

@end
