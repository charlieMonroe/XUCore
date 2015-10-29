// 
// NSMutableDictionaryAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSMutableDictionaryAdditions.h"

@implementation NSMutableDictionary (NSMutableDictionaryAdditions)

-(void)setBool:(BOOL)aBool forKey:(id)key{
	[self setObject:@(aBool) forKey:key];
}
-(void)setFloat:(float)aFloat forKey:(id)key{
	[self setObject:@(aFloat) forKey:key];
}
-(void)setInt:(int)anInt forKey:(id)key{
	[self setObject:@(anInt) forKey:key];
}
-(void)setUnsignedInt:(unsigned int)anInt forKey:(id)key{
	[self setObject:@(anInt) forKey:key];
}
-(void)setUnsignedShort:(unsigned short)aShort forKey:(id)key{
	[self setObject:@(aShort) forKey:key];
}
-(BOOL)setObjectConditionally:(id)object forKey:(id)key{
	if (object != nil){
		[self setObject:object forKey:key];
		return YES;
	}
	return NO;
}

@end

