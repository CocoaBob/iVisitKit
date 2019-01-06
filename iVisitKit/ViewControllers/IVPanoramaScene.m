//
//  IVPanoramaScene.m
//  iVisit360
//
//  Created by CocoaBob on 28/05/15.
//  Copyright (c) 2015 Abvent R&D. All rights reserved.
//

#import "IVPanoramaScene.h"

@interface IVPanoramaScene ()

@property (nonatomic, strong) NSMutableArray *nodes;

@end

@implementation IVPanoramaScene

- (instancetype)init {
    if (self = [super init]) {
        if (SYSTEM_VERSION_LESS_THAN(@"9.0")) {
            self.background.contentsTransform = SCNMatrix4MakeScale(1, 1, -1);
        }
        
        _cameraNode = [SCNNode node];
        _cameraNode.camera = [SCNCamera camera];
        _cameraNode.camera.zNear = 0.1;
        _cameraNode.camera.zFar = 1000;
        _cameraNode.position = SCNVector3Make(0, 0, 0);
        [self.rootNode addChildNode:_cameraNode];
        
        _nodes = [NSMutableArray array];
    }
    return self;
}

- (void)addNode:(SCNNode *)node {
    [self.rootNode addChildNode:node];
    [_nodes addObject:node];
}

- (NSArray *)allNodes {
    return _nodes;
}

- (void)removeAllNodes {
    for (SCNNode *node in _nodes) {
        node.geometry = nil;
        [node removeFromParentNode];
    }
    [_nodes removeAllObjects];
}

@end
