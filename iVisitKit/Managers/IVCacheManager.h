//
//  IVCacheManager.h
//  iVisit 3D
//
//  Created by Bob on 04/10/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVHeaders.h"

typedef NS_ENUM (NSInteger, CacheType) {
    CacheTypeUnknown = -1,
	CacheTypeDocument = 0,
	CacheTypePreview,
	CacheTypeBackground,
    CacheTypeCount
};

@interface IVCacheManager : NSObject

+ (instancetype)shared;

+ (void)cleanCacheWithReservedKeys:(NSArray *)reservedKeys;
+ (BOOL)setCacheData:(NSData *)data forKey:(NSString *)key type:(CacheType)type;
+ (NSData *)getCacheDataForKey:(NSString *)key type:(CacheType)type;
+ (BOOL)deleteCacheForKey:(NSString *)key type:(CacheType)type;

+ (NSString *)cachePathForFileName:(NSString *)fileName subDir:(NSString *)subDir;

@end
