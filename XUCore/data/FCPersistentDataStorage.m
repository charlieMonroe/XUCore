// 
// FCPersistentDataStorage.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-16 Charlie Monroe Software. All rights reserved.
// 


#import "FCPersistentDataStorage.h"
#import "NSArrayAdditions.h"
#import "NSStringAdditions.h"
#import "FCDataEntity.h"

static NSMutableDictionary *_dataStorages;

NSString *FCPersistentDataStorageObjectWasAddedNotification = @"FCPersistentDataStorageObjectWasAddedNotification";
NSString *FCPersistentDataStorageObjectWasRemovedNotification = @"FCPersistentDataStorageObjectWasRemovedNotification";

static NSString *FCPersistentDataStorageVersionUsedDefaultsKey = @"FCPersistentDataStorageVersion";

// 0 - initial version. Used hashed keys
// 1 - uses objectKey for file name to reduce object unarchiving
#define FCPersistentDataStorageCurrentVersion ((NSInteger)1)

@implementation FCPersistentDataStorage

+(FCPersistentDataStorage *)dataStorage{
	return [self dataStorageNamed:@"Persistent Storage"];
}
+(FCPersistentDataStorage *)dataStorageNamed:(NSString *)name{
	@synchronized (self){
		if (_dataStorages == nil){
			_dataStorages = [[NSMutableDictionary alloc] initWithCapacity:1];
		}
		
		FCPersistentDataStorage *storage = [_dataStorages objectForKey:name];
		if (storage != nil){
			return storage;
		}
		
		storage = [[self alloc] initWithName:name];
		[_dataStorages setObject:storage forKey:name];
		
		return storage;
	}
}

-(NSURL*)_applicationSupportDirectoryURL{
	NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	NSURL *appSuppDir = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject]];
	NSURL *appAppSuppDir = [appSuppDir URLByAppendingPathComponent:bundleIdentifier];
	[[NSFileManager defaultManager] createDirectoryAtURL:appAppSuppDir withIntermediateDirectories:YES attributes:nil error:NULL];
	return appAppSuppDir;
}
-(id)_loadObjectAtURL:(NSURL*)url{
	id entity = [NSKeyedUnarchiver unarchiveObjectWithFile:[url path]];
	[entity setDataStorage:self];
	
	return entity;
}
-(void)_migrateStorageToUseObjectKeyFileNames{
	NSFileManager *fileMan = [NSFileManager defaultManager];
	NSArray *items = [fileMan contentsOfDirectoryAtURL:[self _storageDirectoryURL] includingPropertiesForKeys:nil options:0 error:NULL];
	for (NSURL *item in items){
		if (![[item pathExtension] isEqualToString:@"obj"]){
			continue;
		}
		
		// objectForKey: loads an item if needed
		FCDataEntity *entity = [self _loadObjectAtURL:item];
		NSURL *newURL = [self _objectDataURLForKey:[entity objectKey]];
		[fileMan moveItemAtURL:item toURL:newURL error:NULL];
	}
}
-(NSURL*)_objectDataURLForKey:(NSString*)key{
	NSString *objFileName = [key stringByAppendingPathExtension:@"obj"];
	return [[self _storageDirectoryURL] URLByAppendingPathComponent:objFileName];
}
-(void)_saveObject:(id)obj toURL:(NSURL*)url{
	[obj setLastAccessDate:[[NSDate date] timeIntervalSince1970]];
	
	[NSKeyedArchiver archiveRootObject:obj toFile:[url path]];
}
-(NSURL*)_storageDirectoryURL{
	NSURL *storage = [[self _applicationSupportDirectoryURL] URLByAppendingPathComponent:_name];
	[[NSFileManager defaultManager] createDirectoryAtURL:storage withIntermediateDirectories:YES attributes:nil error:NULL];
	return storage;
}
-(NSArray *)allItems{
	NSArray *items = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[self _storageDirectoryURL] includingPropertiesForKeys:nil options:0 error:NULL];
	for (NSURL *item in items){
		if (![[item pathExtension] isEqualToString:@"obj"]){
			continue;
		}
		
		NSString *key = [[item lastPathComponent] stringByDeletingPathExtension];
		if ([_memoryCache objectForKey:key] == nil){
			FCDataEntity *entity = [self _loadObjectAtURL:item];
			[_memoryCache setObject:entity forKey:[entity objectKey]];
		}
	}
	return [_memoryCache allValues];
}
-(void)clearMemoryCache{
	[_memoryCache removeAllObjects];
}
-(BOOL)containsObjectForKey:(NSString*)key{
	return [_memoryCache objectForKey:key] != nil || [[NSFileManager defaultManager] fileExistsAtPath:[[self _objectDataURLForKey:key] path]];
}
-(id)initWithName:(NSString *)name{
	if ((self = [super init]) != nil){
		_name = name;
		_memoryCache = [[NSMutableDictionary alloc] initWithCapacity:1];
		
		NSInteger storageVersion = [[NSUserDefaults standardUserDefaults] integerForKey:FCPersistentDataStorageVersionUsedDefaultsKey];
		if (storageVersion != FCPersistentDataStorageCurrentVersion){
			// Right now the only migration is of the file names.
			[self _migrateStorageToUseObjectKeyFileNames];
		}
		[[NSUserDefaults standardUserDefaults] setInteger:FCPersistentDataStorageCurrentVersion forKey:FCPersistentDataStorageVersionUsedDefaultsKey];
	}
	return self;
}
-(NSInteger)numberOfItems{
	return [[[NSFileManager defaultManager] contentsOfDirectoryAtURL:[self _storageDirectoryURL] includingPropertiesForKeys:nil options:0 error:NULL] count:^ (id obj) {
		return [[obj pathExtension] isEqualToString:@"obj"];
	}];
}
-(id)objectForKey:(NSString *)key{
	if ([_memoryCache objectForKey:key] != nil){
		FCDataEntity *obj = [_memoryCache objectForKey:key];
		[obj setLastAccessDate:[[NSDate date] timeIntervalSince1970]];
		return obj;
	}
	
	id obj = [self _loadObjectAtURL:[self _objectDataURLForKey:key]];
	if (obj == nil){
		return nil;
	}
	
	[obj setLastAccessDate:[[NSDate date] timeIntervalSince1970]];
	[_memoryCache setObject:obj forKey:key];
	return obj;
}
-(void)removeObjectForKey:(NSString*)aKey{
	id obj = [_memoryCache objectForKey:aKey];
	
	[obj entityWillBeRemovedFromDataStorage];
	[obj setDataStorage:nil];
	
	[_memoryCache removeObjectForKey:aKey];
	[[NSFileManager defaultManager] removeItemAtURL:[self _objectDataURLForKey:aKey] error:NULL];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:FCPersistentDataStorageObjectWasRemovedNotification object:self];
}
-(void)saveObject:(FCDataEntity*)object{
	[self setObject:object forKey:[object objectKey]];
}
-(void)setObject:(FCDataEntity*)object forKey:(NSString*)aKey{
	[object setDataStorage:self];
	
	[_memoryCache setObject:object forKey:aKey];
	[self _saveObject:object toURL:[self _objectDataURLForKey:aKey]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:FCPersistentDataStorageObjectWasAddedNotification object:self];
}
-(NSURL*)storageDirectoryURL{
	return [self _storageDirectoryURL];
}

@end

