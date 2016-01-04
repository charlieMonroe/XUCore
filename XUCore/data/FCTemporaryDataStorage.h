// 
// FCTemporaryDataStorage.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-16 Charlie Monroe Software. All rights reserved.
// 


#import "FCPersistentDataStorage.h"

@interface FCTemporaryDataStorage : FCPersistentDataStorage {
	NSInteger _cachedSize;
}

@property (readwrite, assign) long long maximumSize; // In bytes

@end

