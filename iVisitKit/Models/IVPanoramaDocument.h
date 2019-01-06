//
//  IVBasePanoramaDocument.h
//  iVisit 3D
//
//  Created by CocoaBob on 02/07/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVHeaders.h"

@interface IVPanoramaMap : NSObject

@property (nonatomic, assign) Coordinate3D coord1;
@property (nonatomic, assign) Coordinate3D coord2;
@property (nonatomic, assign) CGFloat angle;
@property (nonatomic, assign) CGFloat xMin,xMax;
@property (nonatomic, assign) CGFloat yMin,yMax;
@property (nonatomic, assign) CGFloat zTarget;
@property (nonatomic, assign) NSInteger zPosition;
@property (nonatomic, assign) CGFloat xDistance,yDistance;
@property (nonatomic, strong) NSArray *correspondingNodes;
@property (nonatomic, strong) NSString *mapPath;
@property (nonatomic, strong) NSString *mapName;

+ (IVPanoramaMap *)mapWithPath:(NSString *)mapPath;
- (void)calculateValues;

@end

#pragma mark -

@interface IVPanoramaAnnotation : IVBaseDataModel

@property (nonatomic, assign) IVPanoramaAnnotationType type;

@property (nonatomic, assign) IVPanoramaAnnotationType aliasType;
@property (nonatomic, strong) NSString *aliasAnnotInfos;
@property (nonatomic, assign) BOOL isTransparent;

+ (IVPanoramaAnnotationType)typeOfTypeString:(NSString *)typeString isImage:(NSString *)isImage;

- (NSString *)annotationID;
- (NSString *)nodeID;

- (BOOL)isClickable;

@end

#pragma mark - 

@interface IVPanoramaNode : IVBaseDataModel

- (NSString *)localizedName;
- (CGFloat)coordX;
- (CGFloat)coordY;
- (CGFloat)coordZ;
- (BOOL)isVersioned;

@end

#pragma mark -

@interface IVPanoramaDocument : IVBaseDocument {
	CGColorSpaceRef colorSpaceRef;
	
	BOOL hasCalculatedNodesCenter;
    NSUInteger currentMapIndex;
    
    Coordinate3D nodesCenter;
}

//XML Content
@property (nonatomic, strong) NSDictionary *logoAttributes;
@property (nonatomic, strong) NSDictionary *iconsAttributes;
@property (nonatomic, strong) NSDictionary *format;
@property (nonatomic, strong) NSMutableDictionary *allNodesDict;
@property (nonatomic, strong) NSMutableArray *visibleNodesIDs;
@property (nonatomic, strong) NSMutableArray *nodesVersions;
@property (nonatomic, strong) NSMutableDictionary *routesDict;
@property (nonatomic, strong) NSMutableDictionary *annotationsDict; // @{annotName:IVPanoramaAnnotation}
@property (nonatomic, strong) NSMutableDictionary *xmlMapsDict;

// Run time values
@property (nonatomic, assign) BOOL isV4NaviMode;
@property (nonatomic, strong) NSString *currentNodeID;
@property (nonatomic, strong) NSCache *thumbnailImageDataCache,*mapImageDataCache;
@property (nonatomic, strong) UIFont *nodeTitleFont;
@property (nonatomic, assign) CGFloat nodeTitleFontSize;
@property (nonatomic, assign) IVPanoramaNodeTitlePosition nodeTitlePosition;

- (UIImage *)getImageOfNode:(NSString *)nodeID face:(FaceTo)face;

// Nodes
- (IVPanoramaNode *)currentNode;
- (IVPanoramaNode *)nodeWithNodeID:(NSString *)nodeID;
- (IVPanoramaNode *)visibleNodeAtIndex:(NSUInteger)nodeIndex;
- (NSString *)nameOfNodeID:(NSString *)nodeID;
- (NSUInteger)indexOfNodeID:(NSString *)nodeID;
- (NSString *)nodeIDAtIndex:(NSUInteger)nodeIndex;
- (NSArray *)versionsOfNodeID:(NSString *)nodeID;
- (NSString *)nextNodeVersionOfNodeID:(NSString *)nodeID;
- (void)replaceVisibleNodeID:(NSString *)visibleNodeID withNextVersionNodeID:(NSString *)newNodeID;

// Faces
- (FaceTo)startAngleFace;
- (FaceTo)defaultFaceOfNode:(IVPanoramaNode*)theNode;

// Thumbnails
- (UIImage *)thumbnailImageOfNode:(NSString *)nodeID;

// Maps
- (NSUInteger)mapCount;
- (IVPanoramaMap *)mapAtIndex:(NSUInteger)mapIndex;
- (UIImage *)mapImageAtIndex:(NSUInteger)mapIndex;
- (NSData *)mapDataWithPath:(NSString *)mapPath;
- (void)prepareMaps;

// Annotations
- (UIImage *)getNodeIconImage;
- (UIImage *)getAnnotationImageWithType:(IVPanoramaAnnotationType)type;
- (NSString *)getCachePathOfAnnotationFile:(NSString *)fileName; // If the file hasn't been cached yet, it will be extracted first.
- (UIImage *)getLogo;

@end
