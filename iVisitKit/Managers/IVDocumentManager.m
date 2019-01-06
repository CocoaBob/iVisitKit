//
//  IVDocumentManager.m
//  iVisit 3D
//
//  Created by Bob on 04/07/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVDocumentManager.h"

@interface IVDocumentManager ()

@end

@implementation IVDocumentManager

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

#pragma mark - Document Reading

+ (IVBaseDocument *)loadDocument:(NSString*)documentFilePath {
    __block IVBaseDocument *document = nil;
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Load XML
        NSData *xmlData = nil;
        NSString *rootFolderPath = nil;
        CBZipFile *zipFile = [[CBZipFile alloc] initWithFileAtPath:documentFilePath];
        if ([zipFile open]) {
            // Find root folder
            rootFolderPath = [[zipFile firstFileName] pathComponents][0];

            // Index all files
            if (![zipFile hasHashTable]) {
                [zipFile buildHashTable];
            }

            // Read XML data
            NSString *pathV360 = [rootFolderPath stringByAppendingPathComponent:@"assets/data.xml"];
            NSString *pathV5 = [rootFolderPath stringByAppendingPathComponent:@"assets/ivisit3d.xml"];
            NSString *pathV4 = [rootFolderPath stringByAppendingPathComponent:@"assets/promenadd.xml"];
            xmlData = [zipFile readWithFileName:pathV360 caseSensitive:YES maxLength:NSUIntegerMax];
            if (!xmlData)
                xmlData = [zipFile readWithFileName:pathV5 caseSensitive:YES maxLength:NSUIntegerMax];
            if (!xmlData)
                xmlData = [zipFile readWithFileName:pathV4 caseSensitive:YES maxLength:NSUIntegerMax];
            if (!xmlData)
                xmlData = [zipFile readWithFileName:pathV360 caseSensitive:NO maxLength:NSUIntegerMax];
            if (!xmlData)
                xmlData = [zipFile readWithFileName:pathV5 caseSensitive:NO maxLength:NSUIntegerMax];
            if (!xmlData)
                xmlData = [zipFile readWithFileName:pathV4 caseSensitive:NO maxLength:NSUIntegerMax];

            [zipFile close];
        }
        if (xmlData) {
            // Load document
            IVDocumentParser *docParser = [[IVDocumentParser alloc] initWithXMLData:xmlData];
            document = docParser.document;
            xmlData = nil;

            
            document.zipFile = zipFile;
            document.rootFolderPath = rootFolderPath;
        }
        else {
            document = [IVBaseDocument new];
        }

        // Basic attributes
        document.filePath = documentFilePath;
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:documentFilePath error:NULL];
        document.fileSize = fileAttributes[NSFileSize];
        document.fileDate = fileAttributes[NSFileModificationDate];
    });

    return document;
}

+ (NSString *)localisedStringFromDict:(NSDictionary *)stringDict {
    return stringDict[@"fr_fr"];
}

@end
