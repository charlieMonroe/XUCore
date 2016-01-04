// 
// FCPersistentDataStorage.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-16 Charlie Monroe Software. All rights reserved.
// 


#import <Foundation/Foundation.h>

@class FCDataEntity;

@interface FCPersistentDataStorage : NSObject {
	NSString *_name;
	NSMutableDictionary *_memoryCache;
}

+(FCPersistentDataStorage*)dataStorage; // Uses default name
+(FCPersistentDataStorage*)dataStorageNamed:(NSString*)name;

-(NSArray*)allItems;
-(void)clearMemoryCache;
-(BOOL)containsObjectForKey:(NSString*)key;
-(id)initWithName:(NSString*)name;
-(id)objectForKey:(NSString*)key;
-(void)removeObjectForKey:(NSString*)aKey;
-(NSInteger)numberOfItems;
-(void)saveObject:(FCDataEntity*)object;
-(void)setObject:(FCDataEntity*)object forKey:(NSString*)aKey;
-(NSURL*)storageDirectoryURL;

@end

extern NSString *FCPersistentDataStorageObjectWasAddedNotification;
extern NSString *FCPersistentDataStorageObjectWasRemovedNotification;

