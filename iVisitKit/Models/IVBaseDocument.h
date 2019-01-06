//
//  BaseDocument.h
//  iVisit 3D
//
//  Created by Mengke WANG on 5/11/12.
//  Copyright (c) 2012 Abvent R&D. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IVConstants.h"
#import "IVBaseDataModel.h"

@class CBZipFile;

@interface IVBaseDocument : IVBaseDataModel

@property (nonatomic, assign) IVDocType type;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *fileBaseName;
@property (nonatomic, strong) NSString *imageFileBaseName;
@property (nonatomic, strong) NSString *uid;
@property (nonatomic, strong) NSNumber *fileSize;
@property (nonatomic, strong) NSDate *fileDate;
@property (nonatomic, strong) NSString *rootFolderPath;
@property (nonatomic, strong) CBZipFile *zipFile;

+ (NSString *)UIDOfFileAtPath:(NSString *)filePath;

- (NSString *)baseName;
- (NSString *)imageBaseName;

- (UIImage *)previewImage;
- (UIImage *)backgroundImage;
- (void)openDocument;
- (void)createCache;
- (void)emptyCache;

@end
