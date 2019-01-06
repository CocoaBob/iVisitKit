//
//  IVBasePanoramaDocument.m
//  iVisit 3D
//
//  Created by CocoaBob on 02/07/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVPanoramaDocument.h"

@interface IVPanoramaMap ()
@end

@implementation IVPanoramaMap

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        NSData *coord1Data = [decoder decodeObjectForKey:@"coord1"];
        NSData *coord2Data = [decoder decodeObjectForKey:@"coord2"];
        [coord1Data getBytes:&_coord1 length:[coord1Data length]];
        [coord1Data getBytes:&_coord2 length:[coord2Data length]];
        _angle = [decoder decodeDoubleForKey:@"angle"];
        _xMin = [decoder decodeDoubleForKey:@"xMin"];
        _xMax = [decoder decodeDoubleForKey:@"xMax"];
        _yMin = [decoder decodeDoubleForKey:@"yMin"];
        _yMax = [decoder decodeDoubleForKey:@"yMax"];
        _zTarget = [decoder decodeDoubleForKey:@"zTarget"];
        _zPosition = [decoder decodeIntegerForKey:@"zPosition"];
        _xDistance = [decoder decodeDoubleForKey:@"xDistance"];
        _yDistance = [decoder decodeDoubleForKey:@"yDistance"];
        _correspondingNodes = [decoder decodeObjectForKey:@"correspondingNodes"];
        _mapPath = [decoder decodeObjectForKey:@"mapPath"];
        _mapName = [decoder decodeObjectForKey:@"mapName"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[NSData dataWithBytes:&_coord1 length:sizeof(Coordinate3D)] forKey:@"coord1"];
    [coder encodeObject:[NSData dataWithBytes:&_coord2 length:sizeof(Coordinate3D)] forKey:@"coord2"];
    [coder encodeDouble:_angle forKey:@"angle"];
    [coder encodeDouble:_xMin forKey:@"xMin"];
    [coder encodeDouble:_xMax forKey:@"xMax"];
    [coder encodeDouble:_yMin forKey:@"yMin"];
    [coder encodeDouble:_yMax forKey:@"yMax"];
    [coder encodeDouble:_zTarget forKey:@"zTarget"];
    [coder encodeInteger:_zPosition forKey:@"zPosition"];
    [coder encodeDouble:_xDistance forKey:@"xDistance"];
    [coder encodeDouble:_yDistance forKey:@"yDistance"];
    [coder encodeObject:_correspondingNodes forKey:@"correspondingNodes"];
    [coder encodeObject:_mapPath forKey:@"mapPath"];
    [coder encodeObject:_mapName forKey:@"mapName"];
}

+ (IVPanoramaMap *)mapWithPath:(NSString *)mapPath {
	IVPanoramaMap *panoramaMap = [IVPanoramaMap new];
	if (panoramaMap) {
		panoramaMap.mapPath = mapPath;
		if (![panoramaMap loadIPTCInfomation:[panoramaMap mapData]]) {
			return nil;
		}
	}
	return panoramaMap;
}

- (BOOL)saveCoord:(Coordinate3D *)coord :(NSArray *)coordinates {
	(*coord).x = [coordinates[0] floatValue];
	(*coord).y = [coordinates[1] floatValue];
	(*coord).z = [coordinates[2] floatValue];
	return YES;
}

- (NSData *)mapData {
	return [(IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument mapDataWithPath:self.mapPath];
}

- (BOOL)loadIPTCInfomation:(NSData *)theImageData {
	CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)theImageData, NULL);
	CFDictionaryRef metadataRef = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, NULL);
	
	if (!metadataRef) {
		CFRelease(sourceRef);
		return NO;
	}
	
	NSDictionary *immutableMetadata = (__bridge NSDictionary *)metadataRef;
	NSMutableDictionary *metaData = [immutableMetadata mutableCopy];
	
	immutableMetadata = nil;
	CFRelease(metadataRef);
	CFRelease(sourceRef);
	
	BOOL successful = YES;
	NSDictionary *iptcDict = metaData[(NSString *)kCGImagePropertyIPTCDictionary];
	if ([iptcDict count] == 2) {
		NSString *value1 = iptcDict[(NSString *)kCGImagePropertyIPTCLanguageIdentifier];
		NSString *value2 = iptcDict[(NSString *)kCGImagePropertyIPTCImageOrientation];
		
		NSRange range1 = [value1 rangeOfString:@"IVISIT "];
		NSRange range2 = [value2 rangeOfString:@"IVISIT "];
		
		NSArray *coords1;
		NSArray *coords2;
		
		if (range1.location != NSNotFound) {
			value1 = [value1 substringFromIndex:range1.length];
			coords1 = [value1 componentsSeparatedByString:@" "];
			coords2 = [value2 componentsSeparatedByString:@" "];
			if ([coords1 count] != 3 || [coords2 count] != 4)
			{
				return NO;
			}
			self.angle = [[coords2 lastObject] floatValue];
			coords2 = [coords2 subarrayWithRange:NSMakeRange(0, 3)];
		}
		else if (range2.location != NSNotFound) {
			value2 = [value2 substringFromIndex:range2.length];
			coords1 = [value1 componentsSeparatedByString:@" "];
			coords2 = [value2 componentsSeparatedByString:@" "];
			if ([coords1 count] != 4 || [coords2 count] != 3)
			{
				return NO;
			}
			self.angle = [[coords1 lastObject] floatValue];
			coords1 = [coords1 subarrayWithRange:NSMakeRange(0, 3)];
		}
		else {
			coords1 = [value1 componentsSeparatedByString:@" "];
			coords2 = [value2 componentsSeparatedByString:@" "];
			if ([coords1 count] != 3 || [coords2 count] != 3)
			{
				return NO;
			}
			self.angle = 0.0f;
		}
		
		successful &= [self saveCoord:&_coord1 :coords1];
		successful &= [self saveCoord:&_coord2 :coords2];
	}
    else {
        successful &= NO;
    }
	
    [self calculateValues];
	
	return successful;
}

- (void)calculateValues {
    self.xMin = MIN(self.coord1.x, self.coord2.x);
    self.xMax = MAX(self.coord1.x, self.coord2.x);
    
    self.yMin = MIN(self.coord1.y, self.coord2.y);
    self.yMax = MAX(self.coord1.y, self.coord2.y);
	
	self.xDistance = self.xMax - self.xMin;
	self.yDistance = self.yMax - self.yMin;
	
	self.zTarget = self.coord1.z;
	self.zPosition = (int)nearbyintf((self.coord2.z * 100));// Use integer, to avoid the accurate problem like 0.1995 and 0.2005...
}

@end

#pragma mark -

@implementation IVPanoramaAnnotation

+ (IVPanoramaAnnotationType)typeOfTypeString:(NSString *)typeString isImage:(NSString *)isImage {
    if ([@"captionAnnot" isEqualToString:typeString]) {
        if ([@"1" isEqualToString:isImage]) {
            return IVPanoramaAnnotationTypeCaptionImage;
        } else {
            return IVPanoramaAnnotationTypeCaptionVideo;
        }
    } else if ([@"annotationImageVideo" isEqualToString:typeString]) {
        if ([@"1" isEqualToString:isImage]) {
            return IVPanoramaAnnotationTypeImage;
        } else {
            return IVPanoramaAnnotationTypeVideo;
        }
    } else if ([@"onlineWebsite" isEqualToString:typeString]) {
        return IVPanoramaAnnotationTypeOnlineWebsite;
    } else if ([@"customAnnot" isEqualToString:typeString]) {
        return IVPanoramaAnnotationTypeCustom;
    }
    return IVPanoramaAnnotationTypeUnkown;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        _type = [decoder decodeIntForKey:@"type"];
        _aliasType = [decoder decodeIntForKey:@"aliasType"];
        _isTransparent = [decoder decodeBoolForKey:@"isTransparent"];
        _aliasAnnotInfos = [decoder decodeObjectForKey:@"aliasAnnotInfos"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    
    [coder encodeInt:_type forKey:@"type"];
    [coder encodeInt:_aliasType forKey:@"aliasType"];
    [coder encodeBool:_isTransparent forKey:@"isTransparent"];
    [coder encodeObject:_aliasAnnotInfos forKey:@"aliasAnnotInfos"];
}

- (NSString *)annotationID {
    return self[@"annotName"];
}

- (NSString *)nodeID {
    return self[@"idNode"];
}

- (BOOL)isClickable {
    NSString *isClickable = self[@"isClickable"];
    if (isClickable && [@"1" isEqualToString:isClickable]) {
        return YES;
    }
    return NO;
}

@end

#pragma mark - 

@implementation IVPanoramaNode

- (NSString *)localizedName {
    return [IVDocumentManager localisedStringFromDict:[self objectForKey:@"label"]];
}

- (CGFloat)coordX {
    return [[self objectForKey:@"coordY"] floatValue];
}

- (CGFloat)coordY {
    return -[[self objectForKey:@"coordX"] floatValue];
}

- (CGFloat)coordZ {
    return [[self objectForKey:@"coordZ"] floatValue];
}

- (BOOL)isVersioned {
    NSString *versionType = self[@"versionType"];
    if (versionType && ([versionType isEqualToString:@"1"] || [versionType isEqualToString:@"2"])) {
        return YES;
    }
    return NO;
}

@end

#pragma mark - 

@interface IVPanoramaDocument ()

@property (nonatomic,strong) NSArray *mMapPaths;
@property (nonatomic,strong) NSMutableArray *mMapZPositionsInOrder;
@property (nonatomic,strong) NSMutableDictionary *displayMapsDict;
@property (nonatomic,strong) NSCache *overlayImagesCache;

@end

@implementation IVPanoramaDocument

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        _logoAttributes = [decoder decodeObjectForKey:@"logoAttributes"];
        _iconsAttributes = [decoder decodeObjectForKey:@"iconsAttributes"];
        _allNodesDict = [[decoder decodeObjectForKey:@"nodesDict"] mutableCopy];
        _visibleNodesIDs = [[decoder decodeObjectForKey:@"visibleNodesIDs"] mutableCopy];
        _nodesVersions = [[decoder decodeObjectForKey:@"nodesVersions"] mutableCopy];
        _routesDict = [[decoder decodeObjectForKey:@"routesDict"] mutableCopy];
        _annotationsDict = [[decoder decodeObjectForKey:@"annotationsDict"] mutableCopy];
        _xmlMapsDict = [[decoder decodeObjectForKey:@"xmlMapsDict"] mutableCopy];
        _format = [decoder decodeObjectForKey:@"format"];

        _mMapPaths = [decoder decodeObjectForKey:@"mMapPaths"];
        _mMapZPositionsInOrder = [decoder decodeObjectForKey:@"mMapZPositionsInOrder"];
        _displayMapsDict = [decoder decodeObjectForKey:@"displayMapsDict"];

        self.thumbnailImageDataCache = [NSCache new];
        self.mapImageDataCache = [NSCache new];
        self.overlayImagesCache = [NSCache new];

		colorSpaceRef = CGColorSpaceCreateDeviceRGB();

        // Init runtime variables
        _nodeTitlePosition = IVPanoramaNodeTitlePositionUnknown;
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];

    [coder encodeObject:_logoAttributes forKey:@"logoAttributes"];
    [coder encodeObject:_iconsAttributes forKey:@"iconsAttributes"];
    [coder encodeObject:_allNodesDict forKey:@"nodesDict"];
    [coder encodeObject:_visibleNodesIDs forKey:@"visibleNodesIDs"];
    [coder encodeObject:_nodesVersions forKey:@"nodesVersions"];
    [coder encodeObject:_routesDict forKey:@"routesDict"];
    [coder encodeObject:_annotationsDict forKey:@"annotationsDict"];
    [coder encodeObject:_xmlMapsDict forKey:@"xmlMapsDict"];
    [coder encodeObject:_format forKey:@"format"];

    [coder encodeObject:_mMapPaths forKey:@"mMapPaths"];
    [coder encodeObject:_mMapZPositionsInOrder forKey:@"mMapZPositionsInOrder"];
    [coder encodeObject:_displayMapsDict forKey:@"displayMapsDict"];
}

- (instancetype)init {
    self = [super init];
	if (self) {
        // Caches
        self.thumbnailImageDataCache = [NSCache new];
        self.mapImageDataCache = [NSCache new];
        self.overlayImagesCache = [NSCache new];

        _logoAttributes = [NSDictionary dictionary];
        _iconsAttributes = [NSDictionary dictionary];
		_allNodesDict = [NSMutableDictionary dictionary];
        _visibleNodesIDs = [NSMutableArray array];
        _nodesVersions = [NSMutableArray array];
        _routesDict = [NSMutableDictionary dictionary];
        _annotationsDict = [NSMutableDictionary dictionary];
		_displayMapsDict = [NSMutableDictionary dictionary];
        _xmlMapsDict = [NSMutableDictionary dictionary];
		
		colorSpaceRef = CGColorSpaceCreateDeviceRGB();
		
//		Coordinate3D newCoord;
//		newCoord.x = 0.0f;
//		newCoord.y = 0.0f;
//		newCoord.z = 0.0f;
//		nodesCenter = newCoord;
        
        // Init runtime variables
        _nodeTitlePosition = IVPanoramaNodeTitlePositionUnknown;
	}
	return self;
}

- (void)dealloc {
    [self.thumbnailImageDataCache removeAllObjects];
    self.thumbnailImageDataCache = nil;
    [self.mapImageDataCache removeAllObjects];
    self.mapImageDataCache = nil;
    [self.overlayImagesCache removeAllObjects];
    self.overlayImagesCache = nil;
    
    if (self.zipFile && [self.zipFile isOpen]) {
        [self.zipFile close];
    }

	CGColorSpaceRelease(colorSpaceRef);
}

#pragma mark - Overwrite Super Class Methods

- (NSData *)getPreviewImageData {
    NSData *returnValue = nil;
    if (self.zipFile && ([self.zipFile isOpen] || [self.zipFile open])) {
        returnValue = [self.zipFile readWithFileName:[self.rootFolderPath stringByAppendingPathComponent:@"assets/preview.jpg"]
                                               caseSensitive:NO
                                                   maxLength:NSUIntegerMax];
        if (!returnValue) {
            returnValue = [self.zipFile readWithFileName:[self.rootFolderPath stringByAppendingPathComponent:@"assets/preview.png"]
                                                   caseSensitive:NO
                                                       maxLength:NSUIntegerMax];
        }
        if (!returnValue &&
            (self.type == IVDocTypePanoramaV5 || self.type == IVDocTypePanorama360)) {
            NSString *formatPrefix = self.format[@"prefix"];
            NSString *facePrefix = [self facePrefixForFace:FaceToFront];
            NSString *startNodeID = [self objectForKey:@"id"];
            NSString *imagePath = [self.rootFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"assets/%@%@%@.%@",formatPrefix,facePrefix,startNodeID,@"jpg"]];
            returnValue = [self.zipFile readWithFileName:imagePath
                                                   caseSensitive:YES
                                                       maxLength:NSUIntegerMax];
        }
        [self.zipFile close];
    }
    return returnValue;
}

- (void)openDocument {
    [[IVPanoramaViewController shared] loadDocumentWithCompletionHandler:^{
        
    }];
}

- (void)emptyCache {
    [self.thumbnailImageDataCache removeAllObjects];
    [self.mapImageDataCache removeAllObjects];
    [self.overlayImagesCache removeAllObjects];
}

#pragma mark -

- (void)calculateTheCenterOfNodes {
	//Calculate the center of the nodes
	for(IVPanoramaNode *node in [self.allNodesDict allValues])
	{
		nodesCenter.x += [node coordX];
		nodesCenter.y += [node coordY];
		nodesCenter.z += [node coordZ];
	}
    NSUInteger nodesCount = [self.allNodesDict count];
	nodesCenter.x /= nodesCount;
	nodesCenter.y /= nodesCount;
	nodesCenter.z /= nodesCount;
}

- (NSString *)imagePathWithFace:(FaceTo)face nodeID:(NSString *)nodeID type:(NSString *)type {
	if (self.format) {
		NSString *formatPrefix = self.format[@"prefix"];
		NSString *facePrefix = [self facePrefixForFace:face];
		NSString *imagePath = [self.rootFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"assets/%@%@%@.%@",formatPrefix,facePrefix,nodeID,type]];
        return imagePath;
	}
	return nil;
}

- (NSData *)imageDataWithFace:(FaceTo)face nodeID:(NSString *)nodeID type:(NSString *)type {
	NSData *data = nil;
    NSString *path = [self imagePathWithFace:face nodeID:nodeID type:type];
    if (path) {
        if (self.zipFile && ([self.zipFile isOpen] || [self.zipFile open])) {
            data = [self.zipFile readWithFileName:path caseSensitive:YES maxLength:NSUIntegerMax];
        }
	}
	return data;
}

- (UIImage *)getImageOfNode:(NSString *)nodeID face:(FaceTo)face {
	NSData *data = nil;
    
    data = [self imageDataWithFace:face nodeID:nodeID type:@"jpg"];

    if (!data) {
        data = [self imageDataWithFace:face nodeID:nodeID type:@"png"];
    }
    
    if (!data) {
        data = [self imageDataWithFace:face nodeID:nodeID type:@"pvr"];
    }
    
    UIImage *returnImage = [[UIImage alloc] initWithData:data];
    if (!returnImage) {
        returnImage = [UIImage imageNamed:@"img_no_image" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil];
    }
    return returnImage;
}

- (NSArray *)visibleNodes {
	return [self.allNodesDict objectsForKeys:self.visibleNodesIDs notFoundMarker:[NSNull null]];
}

- (IVPanoramaNode *)currentNode {
	return [self nodeWithNodeID:self.currentNodeID];
}

- (IVPanoramaNode *)visibleNodeAtIndex:(NSUInteger)nodeIndex {
	if (nodeIndex < [self.visibleNodesIDs count]) {
		return [self nodeWithNodeID:self.visibleNodesIDs[nodeIndex]];
	}
	return nil;
}

- (IVPanoramaNode *)nodeWithNodeID:(NSString *)nodeID {
	return self.allNodesDict[nodeID];
}

- (NSUInteger)indexOfNodeID:(NSString *)nodeID {
	return [self.visibleNodesIDs indexOfObject:nodeID];
}

- (NSString *)nodeIDAtIndex:(NSUInteger)nodeIndex {
	if (nodeIndex < [self.visibleNodesIDs count]) {
		return self.visibleNodesIDs[nodeIndex];
	}
	return nil;
}

- (NSArray *)versionsOfNodeID:(NSString *)nodeID {
    if ([[self nodeWithNodeID:nodeID] isVersioned]) {
        for (NSArray *versions in self.nodesVersions) {
            if ([versions containsObject:nodeID]) {
                return versions;
            }
        }
    }
    return nil;
}

- (NSString *)nextNodeVersionOfNodeID:(NSString *)nodeID {
    NSArray *versions = [self versionsOfNodeID:nodeID];
    NSUInteger index = [versions indexOfObject:nodeID] + 1;
    index = (index < versions.count)?:0;
    return versions[index];
}

- (void)replaceVisibleNodeID:(NSString *)visibleNodeID withNextVersionNodeID:(NSString *)newNodeID {
    NSUInteger index = [self.visibleNodesIDs indexOfObject:visibleNodeID];
    if (index != NSNotFound) {
        [self.visibleNodesIDs removeObjectAtIndex:index];
        [self.visibleNodesIDs insertObject:newNodeID atIndex:index];
    }
}

- (IVPanoramaNode *)startNode {
	return [self nodeWithNodeID:[self objectForKey:@"id"]];
}

- (NSString *)nameOfNodeID:(NSString *)nodeID {
	return [[self nodeWithNodeID:nodeID] localizedName];
}

#pragma mark - Node Title fonts

- (BOOL)loadCustomFont:(NSString *)fontFilePath {
    BOOL returnValue = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:fontFilePath]) {
        CFErrorRef error = NULL;
        CTFontManagerRegisterFontsForURL((CFURLRef)[NSURL fileURLWithPath:fontFilePath], kCTFontManagerScopeProcess, &error);
        if (error) {
            NSLog(@"%@", error);
            CFRelease(error);
        } else {
            returnValue = YES;
        }
    }
    return returnValue;
}

- (UIFont *)fontWithFamily:(NSString *)fontFamily type:(IVPanoramaNodeFontType)fontType size:(CGFloat)fontSize {
    NSPredicate *predicate = nil;
    switch (fontType) {
        case IVPanoramaNodeFontTypeNormal:
            predicate = [NSPredicate predicateWithFormat:@"NOT (SELF CONTAINS[c] %@) AND NOT (SELF CONTAINS[c] %@)",@"italic",@"bold"];
            break;
        case IVPanoramaNodeFontTypeItalic:
            predicate = [NSPredicate predicateWithFormat:@"(SELF CONTAINS[c] %@) AND NOT (SELF CONTAINS[c] %@)",@"italic",@"bold"];
            break;
        case IVPanoramaNodeFontTypeBold:
            predicate = [NSPredicate predicateWithFormat:@"NOT (SELF CONTAINS[c] %@) AND (SELF CONTAINS[c] %@)",@"italic",@"bold"];
            break;
        case IVPanoramaNodeFontTypeBoldItalic:
            predicate = [NSPredicate predicateWithFormat:@"(SELF CONTAINS[c] %@) AND (SELF CONTAINS[c] %@)",@"italic",@"bold"];
            break;
        default:
            break;
    }
    NSArray *fontNames = [UIFont fontNamesForFamilyName:fontFamily];
    NSArray *fontNamesToUse = [fontNames filteredArrayUsingPredicate:predicate];
    NSString *fontNameToUse = [fontNamesToUse lastObject];
    if (fontNameToUse) {
        return [UIFont fontWithName:fontNameToUse size:fontSize];
    } else {
        return nil;
    }
}

- (UIFont *)nodeTitleFont {
    if (!_nodeTitleFont) {
        if (self.type == IVDocTypePanorama360) {
            NSString *fontFamily = self.iconsAttributes[@"family"];
            IVPanoramaNodeFontType fontType = [self.iconsAttributes[@"type"] intValue];
            
            // Check system fonts
            _nodeTitleFont = [self fontWithFamily:fontFamily type:fontType size:self.nodeTitleFontSize];
            
            // Load custom font
            if (!_nodeTitleFont) {
                NSString *customFontFileName = self.iconsAttributes[@"fontFile"];
                if (customFontFileName) {
                    NSString *customFontFilePath = [self getCachePathOfAnnotationFile:customFontFileName];
                    if ([self loadCustomFont:customFontFilePath]) {
                        _nodeTitleFont = [self fontWithFamily:fontFamily type:fontType size:self.nodeTitleFontSize];
                    }
                }
            }
        }
        
        if (!_nodeTitleFont) {
            _nodeTitleFont = [UIFont systemFontOfSize:self.nodeTitleFontSize];
        }
    }
    return _nodeTitleFont;
}

- (CGFloat)nodeTitleFontSize {
    if (_nodeTitleFontSize == 0) {
        _nodeTitleFontSize = [self.iconsAttributes[@"size"] floatValue] * 2;//[UIScreen mainScreen].scale;
        if (_nodeTitleFontSize == 0) {
            _nodeTitleFontSize = 24;// * [UIScreen mainScreen].scale;
        }
    }
    return _nodeTitleFontSize;
}

- (IVPanoramaNodeTitlePosition)nodeTitlePosition {
    if (_nodeTitlePosition == IVPanoramaNodeTitlePositionUnknown) {
        NSString *titlePositionStr = self.iconsAttributes[@"position"];
        if (titlePositionStr) {
            _nodeTitlePosition = [titlePositionStr intValue];
        } else {
            _nodeTitlePosition = IVPanoramaNodeTitlePositionTop;
        }
    }
    return _nodeTitlePosition;
}

#pragma mark - Maps

- (NSArray *)mapPaths {
	if (!self.mMapPaths) {
        @autoreleasepool {
            if (self.zipFile && ([self.zipFile isOpen] || [self.zipFile open])) {
                NSString *specialFolderPath = [[self.rootFolderPath stringByAppendingPathComponent:@"assets/special"] stringByAppendingString:@"/"];
                NSArray *contents = [self.zipFile subpathsAtPath:specialFolderPath];
                NSMutableArray *mapPaths = [NSMutableArray array];
                for (NSString *aPath in contents) {
                    NSString *lowercaseName = [[aPath lastPathComponent] lowercaseString];
                    if (![lowercaseName hasPrefix:@"."] &&
                        ([lowercaseName hasSuffix:@"jpg"] ||
                         [lowercaseName hasSuffix:@"png"])) {
                            [mapPaths addObject:aPath];
                        }
                }
                self.mMapPaths = mapPaths;
                [self.zipFile close];
            }
        }
	}
	return self.mMapPaths;
}

- (NSUInteger)mapCount {
	return [[self mapPaths] count];
}

- (NSData *)mapDataWithPath:(NSString *)mapPath {
	NSData *data = [self.mapImageDataCache objectForKey:mapPath];
	if (!data) {
		if (self.zipFile && ([self.zipFile isOpen] || [self.zipFile open])) {
			data = [self.zipFile readWithFileName:mapPath caseSensitive:YES maxLength:NSUIntegerMax];
		}
		if (data) {
			[self.mapImageDataCache setObject:data forKey:mapPath];
        }
	}
	return data;
}

- (UIImage *)mapImageWithPath:(NSString *)mapPath {
	NSData *data = [self mapDataWithPath:mapPath];
	UIImage *returnImage = [UIImage imageWithData:data];
    if (!returnImage) {
        returnImage = [UIImage imageNamed:@"img_no_image" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil];
    }
    return returnImage;
}

- (UIImage *)mapImageAtIndex:(NSUInteger)mapIndex {
	if (mapIndex < [self mapCount]) {
		return [self mapImageWithPath:[self mapPaths][mapIndex]];
	}
	return nil;
}

- (IVPanoramaMap *)mapAtPath:(NSString *)mapPath {
	return (self.displayMapsDict)[mapPath];
}

- (IVPanoramaMap *)mapAtIndex:(NSUInteger)mapIndex {
	if (mapIndex < [self mapCount]) {
		return [self mapAtPath:[self mapPaths][mapIndex]];
	}
	return nil;
}

- (void)orderZPositions {
    NSMutableSet *tempZPositions = [NSMutableSet set];
	for (IVPanoramaMap *aPanoramaMap in [self.displayMapsDict allValues]) {
        // The last several numbers of fractional part may be not accurate
		[tempZPositions addObject:@(aPanoramaMap.zPosition)];
	}
	self.mMapZPositionsInOrder = [NSMutableArray arrayWithArray:[tempZPositions allObjects]];
	[self.mMapZPositionsInOrder sortUsingSelector:@selector(compare:)];
}

- (void)distributeNodes {
    IVPanoramaDocument *curDoc = (IVPanoramaDocument *)[IVDocumentManager shared].currentOpeningDocument;
	for (IVPanoramaMap *aPanoramaMap in [self.displayMapsDict allValues]) {
        if (curDoc.type == IVDocTypePanoramaV4 || curDoc.type == IVDocTypePanoramaV5) {
            // Find zMin
            NSInteger zPositionIndex = [self.mMapZPositionsInOrder indexOfObject:@(aPanoramaMap.zPosition)];
            CGFloat zMax = aPanoramaMap.zPosition / 100.f;//It was multiplied 100 and stored as integer
            CGFloat zMin = NSIntegerMin;
            NSInteger lowerZPositionIndex = -1;
            if (zPositionIndex != NSNotFound) {
                lowerZPositionIndex = zPositionIndex - 1;
            }
            if (lowerZPositionIndex >= 0) {
                zMin = [(self.mMapZPositionsInOrder)[lowerZPositionIndex] floatValue] / 100.f;//It was multiplied 100 and stored as integer
            }
            
            NSMutableArray *correspondingNodes = [NSMutableArray array];
            for (NSString *nodeID in self.visibleNodesIDs) {
                IVPanoramaNode *node = [self nodeWithNodeID:nodeID];
                CGFloat x = [node coordX];
                CGFloat y = [node coordY];
                CGFloat z = [node coordZ];
                if (aPanoramaMap.xMin <= x && x <= aPanoramaMap.xMax &&
                    aPanoramaMap.yMin <= y && y <= aPanoramaMap.yMax &&
                    zMin <= z && z <= zMax) {
                    [correspondingNodes addObject:node];
                }
            }
            aPanoramaMap.correspondingNodes = correspondingNodes;
        }
        else if (curDoc.type == IVDocTypePanorama360) {
            NSMutableArray *correspondingNodes = [NSMutableArray array];
            for (NSString *nodeID in self.visibleNodesIDs) {
                IVPanoramaNode *node = [self nodeWithNodeID:nodeID];
//                CGFloat x = [node coordX];
//                CGFloat y = [node coordY];
                CGFloat z = [node coordZ];
                if (z == aPanoramaMap.zTarget) {
                    [correspondingNodes addObject:node];
                }
            }
            aPanoramaMap.correspondingNodes = correspondingNodes;
        }
	}
}

- (IVPanoramaMap *)currentMap {
	return [self mapAtIndex:currentMapIndex];
}

- (void)prepareMaps {
	self.mMapZPositionsInOrder = nil;
	if ([self.displayMapsDict count] == 0) {
        for (NSString *mapPath in [self mapPaths]) {
            IVPanoramaMap *aPanoramaMap = [self.xmlMapsDict objectForKey:[mapPath lastPathComponent]];
            if (aPanoramaMap) {
                aPanoramaMap.mapPath = mapPath;
            } else {
                aPanoramaMap = [IVPanoramaMap mapWithPath:mapPath];
            }
            if (aPanoramaMap) {
                (self.displayMapsDict)[mapPath] = aPanoramaMap;
            }
		}
		[self orderZPositions];
		[self distributeNodes];
	}
}

#pragma mark - Faces

- (NSString *)facePrefixForFace:(FaceTo)face {
    switch (face) {
        case FaceToFront:
        default:
            return [self objectForKey:@"front"];
        case FaceToLeft:
            return [self objectForKey:@"left"];
        case FaceToBack:
            return [self objectForKey:@"back"];
        case FaceToRight:
            return [self objectForKey:@"right"];
        case FaceToTop:
            return [self objectForKey:@"top"];
        case FaceToBottom:
            return [self objectForKey:@"bottom"];
    }
}

- (FaceTo)defaultFaceOfNode:(IVPanoramaNode*)theNode {
	if (!hasCalculatedNodesCenter) {
		[self calculateTheCenterOfNodes];
		hasCalculatedNodesCenter = YES;
	}
	
	Coordinate3D positonToCenterVector;
	positonToCenterVector.x = [theNode coordX] - nodesCenter.x;
	positonToCenterVector.y = [theNode coordY] - nodesCenter.y;
	positonToCenterVector.z = [theNode coordZ] - nodesCenter.z;
	
	if(CGAbs(positonToCenterVector.x) > CGAbs(positonToCenterVector.y) )
	{
		// X axis movement, right or left side of the cube
		if( positonToCenterVector.x < 0 )
		{
			return FaceToFront;
		}
		else
		{
			return FaceToBack;
		}
	}
	else
	{
		// Y axis movement, back or front side of the cube
		if( positonToCenterVector.y < 0 )
		{
			return FaceToLeft;
		}
		else
		{
			return FaceToRight;
		}
	}
}

- (float)trimAngle:(float)angle {
	if (angle > 360) {
		return [self trimAngle:(angle - 360)];
	} else if (angle < 0) {
		return [self trimAngle:(angle + 360)];
	} else {
		return angle;
	}
}

- (FaceTo)startAngleFace {
	FaceTo defaultFaceForStartNode = [self defaultFaceOfNode:[self startNode]];
	
	float startAngle = [[self objectForKey:@"angleH"] floatValue] + 180;
	
	startAngle = [self trimAngle:startAngle];
	
	FaceTo returnValue;
	if (startAngle == 45 && (defaultFaceForStartNode == FaceToBack || defaultFaceForStartNode == FaceToRight)) {
		returnValue = defaultFaceForStartNode;
	}
	else if (startAngle == 135 && (defaultFaceForStartNode == FaceToFront || defaultFaceForStartNode == FaceToRight)) {
		returnValue = defaultFaceForStartNode;
	}
	else if (startAngle == 225 && (defaultFaceForStartNode == FaceToFront || defaultFaceForStartNode == FaceToLeft)) {
		returnValue = defaultFaceForStartNode;
	}
	else if (startAngle == 315 && (defaultFaceForStartNode == FaceToBack || defaultFaceForStartNode == FaceToLeft)) {
		returnValue = defaultFaceForStartNode;
	}
	else if (startAngle < 45 || startAngle > 315) {
		returnValue = FaceToBack;
	}
	else if (startAngle > 45 && startAngle < 135) {
		returnValue = FaceToRight;
	}
	else if (startAngle > 135 && startAngle < 225) {
		returnValue = FaceToFront;
	}
	else if (startAngle > 225 && startAngle < 315) {
		returnValue = FaceToLeft;
	}
	else {
		returnValue = [self defaultFaceOfNode:[self startNode]];
	}
	
	return returnValue;
}

#pragma mark - Thumbnails

- (UIImage *)thumbnailImageOfNode:(NSString *)nodeID {
	NSData *data = [self.thumbnailImageDataCache objectForKey:nodeID];
	if (!data) {
		if (self.zipFile && ([self.zipFile isOpen] || [self.zipFile open])) {
			data = [self.zipFile readWithFileName:[self.rootFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"assets/t_%@.png",nodeID]] caseSensitive:YES maxLength:NSUIntegerMax];
            if (!data)
                data = [self.zipFile readWithFileName:[self.rootFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"assets/t_%@.jpg",nodeID]] caseSensitive:YES maxLength:NSUIntegerMax];
            if (!data &&
                (self.type == IVDocTypePanoramaV5 || self.type == IVDocTypePanorama360)) {
                NSString *formatPrefix = self.format[@"prefix"];
                NSString *facePrefix = [self facePrefixForFace:FaceToFront];
                NSString *lowImagePath = [self.rootFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"assets/%@%@%@.%@",@"l_",facePrefix,nodeID,@"jpg"]];
                NSString *normalImagePath = [self.rootFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"assets/%@%@%@.%@",formatPrefix,facePrefix,nodeID,@"jpg"]];
                data = [self.zipFile readWithFileName:lowImagePath caseSensitive:YES maxLength:NSUIntegerMax];
                if (!data)
                    [self.zipFile readWithFileName:normalImagePath caseSensitive:YES maxLength:NSUIntegerMax];
            }
		}
		if (data) {
			[self.thumbnailImageDataCache setObject:data forKey:nodeID];
		}
	}
	UIImage *returnImage = [UIImage imageWithData:data];
    if (!returnImage) {
        returnImage = [UIImage imageNamed:@"icon" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil];
    }
    return returnImage;
}

- (UIImage *)thumbnailImageOfVisibleNodeAtIndex:(NSUInteger)index {
	return [self thumbnailImageOfNode:self.visibleNodesIDs[index]];
}

#pragma mark - Annotations

- (NSString *)getCachePathOfAnnotationFile:(NSString *)fileName {
    if (!fileName || fileName.length == 0) {
        return nil;
    }
    NSString *cacheFilePath = [IVCacheManager cachePathForFileName:fileName subDir:[self uid]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheFilePath]) {
        if (self.zipFile && ([self.zipFile isOpen] || [self.zipFile open])) {
            [self.zipFile extractWithFileName:[[self.rootFolderPath stringByAppendingPathComponent:@"assets/annotations/"] stringByAppendingPathComponent:fileName]
                                caseSensitive:YES
                                    maxLength:NSUIntegerMax
                                       toPath:cacheFilePath];
        }
    }
    
    return cacheFilePath;
}

- (UIImage *)getCacheImageOfAnnotationFile:(NSString *)fileName {
    NSString *nodeIconImagePath = [self getCachePathOfAnnotationFile:fileName];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:nodeIconImagePath];
    
    if (!image) {
        CGFloat scale = [UIScreen mainScreen].scale;
        NSInteger imageSize = 30 * scale;
        image = [[UIImage imageNamed:@"img_node" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil] resizedImageByMagick:[NSString stringWithFormat:@"%ldx%ld",(long)imageSize,(long)imageSize]];
        image = [UIImage imageWithCGImage:image.CGImage scale:scale orientation:UIImageOrientationUp];
    }
    
    [self.overlayImagesCache setObject:image forKey:fileName];
    return image;
}

- (UIImage *)getNodeIconImage {
    return [self getCacheImageOfAnnotationFile:@"icon_lien.png"];
}

- (UIImage *)getAnnotationImageWithType:(IVPanoramaAnnotationType)type {
    switch (type) {
        default:
        case IVPanoramaAnnotationTypeUnkown:
            return [self getCacheImageOfAnnotationFile:@"icon_annotation.png"];
        case IVPanoramaAnnotationTypeCaptionImage:
            return [self getCacheImageOfAnnotationFile:@"icon_image.png"];
        case IVPanoramaAnnotationTypeCaptionVideo:
            return [self getCacheImageOfAnnotationFile:@"icon_video.png"];
        case IVPanoramaAnnotationTypeImage:
            return [self getCacheImageOfAnnotationFile:@"icon_image.png"];
        case IVPanoramaAnnotationTypeVideo:
            return [self getCacheImageOfAnnotationFile:@"icon_video.png"];
        case IVPanoramaAnnotationTypeOnlineWebsite:
            return [self getCacheImageOfAnnotationFile:@"icon_website.png"];
        case IVPanoramaAnnotationTypeCustom:
            return [self getCacheImageOfAnnotationFile:@"icon_annotation.png"];
    }
}

- (UIImage *)getLogo {
    NSString *logoFileName = self.logoAttributes[@"file"];
    NSString *logoFilePath = [self getCachePathOfAnnotationFile:logoFileName];
    UIImage *returnImage = [[UIImage alloc] initWithContentsOfFile:logoFilePath];
    return returnImage;
}

@end
