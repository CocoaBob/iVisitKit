//
//  PanoramaViewController.m
//  Panorama
//
//  Created by CocoaBob on 4/7/11.
//  Copyright 2011 CocoaBob. All rights reserved.
//

#import "IVPanoramaViewController.h"

@interface IVPanoramaViewController () <IVNodesListViewDelegate, IVPanoramaAnnotationViewControllerDelegate>

// UI
@property (nonatomic, weak) IBOutlet IVPanoramaNodesListView *nodesListView;

@property (nonatomic, strong) UIBarButtonItem *btnPlay;
@property (nonatomic, strong) UIBarButtonItem *btnMute;
@property (nonatomic, strong) UIBarButtonItem *btnMap;
@property (nonatomic, strong) UIBarButtonItem *btnNavi;
@property (nonatomic, strong) UIBarButtonItem *btnMotion;
@property (nonatomic, weak) IBOutlet UIButton *btnNaviForMotionMode;
@property (nonatomic, weak) IBOutlet UIButton *btnMotionForMotionMode;

@property (nonatomic, assign) BOOL needPreparationForNewPano;
@property (nonatomic, assign) BOOL isPopingViewController;
@property (nonatomic, assign) BOOL isFullScreenUIMode;

@property (nonatomic, assign) CGFloat touchAnimationBeginScale;
@property (nonatomic, assign) BOOL isLoadingNode;

// Motion
@property (nonatomic, assign) BOOL isMotionRunning;
@property (nonatomic, strong) NSOperationQueue *motionQueue;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) NSInteger framesToSkip;
@property (nonatomic, assign) CGFloat lastAngleHBeforeMotion;
@property (nonatomic, assign) CGFloat lastAngleVBeforeMotion;
@property (nonatomic, assign) CMAcceleration lastMotionGravity;

// Scene
@property (nonatomic, weak) IBOutlet SCNView *scnView;
@property (nonatomic, strong) IVPanoramaScene *panoramaScene;
@property (nonatomic, strong) IVPanoramaOverlayScene *overlayScene;

@property (nonatomic, assign) float rotationAngleH, rotationAngleV;//In radian
@property (nonatomic, assign) float nodeAngleH,nodeAngleV;//In radian

@property (nonatomic, assign) SCNMatrix4 lastProjectionMatrix;
@property (nonatomic, assign) SCNMatrix4 lastViewMatrix;

// 3D annotations
@property (nonatomic, strong) NSMutableArray *videoNodes;
@property (nonatomic, strong) NSMutableArray *videoPlayers;
@property (nonatomic, assign) BOOL isVideoPaused;
@property (nonatomic, assign) BOOL isVideoMuted;

// 2D annotations
@property (nonatomic, strong) NSCache *overlayTexturesCache;

@end

#pragma mark - IVPanoramaViewController -

#define FOV_MAX 80
#define FOV_MIN 40

@implementation IVPanoramaViewController

+ (instancetype)shared {
    static id __sharedInstance = nil;
    if (__sharedInstance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            __sharedInstance = [[[self class] alloc] init];
        });
    }
    return __sharedInstance;
}

- (instancetype)init {
    self = [[UIStoryboard storyboardWithName:@"IVPanoramaStoryboard" bundle:[NSBundle bundleForClass:self.class]] instantiateInitialViewController];
    [self view];
    return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    // Register notifications for video playing
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      if (!_isVideoPaused) {
                                                          [self playVideos];
                                                      }
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      [self pauseVideos];
                                                  }];
    
    // Setups
    [self setupAnnotation3D];
    [self setupScene];
    [self setupMotion];
    
    // Single tap to toggle full screen
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleUI)];
    for (UIGestureRecognizer *gr in [_scnView gestureRecognizers]) {
        [tapGR requireGestureRecognizerToFail:gr];
    }
    [_scnView addGestureRecognizer:tapGR];
    
    // NavBar buttons
#define NAV_BAR_BTN_SIZE 24
    UIButton* btnMotion = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, NAV_BAR_BTN_SIZE, NAV_BAR_BTN_SIZE)];
    [btnMotion addTarget:self action:@selector(toggleDeviceMotion:) forControlEvents:UIControlEventTouchUpInside];
    _btnMotion = [[UIBarButtonItem alloc] initWithCustomView:btnMotion];
    
    UIButton* btnNavi = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, NAV_BAR_BTN_SIZE, NAV_BAR_BTN_SIZE)];
    [btnNavi addTarget:self action:@selector(toggleNaviMode:) forControlEvents:UIControlEventTouchUpInside];
    _btnNavi = [[UIBarButtonItem alloc] initWithCustomView:btnNavi];
    
    UIButton* btnMap = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, NAV_BAR_BTN_SIZE, NAV_BAR_BTN_SIZE)];
    [btnMap addTarget:self action:@selector(showMapView:) forControlEvents:UIControlEventTouchUpInside];
    _btnMap = [[UIBarButtonItem alloc] initWithCustomView:btnMap];
    
    UIButton* btnMute = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, NAV_BAR_BTN_SIZE, NAV_BAR_BTN_SIZE)];
    [btnMute addTarget:self action:@selector(toggleMute:) forControlEvents:UIControlEventTouchUpInside];
    _btnMute = [[UIBarButtonItem alloc] initWithCustomView:btnMute];
    
    UIButton* btnPause = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, NAV_BAR_BTN_SIZE, NAV_BAR_BTN_SIZE)];
    [btnPause addTarget:self action:@selector(togglePlayPause:) forControlEvents:UIControlEventTouchUpInside];
    _btnPlay = [[UIBarButtonItem alloc] initWithCustomView:btnPause];
    
    [self updateNavigationBarButtonImages];
}

- (void)viewDidUnload {
    [self teardownMotion];
	_nodesListView = nil;
	self.navigationItem.rightBarButtonItem = nil;
    [_overlayTexturesCache removeAllObjects];
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[_nodesListView hidePageScrollView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Scene Playing
    _scnView.playing = YES;
    
    // Video Playing
    if (!_isVideoPaused) {
        [self playVideos];
    }
    
    _isPopingViewController = NO;
    
	[_nodesListView updateNodesListOffsetWithNodeID:[(IVPanoramaDocument *)[self currentOpeningDocument] currentNodeID]];
    if (!_isFullScreenUIMode) {
        [_nodesListView performSelectorOnMainThread:@selector(animateShowPageScrollView:) withObject:nil waitUntilDone:NO];
    }
	
    if (_needPreparationForNewPano) {
        _needPreparationForNewPano = NO;
        self.navigationItem.title = [(IVPanoramaDocument *)[self currentOpeningDocument] baseName];
        [_nodesListView updateAllPages];
        
        [self updateActionButtons];
        [self setupSceneBeforeAnimation];
        [self performSelector:@selector(animateToStartAngleAndFOV) withObject:nil afterDelay:TRANSIT_ZOOM_DURATION + 0.1]; // Wait for the fade out animation
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(dismissSelf)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self pauseVideos];
    
    // Hide nodes thumbnails list
	[_nodesListView animateHidePageScrollView:nil];
    
    // Stop gyroscope mode
    if([IVStatusCenter shared].isDeviceMotionActive) {
		[self stopDeviceMotions];
    }
    
    [super viewWillDisappear:animated];
    
    // Clear content when close the project
    if (![[self.navigationController viewControllers] containsObject:self]) {
        _panoramaScene.background.contents = [UIColor blackColor];
        [self.overlayScene removeAllOverlays];
        [_overlayTexturesCache removeAllObjects];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateOverlayLogoPosition];
        [self updateOverlaySize];
        [self inverseFovIfNeeded];
        
        [_nodesListView updateContentSizeForPagingScrollView];
        [_nodesListView tilePages];
        [_nodesListView updateNodesListOffsetWithNodeID:[(IVPanoramaDocument *)[self currentOpeningDocument] currentNodeID]];
        
        [self updateNavigationBarButtonImages];
        
        if (!self.presentedViewController) { // Make sure it's visible
            // Show/Hide status bar
            if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
                [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
            } else if (!self.navigationController.navigationBarHidden) {
                [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
            }
        }
    } completion:nil];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self updateOverlayLogoPosition];
    [self updateOverlaySize];
}

#pragma mark - Overwrite Super Class Methods

- (id)currentOpeningDocument {
    IVBaseDocument *document = [super currentOpeningDocument];
    if ([document isKindOfClass:[IVPanoramaDocument class]]) {
        return (IVPanoramaDocument *)document;
    }
    return nil;
}

- (void)cleanEnvironment {
    [super cleanEnvironment];
    [_nodesListView cleanEnvironment];
}

- (void)loadDocument {
    [super loadDocument];
    _needPreparationForNewPano = YES;
    
    [[IVOverlayManager shared] showActivityViewWithCompletionHandler:^{
        IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
        
        if (curDoc) {
            // Maps
            [IVMapViewController shared].needPreparationForNewPano = YES;
            [curDoc prepareMaps];
            
            // Reset UI
            _btnNavi.customView.tintColor = curDoc.isV4NaviMode?BUTTON_HIGHLIGHT_COLOR:nil;
            _isVideoPaused = NO;
            [(UIButton *)_btnPlay.customView setSelected:NO];
            _isVideoMuted = NO;
            [(UIButton *)_btnMute.customView setSelected:NO];
            
            // Reset some data
            _nodeAngleH = _nodeAngleV = 0;
            _lastAngleHBeforeMotion = _lastAngleVBeforeMotion = 0;
            
            // Load the 1st node
            [self loadNode:[curDoc objectForKey:@"id"]
                turnToFace:[curDoc startAngleFace]
                completion:^{
                    [[IVOverlayManager shared] hideActivityView];
                }];
            
            // Nodes
            [_nodesListView updateContentSizeForPagingScrollView];
            [_nodesListView updateNodesListOffsetWithNodeID:[curDoc currentNodeID]];
        }
    }];
}

#pragma mark - UI Controls

- (void)updateNavigationBarButtonImages {
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        [(UIButton *)_btnMotion.customView setImage:[[UIImage imageNamed:@"img_compass_s" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [(UIButton *)_btnNavi.customView setImage:[[UIImage imageNamed:@"img_navi_s" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [(UIButton *)_btnNavi.customView setImage:[UIImage imageNamed:@"img_navi_highlight_s" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
        [(UIButton *)_btnMap.customView setImage:[[UIImage imageNamed:@"img_map_s" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [(UIButton *)_btnMute.customView setImage:[[UIImage imageNamed:@"img_sound_s" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [(UIButton *)_btnMute.customView setImage:[[UIImage imageNamed:@"img_sound_muted_s" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
        [(UIButton *)_btnPlay.customView setImage:[[UIImage imageNamed:@"img_pause_s" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [(UIButton *)_btnPlay.customView setImage:[[UIImage imageNamed:@"img_play_s" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
    } else {
        [(UIButton *)_btnMotion.customView setImage:[[UIImage imageNamed:@"img_compass" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [(UIButton *)_btnNavi.customView setImage:[[UIImage imageNamed:@"img_navi" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [(UIButton *)_btnNavi.customView setImage:[UIImage imageNamed:@"img_navi_highlight" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
        [(UIButton *)_btnMap.customView setImage:[[UIImage imageNamed:@"img_map" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [(UIButton *)_btnMute.customView setImage:[[UIImage imageNamed:@"img_sound" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [(UIButton *)_btnMute.customView setImage:[[UIImage imageNamed:@"img_sound_muted" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
        [(UIButton *)_btnPlay.customView setImage:[[UIImage imageNamed:@"img_pause" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [(UIButton *)_btnPlay.customView setImage:[[UIImage imageNamed:@"img_play" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
    }
}

- (void)toggleUI {
	if (_isMotionRunning || _isPopingViewController)
		return;

    // Toggle Status
    _isFullScreenUIMode = !_isFullScreenUIMode;

    // Change the UI
    [self showBars:!_isFullScreenUIMode animated:YES];
    if (_isFullScreenUIMode) {
		[_nodesListView animateHidePageScrollView:nil];
	}
    else {
		[_nodesListView animateShowPageScrollView:nil];
		[_btnMotionForMotionMode setHidden:YES];
        [_btnNaviForMotionMode setHidden:YES];
    }
    [self updateOverlayLogoVisibility:YES];
}

- (void)updateActionButtons {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];

    BOOL showPauseButton = self.videoNodes.count > 0;
    BOOL showMuteButton = showPauseButton;
    BOOL showNaviButton = (curDoc.type == IVDocTypePanoramaV5 || curDoc.type == IVDocTypePanorama360);
	BOOL showMapButton = ([curDoc mapCount] > 0);
	BOOL showMotionButton = [_motionManager isDeviceMotionAvailable];

    NSMutableArray *items = [NSMutableArray array];
    
    if (showMotionButton)
        [items addObject:_btnMotion];
    if (showNaviButton)
        [items addObject:_btnNavi];
    if (showMapButton)
        [items addObject:_btnMap];
    if (showMuteButton)
        [items addObject:_btnMute];
    if (showPauseButton)
        [items addObject:_btnPlay];
    
    self.navigationItem.rightBarButtonItems = items;
}

#pragma mark - IVNodesListViewDelegate

- (NSUInteger)numberOfNodes {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
    if (curDoc) {
        return [[curDoc visibleNodesIDs] count];
    } else {
        return 0;
    }
}

- (NSString *)nodeIDAtIndex:(NSUInteger)nodeIndex {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
    return [curDoc nodeIDAtIndex:nodeIndex];
}

- (NSUInteger)indexOfNodeID:(NSString *)nodeID {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
    return [curDoc indexOfNodeID:nodeID];
}

- (BOOL)shouldDisplayPageViewBackground {
    return YES;
}

- (BOOL)isSelected:(NSString *)nodeID {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
    return  [[curDoc currentNodeID] isEqualToString:nodeID];
}

- (void)didSelectPageView:(IVNodesListPageView *)pageView {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
    if (![pageView.nodeID isEqualToString:curDoc.currentNodeID]) {
        [pageView loadNode:NO];
    } else {
        IVPanoramaNode *node = [curDoc nodeWithNodeID:pageView.nodeID];
        if ([node isVersioned]) {
            [pageView hideBackgroundLayers];
            [IVNodeVersionsView presentWithNode:node fromPageView:pageView];
        }
    }
}

- (void)didLongSelectPageView:(IVNodesListPageView *)pageView {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
    IVPanoramaNode *node = [curDoc nodeWithNodeID:pageView.nodeID];
    if ([node isVersioned]) {
        [pageView hideBackgroundLayers];
        [IVNodeVersionsView presentWithNode:node fromPageView:pageView];
    } else if (![pageView.nodeID isEqualToString:curDoc.currentNodeID]) {
        [pageView loadNode:NO];
    }
}

#pragma mark - IVPanoramaAnnotationViewControllerDelegate

- (void)willPresentAnnotationViewController {
    [self pauseVideos];
    [_nodesListView animateHidePageScrollView:nil];
}

- (void)didDismissAnnotationViewController {
    if (!_isVideoPaused) {
        [self playVideos];
    }
    if (!_isFullScreenUIMode) {
        [_nodesListView animateShowPageScrollView:nil];
        [self showBars:YES animated:YES];
    }
}

#pragma mark - IBActions

- (IBAction)toggleNaviMode:(id)sender {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
    if (curDoc) {
        curDoc.isV4NaviMode = !curDoc.isV4NaviMode;
        [(UIButton *)_btnNavi.customView setSelected:curDoc.isV4NaviMode];
        [_btnNaviForMotionMode setSelected:curDoc.isV4NaviMode];
    }
}

- (IBAction)showMapView:(id)sender {
	_isPopingViewController = YES;
    [_nodesListView animateHidePageScrollView:^(BOOL finished) {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[IVMapViewController shared]];
        navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.navigationController presentViewController:navigationController animated:YES completion:nil];
    }];
}

@end

#pragma mark - IVPanoramaViewController (DeviceMotion) -

@implementation IVPanoramaViewController (DeviceMotion)

- (void)setupMotion {
    _motionQueue = [[NSOperationQueue alloc] init];
    _motionQueue.maxConcurrentOperationCount = 1;
    _motionManager = [[CMMotionManager alloc] init];
    _motionManager.deviceMotionUpdateInterval = 1 / MAX(60.0, (CGFloat)_scnView.preferredFramesPerSecond);
}

- (void)teardownMotion {
    [self stopDeviceMotions];
    _motionQueue = nil;
    _motionManager = nil;
}

- (void)updateCameraWithRotationMatrix:(CMRotationMatrix)matrix {
    // Copy the transform from CMAttitude
    SCNMatrix4 transform = SCNMatrix4Identity;
    
    transform.m11 = matrix.m11;
    transform.m12 = matrix.m12;
    transform.m13 = matrix.m13;
    
    transform.m21 = matrix.m21;
    transform.m22 = matrix.m22;
    transform.m23 = matrix.m23;
    
    transform.m31 = matrix.m31;
    transform.m32 = matrix.m32;
    transform.m33 = matrix.m33;
    
    transform.m44 = 1;
    
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
    
    // Set adjustment for Horizontal rotation
    transform = SCNMatrix4Rotate(transform, -_lastAngleHBeforeMotion, 0, 0, -1);
    
    // Adjust node angle H
    if (curDoc.type == IVDocTypePanoramaV5 || curDoc.type == IVDocTypePanorama360) {
        transform = SCNMatrix4Mult(transform, SCNMatrix4MakeRotation(-(_nodeAngleH - M_PI), 0, 0, -1));
    }
    
    // Set adjustment for Vertical rotation
    transform = SCNMatrix4Rotate(transform, -M_PI_2, 1, 0, 0);
    
    // Set adjustment for different screen orientations
    switch ([[UIApplication sharedApplication] statusBarOrientation]) {
        case UIInterfaceOrientationLandscapeLeft:
            transform = SCNMatrix4Mult(SCNMatrix4MakeRotation(M_PI_2, 0, 0, 1), transform);
            transform = SCNMatrix4Rotate(transform, -M_PI_2, 0, 1, 0);
            break;
        case UIInterfaceOrientationLandscapeRight:
            transform = SCNMatrix4Mult(SCNMatrix4MakeRotation(-M_PI_2, 0, 0, 1), transform);
            transform = SCNMatrix4Rotate(transform, M_PI_2, 0, 1, 0);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            transform = SCNMatrix4Mult(SCNMatrix4MakeRotation(M_PI, 0, 0, 1), transform);
            transform = SCNMatrix4Rotate(transform, M_PI, 0, 1, 0);
            break;
        default:
            transform = SCNMatrix4Mult(SCNMatrix4MakeRotation(0, 0, 0, 0), transform);
            transform = SCNMatrix4Rotate(transform, 0, 0, 0, 0);
            break;
    }
    
    // Adjust node angle V
    if (curDoc.type == IVDocTypePanoramaV5 || curDoc.type == IVDocTypePanorama360) {
        transform = SCNMatrix4Mult(transform, SCNMatrix4MakeRotation(_nodeAngleV - M_PI_2, 1, 0, 0));
    }
    
    _panoramaScene.cameraNode.transform = transform;
}

- (void)handleDeviceMotion:(CMDeviceMotion *)motion {
    if([IVStatusCenter shared].isDeviceMotionActive) {
        if(_framesToSkip == 0 && !_isMotionRunning) {
            _isMotionRunning = YES;
        } else if (_framesToSkip > 0) {
            _framesToSkip -= 1;
        }
        
        if (_isMotionRunning) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _lastMotionGravity = motion.gravity;
                [self updateCameraWithRotationMatrix:motion.attitude.rotationMatrix];
            });
        }
    }
}

- (void)startDeviceMotions {
    BOOL succeeded = NO;
    _isMotionRunning = NO;
    
    if ([_motionManager isDeviceMotionAvailable]) {
        CGFloat cameraAngleH,cameraAngleV;
        [self getCameraAngleH:&cameraAngleH angleV:&cameraAngleV];
        _lastAngleHBeforeMotion = cameraAngleH;
        _lastAngleVBeforeMotion = cameraAngleV;
        succeeded = YES;
        _framesToSkip = 2;// In iOS 6, the 1st frame is not always correct.
        [_motionManager startDeviceMotionUpdatesToQueue:_motionQueue
                                            withHandler:^(CMDeviceMotion *motion, NSError *error){
                                                [self handleDeviceMotion:motion];
                                            }];
    }
    
    if (succeeded) {
        [IVStatusCenter shared].isDeviceMotionActive = YES;
        [self toggleUI];
        [_btnMotionForMotionMode setHidden:NO];
        IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
        [_btnNaviForMotionMode setHidden:(curDoc.type==IVDocTypePanoramaV5 || curDoc.type==IVDocTypePanorama360)?NO:YES];
        [_btnNaviForMotionMode setSelected:curDoc.isV4NaviMode];
    }
    else {
        [IVStatusCenter shared].isDeviceMotionActive = NO;
    }
}

- (void)stopDeviceMotions {
    _isMotionRunning = NO;
    
    if ([_motionManager isDeviceMotionActive]) {
        [_motionManager stopDeviceMotionUpdates];
        [self setCameraAngleH:_lastAngleHBeforeMotion angleV:_lastAngleVBeforeMotion];
    }
    [IVStatusCenter shared].isDeviceMotionActive = NO;
}

- (IBAction)toggleDeviceMotion:(id)sender {
    [_motionQueue cancelAllOperations];
    if ([_motionManager isDeviceMotionActive]) {
        [self stopDeviceMotions];
    }
    else {
        [self startDeviceMotions];
    }
}

- (IBAction)stopDeviceMotion:(id)sender {
    [self stopDeviceMotions];
    
    // Wait for the variable _isMotionRunning to be updated (I don't know why)
    [self performSelector:@selector(toggleUI) withObject:nil afterDelay:0.01];
}

@end

#pragma mark - IVPanoramaViewController (Scene) -

@implementation IVPanoramaViewController (Scene)

- (void)setupScene {
    // Scene
    _panoramaScene = [IVPanoramaScene scene];
    _scnView.scene = _panoramaScene;
    _scnView.backgroundColor = [UIColor blackColor];
    _scnView.pointOfView = _panoramaScene.cameraNode;
//    _scnView.antialiasingMode = SCNAntialiasingModeMultisampling4X;
    
    // Overlay
    _overlayScene = [[IVPanoramaOverlayScene alloc] initWithSize:_scnView.bounds.size];
    _scnView.overlaySKScene = _overlayScene;
    _overlayTexturesCache = [NSCache new];
    
    // Gesture Recognizer
    IVPanoramaGestureRecognizer *panoramaGR = [[IVPanoramaGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanoramaGR:)];
    panoramaGR.panoramaDelegate = self;
    [_scnView addGestureRecognizer:panoramaGR];
    
    IVPanoramaHitTestGestureRecognizer *hitTestGR = [[IVPanoramaHitTestGestureRecognizer alloc] initWithTarget:self action:@selector(handleHitTestGR:)];
    hitTestGR.hitTestDelegate = self;
    [_scnView addGestureRecognizer:hitTestGR];
    [panoramaGR requireGestureRecognizerToFail:hitTestGR];
}

- (void)setupSceneBeforeAnimation {
    [self setCameraFOV:90];
}

#pragma mark - Documents Manager

- (void)loadNode:(NSString *)nodeID turnToFace:(FaceTo)face completion:(void(^)(void))completion {
    if (!_isLoadingNode) {
        _isLoadingNode = YES;
        
        // Remove existing nodes and overlays
        [self removeAnnotations3D];
        [self.overlayScene removeAllOverlays];
        _lastProjectionMatrix = SCNMatrix4Identity;
        _lastViewMatrix = SCNMatrix4Identity;
        
        // Panorama Document
        IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
        curDoc.currentNodeID = nodeID;
        
        // Load node images
        NSMutableArray *images = [NSMutableArray new];
        NSUInteger totalMemoryAvailable = [IVStatusCenter totalMemoryAvailable];
        for (FaceTo faceTo = 0; faceTo < FaceToCount; ++faceTo) {
            UIImage *image = [curDoc getImageOfNode:nodeID face:faceTo];
            if (image.size.width > 512 && totalMemoryAvailable < 268435456) {
                image = [image resizedImageWithMaximumSize:CGSizeMake(512, 512)];
            } else if (image.size.width > 1024 && totalMemoryAvailable < 536870912) {
                image = [image resizedImageWithMaximumSize:CGSizeMake(1024, 1024)];
            } else if (image.size.width < 512) { // For old devices, if texture is smaller than 512, it displays nothing...
                image = [image resizedImageWithMaximumSize:CGSizeMake(512, 512)];
            }
            [images addObject:image];
        }
        _panoramaScene.background.contents = images;
        
        // Add related nodes
        [self addNodes];
        
        if (curDoc.type == IVDocTypePanorama360) {
            // Add related annotations
            [self addAnnotations3D];
            [self addAnnotations2D];
            
            // Add logo to left bottom corner
            [self addLogo];
            
            // Update Play/Mute buttons
            [self updateActionButtons];
            
            // Update FOV if frontFOV attribute is available
            IVPanoramaNode *node = [curDoc nodeWithNodeID:nodeID];
            NSString *fovString = node[@"frontFov"];
            if (fovString) {
                CGFloat fov = [fovString doubleValue];
                fov = MAX(FOV_MIN, MIN(FOV_MAX, fov));
                [self setCameraFOV:fov];
            }
        }
        
        // If it's not V4 panorama, prepare camera angle H/V for the new node to keep the camera direction
        if (curDoc.type == IVDocTypePanoramaV5 || curDoc.type == IVDocTypePanorama360) {
            CGFloat lastNodeAngleH = _nodeAngleH;
            CGFloat lastNodeAngleV = _nodeAngleV;
            IVPanoramaNode *currNode = [curDoc currentNode];
            _nodeAngleH = deg2rad([[currNode objectForKey:@"angleH"] intValue]);
            _nodeAngleV = deg2rad([[currNode objectForKey:@"angleV"] intValue]);
            
            CGFloat cameraAngleH,cameraAngleV;
            [self getCameraAngleH:&cameraAngleH angleV:&cameraAngleV];
            CGFloat deltaH = - (_nodeAngleH - lastNodeAngleH);
            CGFloat deltaV = - (_nodeAngleV - lastNodeAngleV);
            [self setCameraAngleH:cameraAngleH + deltaH * 2
                           angleV:cameraAngleV + deltaV * 2];
            
            if (((IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument).isV4NaviMode) {
                _lastAngleHBeforeMotion += deltaH * 2;
                _lastAngleVBeforeMotion += deltaV;
            }
            else {
                _lastAngleHBeforeMotion = 0;
                _lastAngleVBeforeMotion = 0;
            }
        }
        // Turn to initial face of the new node
        [self turnToFace:face];
        
        // Update nodes list
        [[NSNotificationCenter defaultCenter] postNotificationName:kNodeSelectionDidChangeNotification object:nodeID];
        
        // Finish
        _isLoadingNode = NO;
        if (completion) {
            completion();
        }
    }
}

// If the actionID is routeID, load the node.
// If the actionID is annotationID, show the annotation
- (void)handleNodeActionWithID:(NSString *)actionID {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
    NSDictionary *route = curDoc.routesDict[actionID];
    IVPanoramaAnnotation *annotation = curDoc.annotationsDict[actionID];
    if (annotation) {
        [IVPanoramaAnnotationViewController presentFromViewController:self withAnnotation:annotation];
    } else if (route) {
        [[IVOverlayManager shared] showActivityViewWithCompletionHandler:^{
            NSString *nodeID = [curDoc.currentNodeID isEqualToString:route[@"to"]]?route[@"from"]:route[@"to"];
            [self loadNode:nodeID
                turnToFace:FaceUnchange
                completion:^{
                    [[IVOverlayManager shared] hideActivityView];
                }];
        }];
    }
    
}

#pragma mark - Gesture Recognizer

- (void)handlePanoramaGR:(IVPanoramaGestureRecognizer *)gestureRecognizer {
    // FOV (Zoom)
    CGFloat newFOV = gestureRecognizer.deltaFOV + [self cameraFOV];
    
    newFOV = MIN(FOV_MAX, newFOV);
    newFOV = MAX(FOV_MIN, newFOV);
    
    [self setCameraFOV:newFOV];
    
    // Translate
    CGFloat cameraAngleH,cameraAngleV;
    [self getCameraAngleH:&cameraAngleH angleV:&cameraAngleV];
    
    cameraAngleH += gestureRecognizer.deltaX;
    cameraAngleV += gestureRecognizer.deltaY;
    
    cameraAngleV = MIN(M_PI_2, cameraAngleV);
    cameraAngleV = MAX(-M_PI_2, cameraAngleV);
    
    [self setCameraAngleH:cameraAngleH angleV:cameraAngleV];
    
    // Reset delta values
    gestureRecognizer.deltaFOV = 0;
    gestureRecognizer.deltaX = 0;
    gestureRecognizer.deltaY = 0;
}

#define ANI_MAX 1.25
#define ANI_MID 1.125
#define ANI_DUR 0.1

- (void)handleHitTestGR:(IVPanoramaHitTestGestureRecognizer *)gestureRecognizer {
    id hitNode = gestureRecognizer.hitNode;
    if (hitNode &&
        hitNode != self.overlayScene.logoNode) {
        CGFloat maxAniScale = ANI_MAX * _touchAnimationBeginScale;
        CGFloat midAniScale = ANI_MID * _touchAnimationBeginScale;
        CGFloat oriAniScale = _touchAnimationBeginScale;
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            // Highlight the node (only for SKNode)
            if ([hitNode isKindOfClass:[SKNode class]]) {
                _touchAnimationBeginScale = ((SKNode *)hitNode).xScale;
                maxAniScale = ANI_MAX * _touchAnimationBeginScale;
                midAniScale = ANI_MID * _touchAnimationBeginScale;
                oriAniScale = _touchAnimationBeginScale;
                
                [hitNode runAction:[SKAction scaleTo:maxAniScale duration:ANI_DUR]
                        completion:^{
                            if (gestureRecognizer.state == UIGestureRecognizerStateBegan ||
                                gestureRecognizer.state == UIGestureRecognizerStateChanged) {
                                // Animate the node
                                SKAction *animationAction = [SKAction repeatActionForever:[SKAction sequence:@[[SKAction scaleTo:maxAniScale duration:0.5],
                                                                                                               [SKAction scaleTo:oriAniScale duration:0.5]]]];
                                [hitNode runAction:animationAction withKey:@"animation"];
                            }
                        }];
            }
        } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
            // Remove the highlight and animation (only for SKNode)
            if ([hitNode isKindOfClass:[SKNode class]]) {
                [hitNode removeActionForKey:@"animation"];
            }
            
            // Bounce
            if ([hitNode isKindOfClass:[SKNode class]]) {
                CGFloat beginScale = ((SKNode *)hitNode).xScale;
                [hitNode runAction:[SKAction sequence:@[[SKAction scaleTo:maxAniScale duration:((maxAniScale - beginScale) > 0.1)?ANI_DUR:0],[SKAction scaleTo:oriAniScale duration:ANI_DUR]]]
                        completion:^{
                            SKAction *zoomInAction = [SKAction scaleTo:midAniScale duration:ANI_DUR];
                            zoomInAction.timingMode = SKActionTimingEaseOut;
                            [hitNode runAction:zoomInAction completion:^{
                                SKAction *zoomOutAction = [SKAction scaleTo:oriAniScale duration:ANI_DUR];
                                zoomOutAction.timingMode = SKActionTimingEaseIn;
                                [hitNode runAction:zoomOutAction completion:^{
                                    [hitNode removeAllActions];
                                    [self handleNodeActionWithID:((SKNode *)hitNode).name];
                                }];
                            }];
                        }];
            } else {
                [self handleNodeActionWithID:((SKNode *)hitNode).name];
            }
        } else if (gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
            // Remove the highlight and animation (only for SKNode)
            if ([hitNode isKindOfClass:[SKNode class]]) {
                [hitNode removeActionForKey:@"animation"];
                [hitNode runAction:[SKAction scaleTo:oriAniScale duration:ANI_DUR]];
            }
        }
    }
}

#pragma mark - IVPanoramaGestureRecognizerDelegate

- (CGFloat)fovForPanoramaGestureRecognizer:(IVPanoramaGestureRecognizer *)panoramaGestureRecognizer {
    return [self cameraFOV];
}

#pragma mark - IVPanoramaHitTestGestureRecognizerDelegate

- (id)gestureRecognizer:(IVPanoramaHitTestGestureRecognizer *)gestureRecognizer hitTest:(UITouch *)touch inView:(UIView *)view {
    if (view == _scnView) {
        CGPoint point;
        
        // Handle overlays 2D nodes
        point = [touch locationInNode:self.overlayScene];
        NSArray *results = [self.overlayScene nodesAtPoint:point];
        if (results.count > 0) {
            return [results firstObject];
        }
        
        // Handle clickable 3D nodes
        point = [touch locationInView:_scnView];
        results = [_scnView hitTest:point options:nil];
        SCNHitTestResult *result = [results firstObject];
        return result.node;
    }
    return nil;
}

#pragma mark - Scene Control

- (void)animateWithDuration:(CGFloat)duration
             timingFunction:(CAMediaTimingFunction *)timingFunction
                 animations:(void (^)(void))animations
                 completion:(void (^)(void))completion {
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration: duration];
    [SCNTransaction setCompletionBlock:completion];
    [SCNTransaction setAnimationTimingFunction:timingFunction];
    if (animations) {
        animations();
    }
    [SCNTransaction commit];
}

- (void)animateToStartAngleAndFOV {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
    
    CGFloat destAngleH = 0;
    CGFloat destAngleV = 0;
    if (curDoc.type == IVDocTypePanoramaV4) {
        destAngleH = deg2rad([[curDoc objectForKey:@"angleH"] floatValue]);
        destAngleV = deg2rad([[curDoc objectForKey:@"angleV"] floatValue]);
        CGFloat cameraAngleH,cameraAngleV;
        [self getCameraAngleH:&cameraAngleH angleV:&cameraAngleV];
        destAngleH = [self getClosestEquivalentAngleRelativeToAngle:cameraAngleH fromAngle:destAngleH];
        destAngleV = [self getClosestEquivalentAngleRelativeToAngle:cameraAngleV fromAngle:destAngleV];
    } else if (curDoc.type == IVDocTypePanorama360) {
        IVPanoramaNode *currNode = [curDoc currentNode];
        NSString *frontAngleH = [currNode objectForKey:@"frontAngleH"];
        NSString *frontAngleV = [currNode objectForKey:@"frontAngleV"];
        if (frontAngleH) {
            destAngleH = deg2rad([frontAngleH floatValue]);
            destAngleH -= M_PI;
        }
        if (frontAngleV) {
            destAngleV = deg2rad([frontAngleV floatValue]);
            destAngleV -= M_PI_2;
        }
        CGFloat cameraAngleH,cameraAngleV;
        [self getCameraAngleH:&cameraAngleH angleV:&cameraAngleV];
        destAngleH = [self getClosestEquivalentAngleRelativeToAngle:cameraAngleH fromAngle:destAngleH];
        destAngleV = [self getClosestEquivalentAngleRelativeToAngle:cameraAngleV fromAngle:destAngleV];
    } else {
        [self getCameraAngleH:&destAngleH angleV:&destAngleV];
    }
    
    float destFov = [[curDoc objectForKey:@"baseFov"] intValue];
    destFov = MIN(FOV_MAX, destFov);
    destFov = MAX(FOV_MIN, destFov);
    
    [self animateWithDuration:0.5
               timingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]
                   animations:^{
                       [self setCameraAngleH:destAngleH angleV:destAngleV];
                       [self setCameraFOV:destFov];
                   }
                   completion:nil];
}

- (void)getCameraAngleH:(CGFloat *)angleH angleV:(CGFloat *)angleV {
    *angleV = _rotationAngleV;
    *angleH = _rotationAngleH;
}

- (void)setCameraAngleH:(CGFloat)angleH angleV:(CGFloat)angleV {
    if (!_isMotionRunning) {// Disable pan during device motion mode.
        _rotationAngleH = angleH;
        _rotationAngleV = angleV;
        
        IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
        SCNMatrix4 transform = SCNMatrix4Identity;
        
        if (curDoc.type == IVDocTypePanoramaV5 || curDoc.type == IVDocTypePanorama360) {
            transform = SCNMatrix4Mult(SCNMatrix4MakeRotation(_nodeAngleV - M_PI_2, 1, 0, 0), transform);
            transform = SCNMatrix4Mult(SCNMatrix4MakeRotation(M_PI - _nodeAngleH, 0, 1, 0), transform);
        }
        
        transform = SCNMatrix4Mult(SCNMatrix4MakeRotation(_rotationAngleH, 0, 1, 0), transform);
        transform = SCNMatrix4Mult(SCNMatrix4MakeRotation(_rotationAngleV, 1, 0, 0), transform);
        
        _panoramaScene.cameraNode.transform = transform;
    }
}

- (void)inverseFovIfNeeded {
    CGFloat viewRatio = CGRectGetHeight(_scnView.bounds) / CGRectGetWidth(_scnView.bounds);
//    CGFloat fovRatio = _panoramaScene.cameraNode.camera.yFov / _panoramaScene.cameraNode.camera.xFov;
    if ((viewRatio > 1 && _panoramaScene.cameraNode.camera.yFov == 0) ||
        (viewRatio < 1 && _panoramaScene.cameraNode.camera.xFov == 0) ) { // Only the longer axis has fov value, the other one is always 0.
        CGFloat xFov = _panoramaScene.cameraNode.camera.xFov;
        CGFloat yFov = _panoramaScene.cameraNode.camera.yFov;
        _panoramaScene.cameraNode.camera.xFov = yFov;
        _panoramaScene.cameraNode.camera.yFov = xFov;
    }
}

- (CGFloat)cameraFOV {
    return MAX(_panoramaScene.cameraNode.presentationNode.camera.yFov, _panoramaScene.cameraNode.presentationNode.camera.xFov);
}

- (void)setCameraFOV:(CGFloat)cameraFOV {
    CGFloat ratio = CGRectGetHeight(_scnView.bounds) / CGRectGetWidth(_scnView.bounds);
    if (ratio > 1) {
        _panoramaScene.cameraNode.camera.xFov = 0;
        _panoramaScene.cameraNode.camera.yFov = cameraFOV;
    }
    else {
        _panoramaScene.cameraNode.camera.xFov = cameraFOV;
        _panoramaScene.cameraNode.camera.yFov = 0;
    }
}

- (void)turnToFace:(FaceTo)face {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
    if (curDoc.type == IVDocTypePanorama360) {
        if (face == FaceUnchange &&
            ((IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument).isV4NaviMode) {
            // Old navigation mode, do nothing
        }
        else {
            // New navigation mode, always turn to the front angle
            IVPanoramaNode *currNode = [curDoc currentNode];
            NSString *strFrontAngleH = [currNode objectForKey:@"frontAngleH"];
            NSString *strFrontAngleV = [currNode objectForKey:@"frontAngleV"];
            CGFloat frontAngleH, frontAngleV;
            if (strFrontAngleH) {
                frontAngleH = deg2rad([strFrontAngleH floatValue]) - M_PI;
            } else {
                frontAngleH = deg2rad([[currNode objectForKey:@"angleH"] floatValue]) - M_PI;
            }
            if (strFrontAngleV) {
                frontAngleV = M_PI_2 - deg2rad([strFrontAngleV floatValue]);
            } else {
                frontAngleV = M_PI_2 - deg2rad([[currNode objectForKey:@"angleV"] floatValue]);
            }
            [self setCameraAngleH:frontAngleH
                           angleV:frontAngleV];
        }
    }
    else if (curDoc.type == IVDocTypePanoramaV5) {
        if (face == FaceUnchange &&
            ((IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument).isV4NaviMode) {
            // Old navigation mode, do nothing
        }
        else {
            // New navigation mode, always turn to the front face for V5
            [self setCameraAngleH:M_PI - _nodeAngleH
                           angleV:M_PI_2 - _nodeAngleV];
        }
    }
    else if (curDoc.type == IVDocTypePanoramaV4) {
        if (face != FaceUnchange) {
            CGPoint newCameraAngle = CGPointZero;
            switch (face) {
                case FaceToFront:
                    newCameraAngle.x = 0.0f;
                    break;
                case FaceToLeft:
                    newCameraAngle.x = M_PI_2;
                    break;
                case FaceToBack:
                    newCameraAngle.x = M_PI;
                    break;
                case FaceToRight:
                    newCameraAngle.x = -M_PI_2;
                    break;
                default:
                    // -1 means keep the camera direction, it's the old navigation mode
                    break;
            }
            [self setCameraAngleH:newCameraAngle.x angleV:newCameraAngle.y];
        }
    }
}

- (void)updateOverlaySize {
    self.overlayScene.size = _scnView.bounds.size;
    [self updateOverlays];
}

#pragma mark - SCNSceneRendererDelegate

- (void)renderer:(id <SCNSceneRenderer>)aRenderer updateAtTime:(NSTimeInterval)time {
    if (!_isLoadingNode) {
        [self updateOverlays];
    }
}

@end

#pragma mark - IVPanoramaViewController (Overlays) -

@implementation IVPanoramaViewController (Overlays)

- (SKTexture *)textureOfImage:(UIImage *)image {
    SKTexture *texture = [_overlayTexturesCache objectForKey:image];
    if (!texture) {
        texture = [SKTexture textureWithImage:image];
        [_overlayTexturesCache setObject:texture forKey:image];
    }
    return texture;
}

- (SKSpriteNode *)overlayNodeWithID:(NSString *)nodeID image:(UIImage *)image {
    SKSpriteNode *node = [[SKSpriteNode alloc] initWithTexture:[self textureOfImage:image]];
    node.name = nodeID;
    return node;
}


#pragma mark - Nodes

- (UIImage *)createNodeOverlayImageWithTitle:(NSString *)titleString icon:(UIImage *)iconImage anchorPoint:(CGPoint *)anchorPoint {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
    
    // Settings
    CGFloat fontSize = curDoc.nodeTitleFontSize;
    UIFont *titleFont = curDoc.nodeTitleFont;
    IVPanoramaNodeTitlePosition titlePosition = curDoc.nodeTitlePosition;
    
    // Title Image
    NSDictionary *attributes = @{NSFontAttributeName:titleFont, NSForegroundColorAttributeName:[UIColor whiteColor]};
    NSDictionary *attributesBG = @{NSFontAttributeName:titleFont, NSForegroundColorAttributeName:[UIColor blackColor]};
    CGSize titleStringSize = [titleString sizeWithAttributes:attributes];
    CGFloat offset = fontSize / 8.0;
    CGSize drawingSize = CGSizeMake(titleStringSize.width + offset * 2 , titleStringSize.height + offset * 2);
    
    // Combine two images
    UIGraphicsBeginImageContextWithOptions(drawingSize, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextDrawingMode(context, kCGTextStroke);
    CGContextSetLineWidth(context, offset);
    [titleString drawAtPoint:CGPointMake(offset, offset) withAttributes:attributesBG];
    CGContextSetTextDrawingMode(context, kCGTextFill);
    [titleString drawAtPoint:CGPointMake(offset, offset) withAttributes:attributes];
    UIImage *titleImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGSize iconImageSize = iconImage.size;
    CGSize titleImageSize = CGSizeMake(drawingSize.width, drawingSize.height);
    
    CGFloat imageWidth;
    CGFloat imageHeight;
    CGRect iconImageRect;
    CGRect titleImageRect;
    
    switch (titlePosition) {
        default:
        case IVPanoramaNodeTitlePositionTop:
        {
            imageWidth = MAX(iconImageSize.width, titleImageSize.width);
            imageHeight = iconImageSize.height + titleImageSize.height;
            iconImageRect = CGRectMake(((imageWidth - iconImageSize.width) / 2.0), titleImageSize.height, iconImageSize.width, iconImageSize.height);
            titleImageRect = CGRectMake(((imageWidth - titleImageSize.width) / 2.0), 0, titleImageSize.width, titleImageSize.height);
            
            *anchorPoint = CGPointMake(0.5, (iconImageSize.height / 2.0) / (titleImageSize.height + iconImageSize.height));
            break;
        }
        case IVPanoramaNodeTitlePositionBottom:
        {
            imageWidth = MAX(iconImageSize.width, titleImageSize.width);
            imageHeight = iconImageSize.height + titleImageSize.height;
            iconImageRect = CGRectMake(((imageWidth - iconImageSize.width) / 2.0), 0, iconImageSize.width, iconImageSize.height);
            titleImageRect = CGRectMake(((imageWidth - titleImageSize.width) / 2.0), iconImageSize.height, titleImageSize.width, titleImageSize.height);
            
            *anchorPoint = CGPointMake(0.5, (titleImageSize.height + iconImageSize.height / 2.0) / (titleImageSize.height + iconImageSize.height));
            break;
        }
        case IVPanoramaNodeTitlePositionLeft:
        {
            imageWidth = iconImageSize.width + titleImageSize.width;
            imageHeight = MAX(iconImageSize.height, titleImageSize.height);
            iconImageRect = CGRectMake(titleImageSize.width, ((imageHeight - iconImageSize.height) / 2.0), iconImageSize.width, iconImageSize.height);
            titleImageRect = CGRectMake(0, ((imageHeight - titleImageSize.height) / 2.0), titleImageSize.width, titleImageSize.height);
            
            *anchorPoint = CGPointMake((titleImageSize.width + iconImageSize.width / 2.0) / (titleImageSize.width + iconImageSize.width), 0.5);
            break;
        }
        case IVPanoramaNodeTitlePositionRight:
        {
            imageWidth = iconImageSize.width + titleImageSize.width;
            imageHeight = MAX(iconImageSize.height, titleImageSize.height);
            iconImageRect = CGRectMake(0, ((imageHeight - iconImageSize.height) / 2.0), iconImageSize.width, iconImageSize.height);
            titleImageRect = CGRectMake(iconImageSize.width, ((imageHeight - titleImageSize.height) / 2.0), titleImageSize.width, titleImageSize.height);
            
            *anchorPoint = CGPointMake((iconImageSize.width / 2.0) / (titleImageSize.width + iconImageSize.width), 0.5);
            break;
        }
    }
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(imageWidth, imageHeight), NO, [UIScreen mainScreen].scale);
    [iconImage drawInRect:iconImageRect];
    [titleImage drawInRect:titleImageRect];
    UIImage *returnValue = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return returnValue;
}

- (void)addNodeWithRouteID:(NSString *)routeID {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
    NSDictionary *route = curDoc.routesDict[routeID];
    NSString *nodeID = [curDoc.currentNodeID isEqualToString:route[@"to"]]?route[@"from"]:route[@"to"];
    IVPanoramaNode *panoNode = [curDoc nodeWithNodeID:nodeID];
    
    // Add overlay nodes
    if (curDoc.type == IVDocTypePanoramaV4 || curDoc.type == IVDocTypePanoramaV5 || curDoc.type == IVDocTypePanorama360) {
        CGPoint anchorPoint;
        UIImage *overlayImage = [self createNodeOverlayImageWithTitle:[panoNode localizedName]
                                                                 icon:[curDoc getNodeIconImage]
                                                          anchorPoint:&anchorPoint];
        SKSpriteNode *nodeOverlay = [self overlayNodeWithID:routeID image:overlayImage];
        nodeOverlay.anchorPoint = anchorPoint;
        [self.overlayScene addNode:nodeOverlay];
    }
}

- (void)addNodes {
    // Find linked nodes
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
    NSString *curNodeID = curDoc.currentNodeID;
    NSMutableSet *nodes = [NSMutableSet set];
    for (NSString *routeKey in curDoc.routesDict) {
        NSDictionary *route = curDoc.routesDict[routeKey];
        if ([curNodeID isEqualToString:route[@"from"]]) {
            [nodes addObject:route[@"id"]];
        }
        if ((curDoc.type == IVDocTypePanoramaV4 || curDoc.type == IVDocTypePanoramaV5) &&
            [curNodeID isEqualToString:route[@"to"]]) {
            [nodes addObject:route[@"id"]];
        }
    }
    
    // Add node to scene
    for (NSString *nodeID in nodes) {
        [self addNodeWithRouteID:nodeID];
    }
}

#pragma mark - Annotation

- (void)addAnnotation2D:(IVPanoramaAnnotation *)annotation {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
//    NSString *annotationID = [annotation annotationID];
    UIImage *annotationImage = [curDoc getAnnotationImageWithType:annotation.type];
    SKSpriteNode *annotationOverlay = [self overlayNodeWithID:[annotation annotationID] image:annotationImage];
    [self.overlayScene addAnnotation:annotationOverlay];
}

- (void)addAnnotations2D {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
    for (IVPanoramaAnnotation *annotation in [curDoc.annotationsDict allValues]) {
        if ([curDoc.currentNodeID isEqualToString:[annotation nodeID]]) {
            if (annotation.type != IVPanoramaAnnotationTypeImage && annotation.type != IVPanoramaAnnotationTypeVideo) {
                [self addAnnotation2D:annotation];
            }
        }
    }
}

- (void)addLogo {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
    UIImage *logoImage = [curDoc getLogo];
//    logoImage = [UIImage imageWithCGImage:logoImage.CGImage scale:[UIScreen mainScreen].scale orientation:logoImage.imageOrientation];
    if (logoImage) {
        self.overlayScene.logoNode = [self overlayNodeWithID:nil image:logoImage];
        [self updateOverlayLogoVisibility:NO];
        [self updateOverlayLogoPosition];
    }
}

#pragma mark - Overlay positions

- (void)setOverlayPosition:(SKSpriteNode *)overlay
                 viewWidth:(CGFloat)viewWidth
                viewHeight:(CGFloat)viewHeight
          projectionMatrix:(SCNMatrix4)projectionMatrix
           modelViewMatrix:(SCNMatrix4)modelViewMatrix {
    // 3D to 2D projection
    SCNVector4 point = SCNVector4Make(0, 0, 0, 1.0);
    point = SCNMatrix4MultiplyVector4(modelViewMatrix, point);
    point = SCNMatrix4MultiplyVector4(projectionMatrix, point);
    point.x = (point.x / point.w + 1) / 2;
    point.y = (point.y / point.w + 1) / 2;
    
    // Hide if node position is behind camera
    if (point.z < 0) {
        overlay.hidden = YES;
    } else {
        overlay.hidden = NO;
        
        overlay.position = CGPointMake(viewWidth * point.x, viewHeight * point.y);
        
        // Update scale
//            overlay.xScale = overlay.yScale = FOV_MIN / [self cameraFOV];
        
        // Update rotation
        if ([_motionManager isDeviceMotionActive]) {
            SCNVector3 gravity;
            gravity.x = _lastMotionGravity.x;
            gravity.y = _lastMotionGravity.y;
            gravity.z = 0;
            
            SCNVector3 groundVector;
            switch ([[UIApplication sharedApplication] statusBarOrientation]) {
                case UIInterfaceOrientationLandscapeLeft:
                    groundVector.x = 1.0f;
                    groundVector.y = 0.0f;
                    groundVector.z = 0.0f;
                    break;
                case UIInterfaceOrientationLandscapeRight:
                    groundVector.x = -1.0f;
                    groundVector.y = 0.0f;
                    groundVector.z = 0.0f;
                    break;
                case UIInterfaceOrientationPortraitUpsideDown:
                    groundVector.x = 0.0f;
                    groundVector.y = 1.0f;
                    groundVector.z = 0.0f;
                    break;
                default:
                    groundVector.x = 0.0f;
                    groundVector.y = -1.0f;
                    groundVector.z = 0.0f;
                    break;
            }
            
            float cosAngle = acosf((groundVector.x * gravity.x + groundVector.y * gravity.y + groundVector.z * gravity.z) /
                                   ([self normalizeVector:&groundVector] * [self normalizeVector:&gravity]));
            float sinAngle = groundVector.x * gravity.y - groundVector.y * gravity.x;
            if (sinAngle > 0.0f) {
                cosAngle = -cosAngle;
            }
            
            overlay.zRotation = -cosAngle;
        }
        else {
            overlay.zRotation = 0;
        }
    }
}

- (void)updateOverlays {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
    IVPanoramaNode *curNode = [curDoc currentNode];
    CGFloat viewWidth = CGRectGetWidth(_scnView.bounds);
    CGFloat viewHeight = CGRectGetHeight(_scnView.bounds);
    
    // Projection Matrix
    // Adjust the focal lengths of the camera project matrix before calculating node positions
    SCNMatrix4 projectionMatrix = _panoramaScene.cameraNode.presentationNode.camera.projectionTransform;
    if (viewWidth > viewHeight) {
        projectionMatrix.m11 = ABS(projectionMatrix.m11);
        projectionMatrix.m22 = projectionMatrix.m11 * viewWidth / viewHeight;
    } else {
        projectionMatrix.m22 = ABS(projectionMatrix.m22);
        projectionMatrix.m11 = projectionMatrix.m22 * viewHeight / viewWidth;
    }
    
    // View Matrix
    SCNMatrix4 viewMatrix = _panoramaScene.cameraNode.presentationNode.transform;
    { // Bob: I don't know how this part works, it just works.
        viewMatrix = SCNMatrix4Mult(viewMatrix, SCNMatrix4MakeRotation(M_PI_2, 0, -1, 0)); // Columns 1 = 3, 3 = 1
        viewMatrix = SCNMatrix4Mult(viewMatrix, SCNMatrix4MakeRotation(-M_PI_2, -1, 0, 0)); // Columns 2 = -3, 3 = -2
        viewMatrix = SCNMatrix4Invert(viewMatrix);
        
        if (curDoc.type == IVDocTypePanoramaV5) {
            viewMatrix = SCNMatrix4Mult(SCNMatrix4MakeRotation(-M_PI_2, 0, 0, 1), viewMatrix);
            viewMatrix = SCNMatrix4Mult(SCNMatrix4MakeRotation(_nodeAngleV - M_PI_2, 1, 0, 0), viewMatrix);
            viewMatrix = SCNMatrix4Mult(SCNMatrix4MakeRotation(M_PI - _nodeAngleH, 0, 0, 1), viewMatrix);
        } else if (curDoc.type == IVDocTypePanorama360) {
            viewMatrix = SCNMatrix4Mult(SCNMatrix4MakeRotation(-M_PI_2, 0, 0, 1), viewMatrix);
        }
    }
    
    // No need to update if the view isn't changed
    if (SCNMatrix4EqualToMatrix4(projectionMatrix, _lastProjectionMatrix) &&
        SCNMatrix4EqualToMatrix4(viewMatrix, _lastViewMatrix)) {
        return;
    }
    
    // Remember the last status
    _lastProjectionMatrix = projectionMatrix;
    _lastViewMatrix = viewMatrix;
    
    // Update each node
    for (SKSpriteNode *nodeOverlay in [self.overlayScene allNodes]) {
        NSDictionary *route = curDoc.routesDict[nodeOverlay.name];
        NSString *nodeID = [curDoc.currentNodeID isEqualToString:route[@"to"]]?route[@"from"]:route[@"to"];
        IVPanoramaNode *node = [curDoc nodeWithNodeID:nodeID];
        SCNMatrix4 modelViewMatrix = SCNMatrix4Identity;
        
        if (curDoc.type == IVDocTypePanoramaV4 || curDoc.type == IVDocTypePanoramaV5) {
            modelViewMatrix = SCNMatrix4Mult(SCNMatrix4MakeTranslation(node.coordX-curNode.coordX, node.coordY-curNode.coordY, node.coordZ-curNode.coordZ), viewMatrix);
        } else if (curDoc.type == IVDocTypePanorama360) {
            CGFloat coordX = [route[@"coordX"] floatValue];
            CGFloat coordY = [route[@"coordY"] floatValue];
            CGFloat coordZ = [route[@"coordZ"] floatValue];
            modelViewMatrix = SCNMatrix4Mult(SCNMatrix4MakeTranslation(coordY, -coordX, coordZ), viewMatrix);
        }
        
        [self setOverlayPosition:nodeOverlay viewWidth:viewWidth viewHeight:viewHeight projectionMatrix:projectionMatrix modelViewMatrix:modelViewMatrix];
    }
    
    for (SKSpriteNode *annotationOverlay in [self.overlayScene allAnnotations]) {
        NSString *annotationID = annotationOverlay.name;
        IVPanoramaAnnotation *annotation = curDoc.annotationsDict[annotationID];
        CGFloat coordX = [annotation[@"coordX"] floatValue];
        CGFloat coordY = [annotation[@"coordY"] floatValue];
        CGFloat coordZ = [annotation[@"coordZ"] floatValue];
        SCNMatrix4 modelViewMatrix = SCNMatrix4Mult(SCNMatrix4MakeTranslation(coordY, -coordX, coordZ), viewMatrix);
        
        [self setOverlayPosition:annotationOverlay viewWidth:viewWidth viewHeight:viewHeight projectionMatrix:projectionMatrix modelViewMatrix:modelViewMatrix];
    }
}

- (void)updateOverlayLogoPosition {
    SKNode *logoNode = self.overlayScene.logoNode;
    if (!logoNode) {
        return;
    }
    
    CGFloat viewWidth = CGRectGetWidth(_scnView.bounds);
    CGFloat viewHeight = CGRectGetHeight(_scnView.bounds);
    CGFloat logoWidth = CGRectGetWidth(logoNode.frame);
    CGFloat logoWidth_2 = logoWidth / 2.0;
    CGFloat logoHeight = CGRectGetHeight(logoNode.frame);
    CGFloat logoHeight_2 = logoHeight / 2.0;
    CGPoint position = CGPointZero;
    
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
    switch ([curDoc.logoAttributes[@"position"] intValue]) {
        case IVPanoramaLogoPositionTopLeft:
            position = CGPointMake(logoWidth_2, viewHeight - logoHeight_2);
            break;
        case IVPanoramaLogoPositionTopRight:
            position = CGPointMake(viewWidth - logoWidth_2, viewHeight - logoHeight_2);
            break;
        case IVPanoramaLogoPositionBottomLeft:
            position = CGPointMake(logoWidth_2, logoHeight_2);
            break;
        case IVPanoramaLogoPositionBottomRight:
            position = CGPointMake(viewWidth - logoWidth_2, logoHeight_2);
            break;
        default:
            break;
    }
    
    logoNode.position = position;
}

- (void)updateOverlayLogoVisibility:(BOOL)animated {
    if (!self.overlayScene.logoNode ||
        (self.overlayScene.logoNode.alpha == 1) == _isFullScreenUIMode) {
        return;
    }
    if (animated) {
        [self.overlayScene.logoNode runAction:[SKAction fadeAlphaTo:_isFullScreenUIMode?1:0 duration:UINavigationControllerHideShowBarDuration]];
    } else {
        self.overlayScene.logoNode.alpha = _isFullScreenUIMode?1:0;
    }
}

@end

#pragma mark -

@interface IVVideoNode : SKVideoNode

@end

@implementation IVVideoNode

- (void)setPaused:(BOOL)paused {
    BOOL canChange = NO;
    for (NSString *stackSymbol in [NSThread callStackSymbols]) {
        if ([stackSymbol containsString:NSStringFromClass([IVPanoramaViewController class])]) {
            canChange = YES;
            break;
        }
    }
    if (canChange) {
        [super setPaused:paused];
    }
}

@end

typedef struct FloatPoint {
    float x;
    float y;
} FloatPoint;

@implementation IVPanoramaViewController (Annotation3D)

- (void)setupAnnotation3D {
    _videoNodes = [NSMutableArray array];
    _videoPlayers = [NSMutableArray array];
}

- (void)addAnnotation3D:(IVPanoramaAnnotation *)annotation {
    SCNVector3 p1 = SCNVector3Make([annotation[@"coordY1"] floatValue], -[annotation[@"coordX1"] floatValue], [annotation[@"coordZ1"] floatValue]);
    SCNVector3 p2 = SCNVector3Make([annotation[@"coordY2"] floatValue], -[annotation[@"coordX2"] floatValue], [annotation[@"coordZ2"] floatValue]);
    SCNVector3 p3 = SCNVector3Make([annotation[@"coordY3"] floatValue], -[annotation[@"coordX3"] floatValue], [annotation[@"coordZ3"] floatValue]);
    SCNVector3 p4 = SCNVector3Make([annotation[@"coordY4"] floatValue], -[annotation[@"coordX4"] floatValue], [annotation[@"coordZ4"] floatValue]);
    
    // Create geometry
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:(SCNVector3[]){ p1, p2, p3, p4 }
                                                                              count:4];
    
    // On iOS devices, SceneKit doesn't support CGPoint becaues it's double.
//    SCNGeometrySource *textureCoordinatesSource = [SCNGeometrySource geometrySourceWithTextureCoordinates:(CGPoint[]){ {0.,1.}, {1.,1.}, {1.,0.}, {0.,0.} }
//                                                                                                    count:4];
    FloatPoint textureCoordinates[] = { {0.,1.}, {1.,1.}, {1.,0.}, {0.,0.} };
//    NSData *textureCoordinatesData = [NSData dataWithBytes:textureCoordinates length:sizeof(textureCoordinates)];
    SCNGeometrySource *textureCoordinatesSource = [SCNGeometrySource geometrySourceWithData:[NSData dataWithBytes:textureCoordinates length:sizeof(textureCoordinates)]
                                                                                   semantic:SCNGeometrySourceSemanticTexcoord
                                                                                vectorCount:4
                                                                            floatComponents:YES
                                                                        componentsPerVector:2
                                                                          bytesPerComponent:sizeof(float)
                                                                                 dataOffset:offsetof(FloatPoint, x)
                                                                                 dataStride:sizeof(FloatPoint)];
    

    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:[NSData dataWithBytes:(short[]){ 3, 2, 1, 3, 1, 0 } length:sizeof(short[6])]
                                                                primitiveType:SCNGeometryPrimitiveTypeTriangles
                                                               primitiveCount:2
                                                                bytesPerIndex:sizeof(short)];
    
    SCNGeometry *geometry = [SCNGeometry geometryWithSources:@[vertexSource,textureCoordinatesSource] elements:@[element]];
    
    // Add media
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
    NSString *filePath = [curDoc getCachePathOfAnnotationFile:annotation[@"annotInfos"]];
    if (!filePath || annotation.isTransparent) {
        geometry.firstMaterial.diffuse.contents = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.5];
    }
    else if (annotation.type == IVPanoramaAnnotationTypeImage) {
        geometry.firstMaterial.diffuse.contents = filePath;
        SCNMatrix4 transform = SCNMatrix4Identity;
        transform = SCNMatrix4Mult(SCNMatrix4MakeRotation(M_PI, 1, 0, 0), transform);
        transform = SCNMatrix4Mult(SCNMatrix4MakeTranslation(0, -1, 0), transform);
        geometry.firstMaterial.diffuse.contentsTransform = transform;
    } else if (annotation.type == IVPanoramaAnnotationTypeVideo) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        AVPlayer *player = [[AVPlayer alloc ] initWithURL:fileURL];
        [self.videoPlayers addObject:player];
        player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        player.muted = _isVideoMuted;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidPlayToEndTimeNotification:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:[player currentItem]];
        
        CGSize videoSize = CGSizeMake([annotation[@"width"] floatValue],[annotation[@"height"] floatValue]);
        
        IVVideoNode *videoNode = [[IVVideoNode alloc] initWithAVPlayer:player];
        [self.videoNodes addObject:videoNode];
        videoNode.size = videoSize;
        videoNode.position = CGPointMake(videoSize.width / 2.0, videoSize.height / 2.0);
        
        SKScene *skScene = [SKScene sceneWithSize:videoSize];
        skScene.scaleMode = SKSceneScaleModeResizeFill;
        [skScene addChild:videoNode];
        
        geometry.firstMaterial.diffuse.contents = skScene;
        
        if (_isVideoPaused) {
            videoNode.paused = YES;
            [videoNode pause];
        } else {
            videoNode.paused = NO;
            [videoNode play];
        }
    }
    
    SCNNode *node = [SCNNode nodeWithGeometry:geometry];
    node.name = annotation.annotationID;
    
//    IVPanoramaNode *curPanoNode = [curDoc currentNode];
//    
//    CGFloat curNodeAngleH = deg2rad([[curPanoNode objectForKey:@"angleH"] intValue]);
//    CGFloat curNodeAngleV = deg2rad([[curPanoNode objectForKey:@"angleV"] intValue]);
    
    SCNMatrix4 transform = SCNMatrix4Identity;
    transform = SCNMatrix4Mult(SCNMatrix4MakeRotation(-M_PI_2, 1, 0, 0), transform);
    node.transform = transform;
    
    [_panoramaScene addNode:node];
}

- (void)addAnnotations3D {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[self currentOpeningDocument];
    for (IVPanoramaAnnotation *annotation in [curDoc.annotationsDict allValues]) {
        if ([curDoc.currentNodeID isEqualToString:[annotation nodeID]]) {
            if (annotation.type == IVPanoramaAnnotationTypeImage || annotation.type == IVPanoramaAnnotationTypeVideo) {
                [self addAnnotation3D:annotation];
            }
        }
    }
}

- (void)removeAnnotations3D {
    for (IVVideoNode *videoNode in self.videoNodes) {
        [videoNode pause];
    }
    for (AVPlayer *player in self.videoPlayers) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[player currentItem]];
    }
    for (SCNNode *node in [_panoramaScene allNodes]) {
        id contents = node.geometry.firstMaterial.diffuse.contents;
        if ([contents isKindOfClass:[SKScene class]]) {
            [(SKScene *)contents removeAllChildren];
        }
        node.geometry.firstMaterial.diffuse.contents = nil;
    }
    
    [self.videoNodes removeAllObjects];
    self.videoNodes = nil;
    [self.videoPlayers removeAllObjects];
    self.videoPlayers = nil;
    
    [_panoramaScene removeAllNodes];
}

- (void)pauseVideos {
    for (IVVideoNode *videoNode in self.videoNodes) {
        [videoNode pause];
        videoNode.paused = YES;
    }
}

- (void)playVideos {
    for (IVVideoNode *videoNode in self.videoNodes) {
        [videoNode play];
        videoNode.paused = NO;
    }
}

- (void)muteVideos {
    for (AVPlayer *player in self.videoPlayers) {
        player.muted = YES;
    }
}

- (void)unmuteVideos {
    for (AVPlayer *player in self.videoPlayers) {
        player.muted = NO;
    }
}

#pragma mark - NSNotification

- (void)playerItemDidPlayToEndTimeNotification:(NSNotification *)notification {
    AVPlayerItem *playerItem = [notification object];
    [playerItem seekToTime:kCMTimeZero];
}

#pragma mark - Actions

- (IBAction)togglePlayPause:(id)sender {
    _isVideoPaused = !_isVideoPaused;
    [(UIButton *)_btnPlay.customView setSelected:_isVideoPaused];
    
    if (_isVideoPaused) {
        [self pauseVideos];
    } else {
        [self playVideos];
    }
}

- (IBAction)toggleMute:(id)sender {
    _isVideoMuted = !_isVideoMuted;
    [(UIButton *)_btnMute.customView setSelected:_isVideoMuted];
    
    if (_isVideoMuted) {
        [self muteVideos];
    } else {
        [self unmuteVideos];
    }
}

@end

#pragma mark - IVPanoramaViewController (Helpers) -

@implementation IVPanoramaViewController (Helpers)

- (CGFloat)normalizeVector:(SCNVector3 *)vector {
    float mag = sqrtf(powf(vector->x, 2) + powf(vector->y, 2) + powf(vector->z, 2));
    if (mag != 0.0f) {
        vector->x /= mag;
        vector->y /= mag;
        vector->z /= mag;
    }
    return mag;
}

- (CGFloat)getClosestEquivalentAngleRelativeToAngle:(CGFloat)fromAngle fromAngle:(CGFloat)toAngle {
    CGFloat returnValue = toAngle;
    if (fromAngle < toAngle) {
        while (fromAngle < toAngle) {
            toAngle -= M_PI_D;
        }
        CGFloat diff1 = fabs(fromAngle - toAngle);
        CGFloat diff2 = fabs(toAngle + M_PI_D - fromAngle);
        returnValue = (diff1 < diff2)?toAngle:(toAngle + M_PI_D);
    }
    else if (fromAngle > toAngle) {
        while (fromAngle > toAngle) {
            toAngle += M_PI_D;
        }
        CGFloat diff1 = fabs(toAngle - fromAngle);
        CGFloat diff2 = fabs(fromAngle - (toAngle - M_PI_D));
        returnValue = (diff1 < diff2)?toAngle:(toAngle - M_PI_D);
    }
    return returnValue;
}

@end
