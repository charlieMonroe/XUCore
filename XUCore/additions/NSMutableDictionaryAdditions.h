// 
// NSMutableDictionaryAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>

@interface NSMutableDictionary (NSMutableDictionaryAdditions)

-(void)setBool:(BOOL)aBool forKey:(nonnull id)key;
-(void)setFloat:(float)aFloat forKey:(nonnull id)key;
-(void)setInt:(int)anInt forKey:(nonnull id)key;
-(void)setUnsignedInt:(unsigned int)anInt forKey:(nonnull id)key;
-(void)setUnsignedShort:(unsigned short)aShort forKey:(nonnull id)key;
-(BOOL)setObjectConditionally:(nullable id)object forKey:(nonnull id)key;

@end

