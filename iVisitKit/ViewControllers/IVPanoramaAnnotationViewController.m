//
//  IVPanoramaAnnotationViewController.m
//  iVisit360
//
//  Created by CocoaBob on 15/07/15.
//  Copyright (c) 2015 Abvent R&D. All rights reserved.
//

#import "IVPanoramaAnnotationViewController.h"

#define CONTENT_MARGIN ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?64:32)
#define CAPTION_HEIGHT 50

@interface IVPanoramaAnnotationViewController () <WKNavigationDelegate>

@property (nonatomic, weak) IBOutlet UIScrollView *contentScrollView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentScrollViewTopMargin;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentScrollViewBottomMargin;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentScrollViewLeftMargin;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentScrollViewRightMargin;
@property (nonatomic, weak) IBOutlet UIView *mediaContainerView;
@property (nonatomic, weak) IBOutlet UIView *htmlContainerView;
@property (nonatomic, strong) NSLayoutConstraint *htmlContainerViewHeight;

@property (nonatomic, strong) IVPanoramaAnnotation *annotation;
@property (nonatomic, strong) MPMoviePlayerController *moviePlayerController;

@end

@implementation IVPanoramaAnnotationViewController

+ (void)presentFromViewController:(UIViewController *)presentingVC withAnnotation:(IVPanoramaAnnotation *)annotation {
    dispatch_block_t tempBlock = ^ {
        // To avoid presenting for a non-clickable 3D node
        if ((annotation.type == IVPanoramaAnnotationTypeImage || annotation.type == IVPanoramaAnnotationTypeImage) &&
            !annotation.isClickable) {
            return;
        }
        
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"IVPanoramaStoryboard" bundle:[NSBundle bundleForClass:self.class]];
        IVPanoramaAnnotationViewController *annotationVC = [storyboard instantiateViewControllerWithIdentifier:@"IVPanoramaAnnotationViewController"];
        annotationVC.delegate = (id<IVPanoramaAnnotationViewControllerDelegate>)presentingVC;
        if ([annotationVC.delegate respondsToSelector:@selector(willPresentAnnotationViewController)]) {
            [annotationVC.delegate willPresentAnnotationViewController];
        }
        annotationVC.annotation = annotation;
        annotationVC.view.alpha = 0;
        
        annotationVC.view.frame = presentingVC.view.bounds;
        annotationVC.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        // Add child view controller
        {
            [presentingVC addChildViewController:annotationVC]; // Step 1
            [presentingVC.view addSubview:annotationVC.view]; // Step 2
            [annotationVC didMoveToParentViewController:presentingVC]; // Step 3
        }
        
        // Fade in
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             annotationVC.view.alpha = 1;
                         }
                         completion:nil];
    };
    
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            tempBlock();
        });
    }
    else {
        tempBlock();
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissSelf)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    tapGestureRecognizer.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
    
    // Prepare content container view
    _contentScrollViewTopMargin.constant = CONTENT_MARGIN;
    _contentScrollViewBottomMargin.constant = CONTENT_MARGIN;
    _contentScrollViewLeftMargin.constant = CONTENT_MARGIN;
    _contentScrollViewRightMargin.constant = CONTENT_MARGIN;
    _contentScrollView.layer.cornerRadius = 5;
    [self.view addSubview:_contentScrollView];
    
    // Prepare WKWebView
    NSURL *requestURL = nil;
    IVPanoramaAnnotationType annotationType = _annotation.isClickable ? _annotation.aliasType : _annotation.type;
    NSString *annotationInfos = _annotation.isClickable ? _annotation.aliasAnnotInfos : _annotation[@"annotInfos"];
    switch (annotationType) {
        case IVPanoramaAnnotationTypeCaptionImage:
        case IVPanoramaAnnotationTypeCaptionVideo:
        case IVPanoramaAnnotationTypeCustom:
        {
            // To fix WKWebView for iOS 8
            NSString *tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"HTML"];
            [[NSFileManager defaultManager] createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:nil];
            /* To fix WKWebView for iOS 8 */
            
            NSString *htmlFileName = [NSString stringWithFormat:@"%@.html",_annotation.annotationID];
            NSString *htmlFilePath = [curDoc getCachePathOfAnnotationFile:htmlFileName];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:htmlFilePath]) {
                // To fix WKWebView for iOS 8
                [[NSFileManager defaultManager] copyItemAtPath:htmlFilePath toPath:[tempDir stringByAppendingPathComponent:htmlFilePath.lastPathComponent] error:nil];
                /* To fix WKWebView for iOS 8 */
                
                NSString *htmlContent = [NSString stringWithContentsOfFile:htmlFilePath encoding:NSUTF8StringEncoding error:nil];
                if (htmlContent) {
                    NSArray *allImageNames = [htmlContent subStringsBetweenStartTag:@"<img src=\"./" andEndTag:@"\" />"];
                    for (NSString *imageName in allImageNames) {
                        NSString *imageFilePath = [curDoc getCachePathOfAnnotationFile:imageName]; // Unzip image files to cache directory
                        // To fix WKWebView for iOS 8
                        [[NSFileManager defaultManager] copyItemAtPath:imageFilePath toPath:[tempDir stringByAppendingPathComponent:imageFilePath.lastPathComponent] error:nil];
                        /* To fix WKWebView for iOS 8 */
                    }
                }
                
                requestURL = [NSURL fileURLWithPath:[tempDir stringByAppendingPathComponent:htmlFilePath.lastPathComponent]];
            }
            break;
        }
        case IVPanoramaAnnotationTypeOnlineWebsite:
        {
            requestURL = [NSURL URLWithString:annotationInfos];
            break;
        }
        default:
            break;
    }
    
    NSUInteger captionHeight = (requestURL != nil)?CAPTION_HEIGHT:0;
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:_htmlContainerView.bounds];
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    webView.navigationDelegate = self;
    
    if (requestURL) {
        [webView loadRequest:[NSURLRequest requestWithURL:requestURL]];
    }
    
    // Add WKWebView
    {
        [_htmlContainerView addSubview:webView];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_htmlContainerView,webView);
        [_htmlContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[webView]|" options:0 metrics:nil views:views]];
        [_htmlContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[webView]|" options:0 metrics:nil views:views]];
    }
    
    // Setup WKWebView size
    if (annotationType == IVPanoramaAnnotationTypeOnlineWebsite ||
        annotationType == IVPanoramaAnnotationTypeCustom) {
        [_contentScrollView addConstraint:[NSLayoutConstraint constraintWithItem:_htmlContainerView
                                                                       attribute:NSLayoutAttributeHeight
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:_contentScrollView
                                                                       attribute:NSLayoutAttributeHeight
                                                                      multiplier:1.0
                                                                        constant:0]];
    } else {
        [_htmlContainerView addConstraint:[NSLayoutConstraint constraintWithItem:_htmlContainerView
                                                                       attribute:NSLayoutAttributeHeight
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1.0
                                                                        constant:captionHeight]];
    }
    
    // Prepare media view
    if (annotationType == IVPanoramaAnnotationTypeCaptionImage ||
        annotationType == IVPanoramaAnnotationTypeCaptionVideo) {
        CGFloat width = [_annotation[@"captionWidth"] doubleValue];
        CGFloat height = [_annotation[@"captionHeight"] doubleValue];
//        CGFloat scale = [UIScreen mainScreen].scale;
//        width /= scale;
//        height /= scale;
        [_mediaContainerView addConstraint:[NSLayoutConstraint
                                            constraintWithItem:_mediaContainerView
                                            attribute:NSLayoutAttributeHeight
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:_mediaContainerView
                                            attribute:NSLayoutAttributeWidth
                                            multiplier:height/width
                                            constant:0]];
        
        NSLayoutConstraint *contentScrollViewWidth = [NSLayoutConstraint constraintWithItem:_contentScrollView
                                                                          attribute:NSLayoutAttributeWidth
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                                         multiplier:1.0
                                                                           constant:width];
        NSLayoutConstraint *contentScrollHeight = [NSLayoutConstraint constraintWithItem:_contentScrollView
                                                                           attribute:NSLayoutAttributeHeight
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0
                                                                            constant:height + captionHeight];
        NSLayoutConstraint *contentScrollRatio = [NSLayoutConstraint constraintWithItem:_contentScrollView
                                                                          attribute:NSLayoutAttributeHeight
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:_contentScrollView
                                                                          attribute:NSLayoutAttributeWidth
                                                                         multiplier:height/width
                                                                           constant:captionHeight];
        contentScrollViewWidth.priority = 750;
        contentScrollHeight.priority = 750;
        contentScrollRatio.priority = 500;
        [_contentScrollView addConstraints:@[contentScrollViewWidth,contentScrollHeight,contentScrollRatio]];
    } else {
        [_mediaContainerView addConstraint:[NSLayoutConstraint
                                            constraintWithItem:_mediaContainerView
                                            attribute:NSLayoutAttributeHeight
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:_mediaContainerView
                                            attribute:NSLayoutAttributeWidth
                                            multiplier:0
                                            constant:0]];
        
        CGFloat screenLength = MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        NSLayoutConstraint *contentScrollViewWidth = [NSLayoutConstraint constraintWithItem:_contentScrollView
                                                                                  attribute:NSLayoutAttributeWidth
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:nil
                                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                                 multiplier:1.0
                                                                                   constant:screenLength];
        NSLayoutConstraint *contentScrollHeight = [NSLayoutConstraint constraintWithItem:_contentScrollView
                                                                               attribute:NSLayoutAttributeHeight
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:nil
                                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                                              multiplier:1.0
                                                                                constant:screenLength];
        contentScrollViewWidth.priority = 750;
        contentScrollHeight.priority = 750;
        [_contentScrollView addConstraints:@[contentScrollViewWidth,contentScrollHeight]];
    }
    
    if (annotationType == IVPanoramaAnnotationTypeCaptionImage) {
        NSString *imageFileName = annotationInfos;
        NSString *imageFilePath = [curDoc getCachePathOfAnnotationFile:imageFileName];
        UIImage *image = [UIImage imageWithContentsOfFile:imageFilePath];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.frame = _mediaContainerView.bounds;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [_mediaContainerView addSubview:imageView];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_mediaContainerView,imageView);
        [_mediaContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView]|" options:0 metrics:nil views:views]];
        [_mediaContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView]|" options:0 metrics:nil views:views]];
    } else if (annotationType == IVPanoramaAnnotationTypeCaptionVideo) {
        NSString *videoFileName = annotationInfos;
        NSString *videoFilePath = [curDoc getCachePathOfAnnotationFile:videoFileName];
        NSURL *videoFileURL = [NSURL fileURLWithPath:videoFilePath];
        _moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:videoFileURL];
        _moviePlayerController.shouldAutoplay=YES;
        [_moviePlayerController prepareToPlay];
        UIView *movieView = _moviePlayerController.view;
        movieView.frame = _mediaContainerView.bounds;
        movieView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [_mediaContainerView addSubview:movieView];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_mediaContainerView,movieView);
        [_mediaContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[movieView]|" options:0 metrics:nil views:views]];
        [_mediaContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[movieView]|" options:0 metrics:nil views:views]];
    }
    
    [self.view setNeedsLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [_contentScrollView flashScrollIndicators];
}

- (void)dismissSelf:(UITapGestureRecognizer *)tapGestureRecognizer {
    CGPoint location = [tapGestureRecognizer locationInView:self.view];
    
    if (CGRectContainsPoint(_contentScrollView.frame, location)) {
        return;
    }
    
    // Do some clean
    [_moviePlayerController stop];
    [[IVOverlayManager shared] hideActivityView];
    
    // Remove from parent view controller
    [self willMoveToParentViewController:nil]; // Step 1
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.view.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [self.view removeFromSuperview]; // Step 2
                         [self removeFromParentViewController]; // Step 3
                         if ([self.delegate respondsToSelector:@selector(didDismissAnnotationViewController)]) {
                             [self.delegate didDismissAnnotationViewController];
                         }
                     }];
    
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [[IVOverlayManager shared] showActivityViewWithCompletionHandler:nil];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [[IVOverlayManager shared] hideActivityView];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [[IVOverlayManager shared] hideActivityView];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [_htmlContainerView removeConstraint:_htmlContainerViewHeight];
    [[IVOverlayManager shared] hideActivityView];
}

@end
