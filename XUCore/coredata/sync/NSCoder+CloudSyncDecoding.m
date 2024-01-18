//
//  NSCoder+CloudSyncDecoding.m
//  XUCore
//
//  Created by Charlie Monroe on 1/15/24.
//  Copyright © 2024 Charlie Monroe Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@implementation NSCoder (CloudSyncDecoding)

-(id)decodeAttributes {
	NSSet *classSet = [NSSet setWithObjects:
					   [NSArray class], [NSDictionary class],
					   [NSString class], [NSNumber class], [NSNull class], [NSData class],
					   [NSDecimalNumber class], [NSDate class],
					   nil
	];
	
	return [self decodeObjectOfClasses:classSet forKey:@"Attributes"];
}

-(id)decodeChanges {
	NSSet *classSet = [NSSet setWithObjects:
					   [NSArray class], [NSDictionary class],
					   NSClassFromString(@"XUCore.XUSyncChange"),
					   NSClassFromString(@"XUCore.XUAttributeSyncChange"),
					   NSClassFromString(@"XUCore.XUDeletionSyncChange"),
					   NSClassFromString(@"XUCore.XUInsertionSyncChange"),
					   NSClassFromString(@"XUCore.XURelationshipSyncChange"),
					   NSClassFromString(@"XUCore.XUToManyRelationshipAdditionSyncChange"),
					   NSClassFromString(@"XUCore.XUToManyRelationshipDeletionSyncChange"),
					   NSClassFromString(@"XUCore.XUToOneRelationshipSyncChange"),
					   [NSString class], [NSNumber class], [NSNull class], [NSDate class],
					   [NSDecimalNumber class], [NSData class],
					   nil
	];
	
	return [self decodeObjectOfClasses:classSet forKey:@"Changes"];
}

@end

