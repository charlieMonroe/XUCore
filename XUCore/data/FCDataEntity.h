// 
// FCDataEntity.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-16 Charlie Monroe Software. All rights reserved.
// 


#import <Foundation/Foundation.h>
#import "FCPersistentDataStorage.h"

@interface FCDataEntity : NSObject <NSCoding>

-(void)entityWillBeRemovedFromDataStorage; // i.e. delete everything around you
-(void)entityWillGoIdle; // Entity will not be used for some time now - release all cached stuff
-(void)save;

@property (readwrite, assign) FCPersistentDataStorage *dataStorage;
@property (readwrite, retain) NSString *objectKey;
@property (readwrite, assign) unsigned long long lastAccessDate;

@end

