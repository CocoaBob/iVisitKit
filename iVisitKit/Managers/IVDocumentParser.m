//
//  IVDocumentParser.m
//  iVisit 3D
//
//  Created by Bob on 04/07/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVDocumentParser.h"

#import "IVHeaders.h"

@interface IVDocumentParser ()

@property (nonatomic, strong) TBXML *xmlObj;

@end

@implementation IVDocumentParser

- (IVDocumentParser *)initWithXMLData:(NSData *)xmlData {
    self = [self init];
    if (self) {
        NSError *error = nil;
        self.xmlObj = [TBXML tbxmlWithXMLData:xmlData error:&error];
        if (error) {
            NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, [error localizedDescription], [error userInfo]);
            return nil;
        } else {
            [self createDocument];
        }
    }
    return self;
}

#pragma mark - Document Generation

- (void)createDocument {
    TBXMLElement *rootElement = [self.xmlObj rootXMLElement];
    NSString *rootElementName = [TBXML elementName:rootElement];
    if ([@"promenaddMaker" isEqualToString:rootElementName]) {
        [self preparePanorama];
        self.document.type = IVDocTypePanoramaV4;
    }
    else if ([@"iVisit3DMaker" isEqualToString:rootElementName]) {
        TBXMLElement *playerMode = [TBXML childElementNamed:@"playerMode" parentElement:rootElement];
        if (playerMode) {
            NSString *playerModeText = [TBXML textForElement:playerMode];
            if ([@"Panorama" isEqualToString:playerModeText]) {
                [self preparePanorama];
                TBXMLElement *config = [TBXML childElementNamed:@"config" parentElement:rootElement];
                NSString *output = [TBXML valueOfAttributeNamed:@"output" forElement:config];
                NSString *software = [TBXML valueOfAttributeNamed:@"software" forElement:config];
                if (output != nil || [@"iVisit360" isEqualToString:software]) {
                    self.document.type = IVDocTypePanorama360;
                } else {
                    self.document.type = IVDocTypePanoramaV5;
                }
            }
        }
    }
    if (!self.document) {
        self.document = [IVBaseDocument new];
    }
}

- (void)preparePanorama {
    IVPanoramaDocument *newDocument = [IVPanoramaDocument new];
    [TBXML handleElement:[self.xmlObj rootXMLElement]
                handlers:@{@"config":@{@"renderMode":@{kAnyNode:renderModeHandler},//face
                                       @"outputMode":@{@"format":outputModeHandler},
                                       @"startpoint":startPointHandler,
                                       @"icons":iconsHandler,
                                       @"logo":logoHandler},
                           @"content":@{@"crosspoints":@{kAnyNode:crossPointHandler},//crosspoint
                                        @"routes":@{kAnyNode:routeHandler},
                                        @"annotations":@{kAnyNode:annotationHandler},
                                        @"panoramaVersions":@{kAnyNode:panoramaVersionHandler}},//route
                           @"special":@{@"plans":@{kAnyNode:planHandler}}}//plan
                 context:(__bridge void *)(newDocument)
                    stop:NULL];
    self.document = newDocument;
}

#pragma mark - XML Handlers

TBXMLElementHandler renderModeHandler = ^void (TBXMLElement *element, void *context, BOOL *stop) {
    IVPanoramaDocument *newDocument = (__bridge IVPanoramaDocument *)context;
    [newDocument setObject:[TBXML valueOfAttributeNamed:@"prefix" forElement:element] forKey:[TBXML valueOfAttributeNamed:@"id" forElement:element]];
};

TBXMLElementHandler outputModeHandler = ^void (TBXMLElement *element, void *context, BOOL *stop) {
    if ([[TBXML valueOfAttributeNamed:@"id" forElement:element] isEqualToString:@"main"]) {
        IVPanoramaDocument *newDocument = (__bridge IVPanoramaDocument *)context;
        NSMutableDictionary *format = [NSMutableDictionary dictionary];
        [TBXML exportAttributes:element->firstAttribute toDictionary:&format];
        newDocument.format = format;
        *stop = YES;
    }
};

TBXMLElementHandler startPointHandler = ^void (TBXMLElement *element, void *context, BOOL *stop) {
    IVPanoramaDocument *newDocument = (__bridge IVPanoramaDocument *)context;
    [TBXML exportAttributes:element->firstAttribute toDictionary:(NSMutableDictionary **)&newDocument];
};

TBXMLElementHandler iconsHandler = ^void (TBXMLElement *element, void *context, BOOL *stop) {
    IVPanoramaDocument *newDocument = (__bridge IVPanoramaDocument *)context;
    
    NSMutableDictionary *iconsAttributes = [NSMutableDictionary dictionary];
    [TBXML exportAttributes:element->firstAttribute toDictionary:(NSMutableDictionary **)&iconsAttributes];
    newDocument.iconsAttributes = iconsAttributes;
};

TBXMLElementHandler logoHandler = ^void (TBXMLElement *element, void *context, BOOL *stop) {
    IVPanoramaDocument *newDocument = (__bridge IVPanoramaDocument *)context;
    
    NSMutableDictionary *logoAttributes = [NSMutableDictionary dictionary];
    [TBXML exportAttributes:element->firstAttribute toDictionary:(NSMutableDictionary **)&logoAttributes];
    newDocument.logoAttributes = logoAttributes;
};

TBXMLElementHandler crossPointLabelHandler = ^void (TBXMLElement *element, void *context, BOOL *stop) {
    IVPanoramaNode *node = (__bridge IVPanoramaNode *)context;
    NSMutableDictionary *labels = [NSMutableDictionary dictionary];
    [TBXML exportElements:element->firstChild toDictionary:&labels];
    [node setObject:labels forKey:@"label"];
};

TBXMLElementHandler crossPointFrameHandler = ^void (TBXMLElement *element, void *context, BOOL *stop) {
    IVPanoramaNode *node = (__bridge IVPanoramaNode *)context;
    [TBXML exportAttributes:element->firstAttribute toDictionary:(NSMutableDictionary **)&node];
};

TBXMLElementHandler crossPointHandler = ^void (TBXMLElement *element, void *context, BOOL *stop) {
    IVPanoramaDocument *newDocument = (__bridge IVPanoramaDocument *)context;

    IVPanoramaNode *node = [IVPanoramaNode new];
    [TBXML exportAttributes:element->firstAttribute toDictionary:(NSMutableDictionary **)&node];
    [TBXML handleElement:element
                handlers:@{@"label":crossPointLabelHandler,
                           @"frame":crossPointFrameHandler}
                 context:(__bridge void *)(node)
                    stop:stop];
    NSString *nodeID = [node objectForKey:@"id"];
    [newDocument.allNodesDict setObject:node forKey:nodeID];

    NSString *versionType = node[@"versionType"];
    if (!versionType || // XML V4/V5
        ![versionType isEqualToString:@"1"]) { // XML V360
        [newDocument.visibleNodesIDs addObject:nodeID];
    }
};

TBXMLElementHandler routeHandler = ^void (TBXMLElement *element, void *context, BOOL *stop) {
    IVPanoramaDocument *newDocument = (__bridge IVPanoramaDocument *)context;
    NSMutableDictionary *route = [NSMutableDictionary dictionary];
    [TBXML exportAttributes:element->firstAttribute toDictionary:&route];
    newDocument.routesDict[route[@"id"]] = route;
};

TBXMLElementHandler annotationHandler = ^void (TBXMLElement *element, void *context, BOOL *stop) {
    IVPanoramaDocument *newDocument = (__bridge IVPanoramaDocument *)context;
    
    IVPanoramaAnnotation *newAnnotation = [IVPanoramaAnnotation new];
    [TBXML exportAttributes:element->firstAttribute toDictionary:(NSMutableDictionary **)&newAnnotation];
    
    NSString *annotName = newAnnotation[@"annotName"];
    IVPanoramaAnnotation *exsitingAnnotation = newDocument.annotationsDict[annotName];
    
    // Since Dec 2015, it's possbile to have duplicated annotNames
    IVPanoramaAnnotation *annotation = newAnnotation;
    IVPanoramaAnnotation *polygonAnnotation = nil;
    if (exsitingAnnotation) {
        if (newAnnotation[@"isPolygonAnnot"] && [@"1" isEqualToString:newAnnotation[@"isPolygonAnnot"]] &&
            exsitingAnnotation[@"isClickable"] && [@"1" isEqualToString:exsitingAnnotation[@"isClickable"]]) {
            annotation = exsitingAnnotation;
            polygonAnnotation = newAnnotation;
        } else if (exsitingAnnotation[@"isPolygonAnnot"] && [@"1" isEqualToString:exsitingAnnotation[@"isPolygonAnnot"]] &&
                   newAnnotation[@"isClickable"] && [@"1" isEqualToString:newAnnotation[@"isClickable"]]) {
            annotation = newAnnotation;
            polygonAnnotation = exsitingAnnotation;
        }
    }
    
    
    if (polygonAnnotation) {
        annotation[@"captionWidth"] = polygonAnnotation[@"captionWidth"];
        annotation[@"captionHeight"] = polygonAnnotation[@"captionHeight"];
        
        // If annotInfos is empty, it's transparent
        if (!annotation[@"annotInfos"] || [@"" isEqualToString:annotation[@"annotInfos"]]) {
            annotation.isTransparent = YES;
        }
        
        // Remember alias annotation's type and annotInfos
        annotation.aliasType = [IVPanoramaAnnotation typeOfTypeString:polygonAnnotation[@"annotType"] isImage:polygonAnnotation[@"isImage"]];
        annotation.aliasAnnotInfos = polygonAnnotation[@"annotInfos"];
    }
    
    annotation.type = [IVPanoramaAnnotation typeOfTypeString:annotation[@"annotType"] isImage:annotation[@"isImage"]];
    
    newDocument.annotationsDict[annotName] = annotation;
};

TBXMLElementHandler panoramaVersionHandler = ^void (TBXMLElement *element, void *context, BOOL *stop) {
    IVPanoramaDocument *newDocument = (__bridge IVPanoramaDocument *)context;
    
    NSMutableDictionary *versionDict = [NSMutableDictionary dictionary];
    [TBXML exportAttributes:element->firstAttribute toDictionary:&versionDict];
    
    NSString *versionIDListString = versionDict[@"versionIdList"];
    NSArray *versionIDs = [versionIDListString componentsSeparatedByString:@"|;;;;|"];
    if (versionIDs && versionIDs.count > 0) {
        [newDocument.nodesVersions addObject:versionIDs];
    }
//    NSDictionary *tempDictToAvoidReleasingByARC = versionDict;
};

TBXMLElementHandler planAngleHandler = ^void (TBXMLElement *element, void *context, BOOL *stop) {
    IVPanoramaMap *panoramaMap = (__bridge IVPanoramaMap *)context;
    panoramaMap.angle = [[TBXML textForElement:element] floatValue];
};

TBXMLElementHandler planCoordHandler = ^void (TBXMLElement *element, void *context, BOOL *stop) {
    IVPanoramaMap *panoramaMap = (__bridge IVPanoramaMap *)context;
    Coordinate3D newCoord;
    TBXMLAttribute *attribute = element->firstAttribute;
    while (attribute) {
        NSString *name = [TBXML attributeName:attribute];
        float value = [[TBXML attributeValue:attribute] floatValue];
        if ([@"coordX" isEqualToString:name]) {
            newCoord.x = value;
        } else if ([@"coordY" isEqualToString:name]) {
            newCoord.y = value;
        } else if ([@"coordZ" isEqualToString:name]) {
            newCoord.z = value;
        }
        attribute = attribute->next;
    }
    if ([@"bottomRight" isEqualToString:[TBXML elementName:element]]) {//bottomRight
        panoramaMap.coord1 = newCoord;
    }
    else {//topLeft
        panoramaMap.coord2 = newCoord;
    }
};

TBXMLElementHandler planHandler = ^void (TBXMLElement *element, void *context, BOOL *stop) {
    IVPanoramaDocument *newDocument = (__bridge IVPanoramaDocument *)context;

    IVPanoramaMap *panoramaMap = [IVPanoramaMap new];

    [TBXML handleElement:element
                handlers:@{@"angle":planAngleHandler,
                           kAnyNode:planCoordHandler}
                 context:(__bridge void *)(panoramaMap)
                    stop:stop];

    panoramaMap.mapPath = [TBXML valueOfAttributeNamed:@"fileName" forElement:element];
    panoramaMap.mapName = [TBXML valueOfAttributeNamed:@"planName" forElement:element];

    [panoramaMap calculateValues];

    newDocument.xmlMapsDict[panoramaMap.mapPath] = panoramaMap;
};

@end
