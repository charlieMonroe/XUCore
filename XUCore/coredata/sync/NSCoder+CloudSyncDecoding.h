//
//  NSCoder+CloudSyncDecoding.m
//  XUCore
//
//  Created by Charlie Monroe on 1/15/24.
//  Copyright © 2024 Charlie Monroe Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSCoder (CloudSyncDecoding)
-(nullable id)decodeAttributes;
-(nullable id)decodeChanges;
@end
