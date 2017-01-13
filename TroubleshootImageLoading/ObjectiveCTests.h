//
//  ObjectiveCTests.h
//  TroubleshootImageLoading
//
//  Created by Bertrand HOLVECK on 06/12/2016.
//  Copyright © 2016 HOLVECK Ingénieries. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>


@interface ObjectiveCTests : NSObject

- (instancetype _Nonnull)initWithAsset: (PHAsset * _Nonnull)asset NS_SWIFT_NAME(init(with:))NS_DESIGNATED_INITIALIZER;

- (void)testOneWithCompletion: (nullable void (^)(BOOL success))completion_block;
- (void)testTwoWithCompletion: (nullable void (^)(BOOL success))completion_block;

@end
