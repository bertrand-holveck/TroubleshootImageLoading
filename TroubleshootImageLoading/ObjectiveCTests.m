//
//  ObjectiveCTests.m
//  TroubleshootImageLoading
//
//  Created by Bertrand HOLVECK on 06/12/2016.
//  Copyright © 2016 HOLVECK Ingénieries. All rights reserved.
//

#import "ObjectiveCTests.h"

@interface ObjectiveCTests()

@property (copy, nonatomic) PHAsset *imageAsset;

@end



@implementation ObjectiveCTests

@synthesize imageAsset;

- (instancetype)init
{
    self = [self initWithAsset: [PHAsset new]];
    return nil;
}

- (instancetype)initWithAsset: (PHAsset *)asset
{
    if (self = [super init]) {
        self.imageAsset = asset;
    }
    return self;
}


/*!
 * The purpose of this test is to show the original context in which I encountered the bug.
 */
- (void)testOneWithCompletion: (nullable void (^)(BOOL success))completion_block
{
    for (unsigned int i = 0; i < 1000; ++i) {
        fprintf(stderr, ".");
        __block UIImage *image = nil;

        // read the image
        PHImageRequestOptions *imRequestOptions = [PHImageRequestOptions new];
        imRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
        imRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        imRequestOptions.synchronous = YES;
        imRequestOptions.networkAccessAllowed = YES;

        [[PHImageManager defaultManager] requestImageForAsset:self.imageAsset targetSize:CGSizeMake(640, 480) contentMode:PHImageContentModeAspectFill options:imRequestOptions resultHandler:^(UIImage *theImage, NSDictionary *info) {
            image = theImage;
        }];

        CGDataProviderRef provider = CGImageGetDataProvider(image.CGImage);
        CFDataRef rawData = CGDataProviderCopyData(provider);
        CFRelease(rawData);
    }

    completion_block(YES);
}

/*!
 * The second test shows something I went trough while troubleshooting, and is only possible to
 * test in Obj-C. It shows that if we CFRelease the CGDataProvider, the memory doesn't grow. But
 * as we are not supposed, at end of the loop, all the thousand CGDataProviders are CFReleased
 * and then the app crashes as this results in double frees.
 */
- (void)testTwoWithCompletion: (nullable void (^)(BOOL success))completion_block
{
    for (unsigned int i = 0; i < 1000; ++i) {
        fprintf(stderr, ".");
        __block UIImage *image = nil;

        // read the image
        PHImageRequestOptions *imRequestOptions = [PHImageRequestOptions new];
        imRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
        imRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        imRequestOptions.synchronous = YES;
        imRequestOptions.networkAccessAllowed = YES;

        [[PHImageManager defaultManager] requestImageForAsset:self.imageAsset targetSize:CGSizeMake(640, 480) contentMode:PHImageContentModeAspectFill options:imRequestOptions resultHandler:^(UIImage *theImage, NSDictionary *info) {
            image = theImage;
        }];

        CGDataProviderRef provider = CGImageGetDataProvider(image.CGImage);
        CFDataRef rawData = CGDataProviderCopyData(provider);
        CFRelease(rawData);
        CFRelease(provider);
    }

    completion_block(YES);
}

@end
