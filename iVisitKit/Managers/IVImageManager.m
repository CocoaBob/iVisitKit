//
//  IVImageManager.m
//  iVisit 3D
//
//  Created by Bob on 10/10/13.
//  Copyright (c) 2013 Abvent R&D. All rights reserved.
//

#import "IVImageManager.h"

@interface IVImageManager ()

@property (nonatomic, strong) UIImage *mImageNodeSmall,*mImageNodeSmallSelected,*mImageDownloadPage;

@end

@implementation IVImageManager {
    dispatch_queue_t imageProcessingQueue;
    int imageProcessingQueueSpecificKey;
}

#pragma mark - Static Class Features

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

#pragma mark - 

- (instancetype)init {
    self = [super init];
    if (self) {
        imageProcessingQueue = dispatch_queue_create("com.abvent.iVisit360.imageProcessingQueue", NULL);
        CFStringRef specificValue = CFSTR("queuecom.abvent.iVisit360.imageProcessingQueueA");
        dispatch_queue_set_specific(imageProcessingQueue,
                                    &imageProcessingQueueSpecificKey,
                                    (void*)specificValue,
                                    (dispatch_function_t)CFRelease);
    }
    return self;
}

#pragma mark - 

- (UIImage *)previewWithImageData:(NSData *)imageData cacheKey:(NSString *)cacheKey {
    if (!imageData && !cacheKey)
        return nil;
    
    __block NSData *previewImageData = [IVCacheManager getCacheDataForKey:cacheKey type:CacheTypePreview];
    if (!previewImageData) {
        dispatch_block_t tempBlock = ^ {
            previewImageData = GeneratePreviewImageData(imageData);
        };
        
        if (dispatch_get_specific(&imageProcessingQueueSpecificKey)) {
            tempBlock();
        }
        else {
            dispatch_sync(imageProcessingQueue, ^{
                tempBlock();
            });
        }
        
        if (previewImageData) {
            [IVCacheManager setCacheData:previewImageData forKey:cacheKey type:CacheTypePreview];
        }
    }
    UIImage *returnImage = [UIImage imageWithData:previewImageData];
    if (!returnImage) {
        returnImage = [UIImage imageNamed:@"iTunesArtwork" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil];
    }
    return returnImage;
}

- (UIImage *)backgroundWithImage:(UIImage *)image cacheKey:(NSString *)cacheKey {
    if (!image && !cacheKey)
        return nil;
    
    __block NSData *backgroundImageData = [IVCacheManager getCacheDataForKey:cacheKey type:CacheTypeBackground];
    if (!backgroundImageData) {
        dispatch_block_t tempBlock = ^ {
            backgroundImageData = GenerateBackgroundImageData(image);
        };
        
        if (dispatch_get_specific(&imageProcessingQueueSpecificKey)) {
            tempBlock();
        }
        else {
            dispatch_sync(imageProcessingQueue, ^{
                tempBlock();
            });
        }
        
        if (backgroundImageData) {
            [IVCacheManager setCacheData:backgroundImageData forKey:cacheKey type:CacheTypeBackground];
        }
    }
    UIImage *returnImage = [[UIImage alloc] initWithData:backgroundImageData];
    if (!returnImage) {
        returnImage = [UIImage imageNamed:@"img_bg_default" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil];
    }
    return returnImage;
}

#pragma mark - 

NSData * (^GeneratePreviewImageData)(NSData* inImageData) = ^NSData * (NSData* inImageData)
{
    NSInteger maxPreviewSize = 512;
    NSData *returnValue = inImageData;

    // Resize if necessary
    if (returnValue) {
        UIImage *processedImage = [[UIImage alloc] initWithData:returnValue];
        if (MIN(processedImage.size.width, processedImage.size.height) > maxPreviewSize) {
            processedImage = [processedImage resizedImageWithMinimumSize:CGSizeMake(maxPreviewSize, maxPreviewSize)];
            if (processedImage) {
                returnValue = UIImageJPEGRepresentation(processedImage, 0.6);
            }
        }
    }
    return returnValue;
};

NSData * (^GenerateBackgroundImageData)(UIImage* inImage) = ^NSData * (UIImage* inImage)
{
    NSData *returnValue = nil;

    // Resize
    NSUInteger maxBGSize = 512;
    UIImage *resizedImage = [inImage resizedImageByMagick:[NSString stringWithFormat:@"%lux%lu",(unsigned long)maxBGSize,(unsigned long)maxBGSize]];

    // Add effects
    if (resizedImage) {
        CIImage *inputImage = [[CIImage alloc] initWithCGImage:resizedImage.CGImage options:nil];
        // Darker
        CIImage *resultImage = [[CIFilter filterWithName:@"CIExposureAdjust" keysAndValues:kCIInputImageKey, inputImage, @"inputEV", @(-1), nil] outputImage];

        // Blur
        resultImage = [[CIFilter filterWithName:@"CIGaussianBlur" keysAndValues:kCIInputImageKey, resultImage, @"inputRadius", @(2), nil] outputImage];

        // Processing
        static CIContext *context = nil;
        if (!context) context = [CIContext contextWithOptions:nil];
        UIImage *processedImage = [UIImage imageWithCGImage:[context createCGImage:resultImage fromRect:CGRectInset([inputImage extent], 4, 4)]];

        // Save as JPG image data
        if (processedImage) {
            returnValue = UIImageJPEGRepresentation(processedImage,0.6);
        }
        else {
            returnValue = UIImageJPEGRepresentation(resizedImage,0.6);
        }
    }

    return returnValue;
};

#pragma mark - Shared images

- (UIImage *)imageForDownloadPage {
    if (!self.mImageDownloadPage) {
        self.mImageDownloadPage = [UIImage imageNamed:@"img_plus" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil];
    }
    return self.mImageDownloadPage;
}

- (UIImage *)imageForMapNode {
	if (!self.mImageNodeSmall) {
		self.mImageNodeSmall = [UIImage imageNamed:@"img_node_s" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil];
	}
	return self.mImageNodeSmall;
}

- (UIImage *)imageForSelectedMapNode {
	if (!self.mImageNodeSmallSelected) {
		self.mImageNodeSmallSelected = [UIImage imageNamed:@"img_node_s_highlight" inBundle:[NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"Images.bundle"]] compatibleWithTraitCollection:nil];
	}
	return self.mImageNodeSmallSelected;
}

#pragma mark - 

@end
