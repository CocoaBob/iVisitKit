//
//  IVCacheManager.m
//  iVisit 3D
//
//  Created by Bob on 04/10/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVCacheManager.h"

@interface IVCacheManager ()

@property (nonatomic, strong) NSCache *documentCache;
@property (nonatomic, strong) NSCache *previewCache;
@property (nonatomic, strong) NSCache *backgroundCache;

@end

@implementation IVCacheManager

static NSString *_cachesDirectory;

#pragma mark - Object Lifecycle

+ (instancetype)shared {
    static id __sharedInstance = nil;
    if (__sharedInstance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            __sharedInstance = [[[self class] alloc] init];
        });
    }
    return __sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.documentCache = [NSCache new];
        self.previewCache = [NSCache new];
        self.backgroundCache = [NSCache new];
    }
    return self;
}

+ (NSString *)sysVerStr {
    static NSString *_sysVerStr = nil;
    if (!_sysVerStr) {
        _sysVerStr = [[UIDevice currentDevice] systemVersion];
    }
    return _sysVerStr;
}

+ (NSString *)appVerStr {
    static NSString *_appVerStr = nil;
    if (!_appVerStr) {
        _appVerStr = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    }
    return _appVerStr;
}

#pragma mark - Public

// Clean all the cached files except reserved ones
+ (void)cleanCacheWithReservedKeys:(NSArray *)reservedKeys {
    NSString *cachesDirectory = [self cachesDirectory];
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cachesDirectory error:NULL];
    
    // Remove cache directories in Cache directory
    [contents enumerateObjectsUsingBlock:^(NSString *fileName, NSUInteger idx, BOOL *stop) {
        NSString *filePath = [cachesDirectory stringByAppendingPathComponent:fileName];
        NSString *fileBaseName = [fileName stringByDeletingPathExtension];
        NSString *fileExtension = [fileName pathExtension];
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir] &&    // File exists
            isDir &&                                                                            // Is a directory
            [@"Cache" isEqualToString:fileExtension] &&                                         // Cache directories
            ![reservedKeys containsObject:fileBaseName]) {                                      // Nonexistent files
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
        }
    }];
    
    // Remove cache files in Cache directory
    NSString *sysVerStr = [IVCacheManager sysVerStr];
//    NSInteger sysVerStrLength = [sysVerStr length];
    NSString *appVerStr = [IVCacheManager appVerStr];
//    NSInteger appVerStrLength = [appVerStr length];
    [contents enumerateObjectsUsingBlock:^(NSString *fileName, NSUInteger idx, BOOL *stop) {
        NSString *filePath = [cachesDirectory stringByAppendingPathComponent:fileName];
        NSString *fileBaseName = [fileName stringByDeletingPathExtension];
        NSArray *fileBaseNameComponents = [fileBaseName componentsSeparatedByString:@"_"];
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir] &&    // File exists
            !isDir &&                                                                           // Is a file
            [fileName hasSuffix:@"Cache"] &&                                                    // Is iVisit 3D cache file
            (fileBaseNameComponents.count != 3 ||                                               // Is current cache file name format
             ![fileBaseNameComponents[1] isEqualToString:sysVerStr] ||                          // Old Sys Versions
             ![fileBaseNameComponents[2] isEqualToString:appVerStr] ||                          // Old App Versions
             ![reservedKeys containsObject:fileBaseNameComponents[0]])) {                       // Same sys/app versions but nonexistent files
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
            }
    }];
    
}

+ (BOOL)setCacheData:(NSData *)data forKey:(NSString *)key type:(CacheType)type {
    if (!data || !key || type <= CacheTypeUnknown || type >= CacheTypeCount)
        return NO;
    
    __block BOOL returnValue = NO;

    dispatch_block_t tempBlock = ^ {
        NSCache *ramCache = [self ramCacheOfType:type];
        // Cache in ram
        [ramCache setObject:data forKey:key];
        // Cache in disk
        NSString *cachePath = [self pathOfCacheWithKey:key type:type];
        returnValue = [data writeToFile:cachePath atomically:YES];
    };
    
    if ([NSThread isMainThread]) {
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            tempBlock();
        });
    }
    else {
        tempBlock();
    }

    return returnValue;
}

+ (NSData *)getCacheDataForKey:(NSString *)key type:(CacheType)type {
    if (!key || type <= CacheTypeUnknown || type >= CacheTypeCount)
        return nil;
    
    __block NSData *returnValue = nil;

    dispatch_block_t tempBlock = ^ {
        NSCache *ramCache = [self ramCacheOfType:type];

        // Check ram cache
        returnValue = [ramCache objectForKey:key];

        // Check disk cache
        if (!returnValue) {
            NSString *cachePath = [self pathOfCacheWithKey:key type:type];
            returnValue  = [NSData dataWithContentsOfFile:cachePath];
            // Cache in ram
            if (returnValue) {
                [ramCache setObject:returnValue forKey:key];
            }
        }
    };
    
    if ([NSThread isMainThread]) {
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            tempBlock();
        });
    }
    else {
        tempBlock();
    }

    return returnValue;
}

+ (BOOL)deleteCacheForKey:(NSString *)key type:(CacheType)type {
    if (!key || type <= CacheTypeUnknown || type >= CacheTypeCount)
        return NO;
    
    __block BOOL returnValue = NO;

    dispatch_block_t tempBlock = ^ {
        NSCache *ramCache = [self ramCacheOfType:type];
        [ramCache removeObjectForKey:key];
        returnValue = [[NSFileManager defaultManager] removeItemAtPath:[self pathOfCacheWithKey:key type:type] error:NULL];
    };

    if ([NSThread isMainThread]) {
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            tempBlock();
        });
    }
    else {
        tempBlock();
    }

    return returnValue;
}

+ (NSString *)cachePathForFileName:(NSString *)fileName subDir:(NSString *)subDir {
    return [[[self cachesDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.Cache",subDir]] stringByAppendingPathComponent:fileName];
}

#pragma mark - Private

+ (NSString *)cachesDirectory {
    if (!_cachesDirectory) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        if ([paths count] > 0) {
            _cachesDirectory = paths[0];
        }
    }
    return _cachesDirectory;
}

+ (NSString *)pathOfCacheWithKey:(NSString *)key type:(CacheType)type {
    NSString *sysVerStr = [IVCacheManager sysVerStr];
    NSString *appVerStr = [IVCacheManager appVerStr];
    return [[self cachesDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@_%@%@",key,sysVerStr,appVerStr,[self suffixOfType:type]]];
}

+ (NSString *)suffixOfType:(CacheType)cacheType {
    switch (cacheType) {
        case CacheTypeDocument:
            return @".docCache";
            break;
        case CacheTypePreview:
            return @".pviCache";
            break;
        case CacheTypeBackground:
            return @".bgiCache";
            break;
        default:
            return nil;
            break;
    }
}

+ (NSCache *)ramCacheOfType:(CacheType)cacheType {
    switch (cacheType) {
        case CacheTypeDocument:
            return [IVCacheManager shared].documentCache;
            break;
        case CacheTypePreview:
            return [IVCacheManager shared].previewCache;
            break;
        case CacheTypeBackground:
            return [IVCacheManager shared].backgroundCache;
            break;
        default:
            return nil;
            break;
    }
}

@end
