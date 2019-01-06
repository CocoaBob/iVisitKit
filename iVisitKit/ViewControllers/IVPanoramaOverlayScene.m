//
//  IVPanoramaOverlayScene.m
//  iVisit360
//
//  Created by CocoaBob on 18/06/15.
//  Copyright (c) 2015 Abvent R&D. All rights reserved.
//

#import "IVPanoramaOverlayScene.h"

@interface IVPanoramaOverlayScene ()

@end

@implementation IVPanoramaOverlayScene

@synthesize logoNode = _logoNode;

- (instancetype)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        self.allNodes = [NSMutableArray array];
        self.allAnnotations = [NSMutableArray array];
    }
    return self;
}

#pragma mark -

- (void)removeAllOverlays {
    [self removeAllNodes];
    [self removeAllAnnotations];
    [self removeLogo];
}

#pragma mark - Nodes

- (void)addNode:(SKNode *)node {
    [self addChild:node];
    [self.allNodes addObject:node];
}

- (void)removeAllNodes {
    for (SKNode *node in self.allNodes) {
        [node removeFromParent];
    }
    [self.allNodes removeAllObjects];
}

#pragma mark - Annotations

- (void)addAnnotation:(SKNode *)annotation {
    [self addChild:annotation];
    [self.allAnnotations addObject:annotation];
}

- (void)removeAllAnnotations {
    for (SKNode *annotation in self.allAnnotations) {
        [annotation removeFromParent];
    }
    [self.allAnnotations removeAllObjects];
}

#pragma mark - Logo

- (SKNode *)logoNode {
    return _logoNode;
}

- (void)setLogoNode:(SKNode *)logoNode {
    if (_logoNode) {
        [self removeLogo];
    }
    _logoNode = logoNode;
    if (_logoNode) {
        [self addChild:_logoNode];
    }
}

- (void)removeLogo {
    [self.logoNode removeFromParent];
    _logoNode = nil;
}

@end
