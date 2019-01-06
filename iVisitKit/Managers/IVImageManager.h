//
//  IVImageManager.h
//  iVisit 3D
//
//  Created by Bob on 10/10/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVHeaders.h"

@interface IVImageManager : NSObject

+ (instancetype)shared;

- (UIImage *)previewWithImageData:(NSData *)imageData cacheKey:(NSString *)cacheKey;
- (UIImage *)backgroundWithImage:(UIImage *)image cacheKey:(NSString *)cacheKey;

// Shared images
- (UIImage *)imageForDownloadPage;
- (UIImage *)imageForMapNode;
- (UIImage *)imageForSelectedMapNode;

// Properties

@end
