// 
// FCDataEntity.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCDataEntity.h"

static NSString *FCLastAccessDateKey = @"FCLastAccessDate";
static NSString *FCObjectKeyKey = @"FCObjectKey";


@implementation FCDataEntity

@synthesize dataStorage = _dataStorage, objectKey = _objectKey, lastAccessDate = _lastAccessDate;

-(void)encodeWithCoder:(NSCoder *)aCoder{
	NSKeyedArchiver *archiver = (NSKeyedArchiver*)aCoder;
	[archiver encodeObject:[self objectKey] forKey:FCObjectKeyKey];
	[archiver encodeInt64:[self lastAccessDate] forKey:FCLastAccessDateKey];
}
-(void)entityWillBeRemovedFromDataStorage{
	
}
-(void)entityWillGoIdle{

}
-(id)initWithCoder:(NSCoder *)aDecoder{
	self = [[[self class] alloc] init];
	
	NSKeyedUnarchiver *unarchiver = (NSKeyedUnarchiver*)aDecoder;
	[self setLastAccessDate:[unarchiver decodeInt64ForKey:FCLastAccessDateKey]];	
	[self setObjectKey:[unarchiver decodeObjectForKey:FCObjectKeyKey]];
	
	return self;
}
-(void)save{
	[[self dataStorage] saveObject:self];
}

@end



