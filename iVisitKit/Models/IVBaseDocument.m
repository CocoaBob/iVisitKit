//
//  BaseDocument.m
//  iVisit 3D
//
//  Created by Mengke WANG on 5/11/12.
//  Copyright (c) 2012 Abvent R&D. All rights reserved.
//

#import "IVBaseDocument.h"

#import "IVHeaders.h"

@interface IVBaseDocument ()

@end

@implementation IVBaseDocument

+ (NSString *)UIDOfFileAtPath:(NSString *)filePath {
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL];
    if (!fileAttributes) {
        return nil;
    }
    NSTimeInterval modifDate = [fileAttributes[NSFileModificationDate] timeIntervalSince1970];
    NSString *fileSize = [fileAttributes[NSFileSize] stringValue];
    NSString *fileCharacteristics = [NSString stringWithFormat:@"%.0f-%@-%@",modifDate,fileSize,[filePath lastPathComponent]];
    NSString *returnValue = [fileCharacteristics md5];
    return returnValue;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        _type = [decoder decodeIntForKey:@"type"];
        _filePath = [decoder decodeObjectForKey:@"filePath"];
        _fileBaseName = [decoder decodeObjectForKey:@"fileBaseName"];
        _imageFileBaseName = [decoder decodeObjectForKey:@"imageFileBaseName"];
        _uid = [decoder decodeObjectForKey:@"uid"];
        _fileSize = [decoder decodeObjectForKey:@"fileSize"];
        _fileDate = [decoder decodeObjectForKey:@"fileDate"];
        _rootFolderPath = [decoder decodeObjectForKey:@"rootFolderPath"];
        _zipFile = [decoder decodeObjectForKey:@"zipFile"];
        _zipFile.path = _filePath;
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeInt:_type forKey:@"type"];
    [coder encodeObject:_filePath forKey:@"filePath"];
    [coder encodeObject:_fileBaseName forKey:@"fileBaseName"];
    [coder encodeObject:_imageFileBaseName forKey:@"imageFileBaseName"];
    [coder encodeObject:_uid forKey:@"uid"];
    [coder encodeObject:_fileSize forKey:@"fileSize"];
    [coder encodeObject:_fileDate forKey:@"fileDate"];
    [coder encodeObject:_rootFolderPath forKey:@"rootFolderPath"];
    [coder encodeObject:_zipFile forKey:@"zipFile"];
}

- (NSString *)baseName {
    if (!self.fileBaseName) {
        self.fileBaseName = self.filePath.lastPathComponent.stringByDeletingPathExtension;
    }
	return self.fileBaseName;
}

- (NSString *)imageBaseName {
    if (!self.imageFileBaseName) {
        self.imageFileBaseName = [self objectForKey:@"label"];
    }
    return self.imageFileBaseName;
}

#pragma mark - Previews

- (NSData *)getPreviewImageData {
    return nil;
}

- (UIImage *)previewImage {
    return [[IVImageManager shared] previewWithImageData:[self getPreviewImageData] cacheKey:[self uid]];
}

- (UIImage *)backgroundImage {
    return [[IVImageManager shared] backgroundWithImage:[self previewImage] cacheKey:[self uid]];
}

- (void)openDocument {

}

- (void)createCache {

}

- (void)emptyCache {

}

@end
