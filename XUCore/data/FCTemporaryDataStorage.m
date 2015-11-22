// 
// FCTemporaryDataStorage.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCTemporaryDataStorage.h"
#import "FCDataEntity.h"

@interface FCPersistentDataStorage (Privates)
-(NSURL*)_objectDataURLForKey:(NSString*)key;
@end

@implementation FCTemporaryDataStorage

@synthesize maximumSize = _maximumSize;

+(FCPersistentDataStorage *)dataStorage{
	return [self dataStorageNamed:@"Temporary Storage"];
}
-(void)_cleanUp{
	long long needToClean = [self _storageSizeIsOverMaximumBy];
	if (needToClean < 0){
		// No need
		return;
	}
	
	while (needToClean > 0){
		FCDataEntity *obj = [self _leastAccessedObject];
		if (obj == nil){
			// Nothing left!
			break;
		}
		needToClean -= [self _sizeOfFileAtURL:[self _objectDataURLForKey:[obj objectKey]]];
		[self removeObjectForKey:[obj objectKey]];
	}
	
}
-(FCDataEntity*)_leastAccessedObject{
	FCDataEntity* last = nil;
	
	NSArray *items = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[self storageDirectoryURL] includingPropertiesForKeys:nil options:0 error:NULL];
	for (NSURL *item in items){
		if (![[item pathExtension] isEqualToString:@"obj"]){
			continue;
		}
		
		
		FCDataEntity *entity = [NSKeyedUnarchiver unarchiveObjectWithFile:[item path]];
		if ([entity lastAccessDate] < [last lastAccessDate] || last == nil){
			last = entity;
		}
	}
	
	return last;
}
-(unsigned long long)_sizeOfFileAtURL:(NSURL*)url{
	NSDictionary *atts = [[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:NULL];
	return [[atts objectForKey:NSFileSize] longLongValue];
}
-(long long)_storageSizeIsOverMaximumBy{
	if (_cachedSize == -1){
		long long fileSize = 0;
		NSFileManager *defaultManager = [NSFileManager defaultManager];
		NSArray *items = [defaultManager contentsOfDirectoryAtURL:[self storageDirectoryURL] includingPropertiesForKeys:nil options:0 error:NULL];
		for (NSURL *item in items){
			fileSize += [self _sizeOfFileAtURL:item];
		}
		_cachedSize = (NSInteger)fileSize;
	}
	
	return _cachedSize - [self maximumSize];
}
-(id)initWithName:(NSString *)name{
	if ((self = [super initWithName:name]) != nil){
		[self setMaximumSize:50 * 1024 * 1024]; // 50 MB
		_cachedSize = -1;
		
		[self _cleanUp];
	}
	return self;
}
-(void)removeObjectForKey:(NSString *)aKey{
	_cachedSize -= [self _sizeOfFileAtURL:[self _objectDataURLForKey:aKey]];
	[super removeObjectForKey:aKey];
}
-(void)setObject:(FCDataEntity*)object forKey:(NSString *)aKey{
	[super setObject:object forKey:aKey];
	
	_cachedSize += [self _sizeOfFileAtURL:[self _objectDataURLForKey:aKey]];
	
	[self _cleanUp];
}

@end

