// 
// FCTemporaryDataStorage.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCPersistentDataStorage.h"

@interface FCTemporaryDataStorage : FCPersistentDataStorage {
	NSInteger _cachedSize;
}

@property (readwrite, assign) NSInteger maximumSize; // In bytes

@end

