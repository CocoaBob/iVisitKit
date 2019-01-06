//
//  IVPanoramaScene.h
//  iVisit360
//
//  Created by CocoaBob on 28/05/15.
//  Copyright (c) 2015 Abvent R&D. All rights reserved.
//

#import "IVHeaders.h"

@interface IVPanoramaScene : SCNScene

@property (nonatomic, strong) SCNNode *cameraNode;

- (void)addNode:(SCNNode *)node;
- (NSArray *)allNodes;
- (void)removeAllNodes;

@end
