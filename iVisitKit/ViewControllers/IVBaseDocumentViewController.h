//
//  IVBaseDocumentViewController.h
//  iVisit 3D
//
//  Created by Bob on 20/09/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IVBaseDocument;

@interface IVBaseDocumentViewController : UIViewController

- (void)showBars:(BOOL)isVisible animated:(BOOL)animated;

- (void)cleanEnvironment;

- (IVBaseDocument *)currentOpeningDocument;
- (void)loadDocument;
- (void)loadDocumentWithCompletionHandler:(void(^)(void))completionHandler;

@end
