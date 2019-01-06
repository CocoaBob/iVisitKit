//
//  IVPanoramaOverlayScene.h
//  iVisit360
//
//  Created by CocoaBob on 18/06/15.
//  Copyright (c) 2015 Abvent R&D. All rights reserved.
//

#import "IVHeaders.h"

@interface IVPanoramaOverlayScene : SKScene

@property (atomic, strong) SKNode *logoNode;
@property (atomic, strong) NSMutableArray *allNodes;
@property (atomic, strong) NSMutableArray *allAnnotations;

- (void)removeAllOverlays;

// Nodes
- (void)addNode:(SKNode *)node;
- (void)removeAllNodes;

// Annotations
- (void)addAnnotation:(SKNode *)annotation;
- (void)removeAllAnnotations;

// Logo
- (void)removeLogo;

@end
