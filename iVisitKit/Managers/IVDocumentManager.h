//
//  IVDocumentManager.h
//  iVisit 3D
//
//  Created by Bob on 04/07/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVHeaders.h"

@class IVBaseDocument;

@interface IVDocumentManager : NSObject

@property (nonatomic, strong) IVBaseDocument *currentOpeningDocument;

+ (instancetype)shared;
+ (IVBaseDocument *)loadDocument:(NSString*)documentFilePath;
+ (NSString *)localisedStringFromDict:(NSDictionary *)stringDict;

@end
