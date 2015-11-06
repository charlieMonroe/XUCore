// 
// NSArrayAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-14 Charlie Monroe Software. All rights reserved.
// 


#import "NSArrayAdditions.h"
#import "FCLog.h"

#import <XUCore/XUCore-Swift.h>

@implementation NSArray (NSArrayAdditions)

+(instancetype)arrayWithInterlacedArrays:(NSArray *)arrays{
	if ([arrays count] == 0){
		return @[ ];
	}
	if ([arrays count] == 1){
		return [arrays firstObject];
	}
	
	NSUInteger maxIndex = [[arrays findMax:^NSUInteger(NSArray *array) {
		return [array count];
	}] count];
	
	NSMutableArray *result = [NSMutableArray array];
	for (NSUInteger i = 0; i < maxIndex; ++i){
		for (NSArray *arr in arrays){
			if (i < [arr count]){
				[result addObject:[arr objectAtIndex:i]];
			}
		}
	}
	
	return result;
}

-(BOOL)all:(BOOL (^)(id obj))validator{
	BOOL result = YES; // Empty arrays should return true or not?
	for (id item in self){
		result = (result && validator(item));
	}
	return result;
}
-(BOOL)any:(BOOL (^)(id obj))validator{
	for (id item in self){
		if (validator(item)){
			return YES;
		}
	}
	return NO;
}
-(instancetype)arrayByInterlacingWithArrays:(NSArray *)arrays{
	return [[self class] arrayWithInterlacedArrays:[@[ self ] arrayByAddingObjectsFromArray:arrays]];
}
-(id)arrayWithAllocatedObjectsOfClass:(Class)objectClass{
	NSMutableArray *result = [NSMutableArray array];
	for (NSDictionary *aDict in self){
		[result addObject:[[objectClass alloc] initWithDictionary:aDict]];
	}
	return result;
}
-(id)arrayByRemovingObjectsMatching:(BOOL (^)(id))filter{
	NSMutableArray *result = [self mutableCopy];
	for (id obj in self){
		if (filter(obj)){
			[result removeObject:obj];
		}
	}
	return result;
}
-(BOOL)contains:(BOOL (^)(id))filter{
	return [self any:filter];
}
-(BOOL)containsString:(NSString*)string{
	return [self searchForString:string] != nil;
}
-(NSUInteger)count:(BOOL (^)(id obj))filter{
	NSUInteger counter = 0;
	for (id obj in self){
		if (filter(obj)){
			++counter;
		}
	}
	return counter;
}
-(NSArray*)dictionaryRepresentation{
	return [self resultsOfSelectorPerformed:@selector(dictionaryRepresentation)];
}
-(instancetype)distinctUsingSelector:(SEL)aSelector{
	if (aSelector == nil){
		FCLogStacktrace([NSString stringWithFormat:@"******* NULL SEL in %@ ********", NSStringFromSelector(_cmd)]);
	}
	
	return [self distinctUsingBlock:^BOOL(id resultObj, id obj) {
		#pragma clang diagnostic push
		#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			return (BOOL)[resultObj performSelector:aSelector withObject:obj];
		#pragma clang diagnostic pop
	}];
}
-(NSArray *)distinctUsingBlock:(BOOL (^)(id,id))filter{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
	for (id obj in self){
		BOOL found = NO;
		for (id resultObj in result) {
			if (filter(resultObj, obj)){
				found = YES;
			}
		}
		if (!found){
			[result addObject:obj];
		}
	}
	return result;
}
-(id)filter:(BOOL (^)(id))filter{
	NSMutableArray *result = [NSMutableArray array];
	for (id obj in self){
		if (filter(obj)){
			[result addObject:obj];
		}
	}
	return result;
}
-(id)find:(BOOL (^)(id obj))filter{
	for (id obj in self){
		if (filter(obj)){
			return obj;
		}
	}
	return nil;
}
-(id)findMax:(NSUInteger (^)(id))filter{
	NSUInteger maxValue = 0;
	id maxObj = nil;
	for (id obj in self){
		NSUInteger objValue = filter(obj);
		if (objValue > maxValue || (objValue == maxValue && maxObj == nil)){
			maxValue = objValue;
			maxObj = obj;
		}
	}
	return maxObj;
}
-(NSUInteger)findMaxValue:(NSUInteger (^)(id))transformer{
	if ([self count] == 0){
		return NSNotFound;
	}
	
	NSUInteger maxValue = 0;
	for (id obj in self){
		NSUInteger objValue = transformer(obj);
		if (objValue > maxValue){
			maxValue = objValue;
		}
	}
	return maxValue;
}
-(id)findMin:(NSUInteger (^)(id))filter{
	NSInteger minValue = NSIntegerMax;
	id minObj = nil;
	for (id obj in self){
		NSUInteger objValue = filter(obj);
		if (objValue < minValue || (objValue == minValue && minObj == nil)){
			minValue = objValue;
			minObj = obj;
		}
	}
	return minObj;
}
-(NSUInteger)findMinValue:(NSUInteger (^)(id))transformer{
	if ([self count] == 0){
		return NSNotFound;
	}
	
	NSInteger minValue = NSIntegerMax;
	for (id obj in self){
		NSUInteger objValue = transformer(obj);
		if (objValue < minValue){
			minValue = objValue;
		}
	}
	return minValue;
}
-(id)findMapped:(id (^)(id))mapper{
	id result = nil;
	for (id obj in self){
		result = mapper(obj);
		if (result != nil){
			break;
		}
	}
	return result;
}
-(id)findTransformed:(id (^)(id))mapper{
	return [self findMapped:mapper];
}
-(instancetype)flattenedArray{
	NSMutableArray *result = [NSMutableArray array];
	for (NSArray *arr in self){
		[result addObjectsFromArray:arr];
	}
	return result;
}
-(BOOL)isIndexInRange:(NSInteger)index{
	return (index >= 0) && (index < [self count]);
}
-(id)map:(id (^)(id))mapper{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
	for (id obj in self) {
		id mappedResult = mapper(obj);
		if (mappedResult != nil){
			[result addObject:mappedResult];
		}
	}
	return result;
}
-(id)mapIndexed:(id (^)(id, NSUInteger))mapper{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
	for (NSUInteger i = 0; i < [self count]; ++i) {
		id mappedResult = mapper([self objectAtIndex:i], i);
		if (mappedResult != nil){
			[result addObject:mappedResult];
		}
	}
	return result;
}
-(NSInteger)numberOfItemsWithCondition:(BOOL (^)(id obj))filter{
	return [self count:filter];
}
-(NSInteger)numberOfOccurrences:(id)obj{
	return [self count:^BOOL(id o) {
		return [o isEqual:obj];
	}];
}
-(NSArray *)randomizedArray{
	NSMutableArray *result = [self mutableCopy];
	for (int i = 0; i < 4 * [self count]; ++i){
		unsigned char randByte = [[XURandomGenerator sharedGenerator] randomByte] % [self count];
		unsigned char randByte2 = [[XURandomGenerator sharedGenerator] randomByte]  % [self count];
		if (randByte != randByte2){
			[result exchangeObjectAtIndex:randByte withObjectAtIndex:randByte2];
		}
	}
	return result;
}
-(instancetype)resultsOfSelectorPerformed:(SEL)action{
	if (action == nil){
		FCLogStacktrace([NSString stringWithFormat:@"******* NULL SEL in %@ ********", NSStringFromSelector(_cmd)]);
		return nil;
	}
	
	return [self map:^id(id obj) {
		#pragma clang diagnostic push
		#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			return [obj performSelector:action];
		#pragma clang diagnostic pop
	}];
}
-(instancetype)reversedArray{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self count]];
	
	for (int i = (int)[self count] - 1; i >= 0; --i){
		[array addObject:[self objectAtIndex:i]];
	}
	
	return array;
}
-(NSString *)searchForString:(NSString *)string{
	for (id obj in self){
		if ([obj isKindOfClass:[NSString class]]){
			return [obj rangeOfString:string options:NSCaseInsensitiveSearch].location != NSNotFound ? obj : nil;
		}
		if ([obj isKindOfClass:[NSNumber class]]){
			return [[obj stringValue] rangeOfString:string options:NSCaseInsensitiveSearch].location != NSNotFound ? [obj stringValue] : nil;
		}
		if ([obj isKindOfClass:[NSDate class]]){
			return [[obj description] rangeOfString:string options:NSCaseInsensitiveSearch].location != NSNotFound ? [obj description] : nil;
		}
		if ([obj respondsToSelector:@selector(containsString:)]){
			NSString *result = [obj searchForString:string];
			if (result != nil){
				return result;
			}
		}
	}
	return nil;
}
-(NSInteger)sum:(NSInteger(^)(id obj))numerator{
	NSInteger result = 0;
	for (id obj in self){
		result += numerator(obj);
	}
	return result;
}
-(NSDecimalNumber*)sumDecimal:(NSDecimalNumber*(^)(id obj))numerator{
	NSDecimalNumber *result = [NSDecimalNumber zero];
	for (id obj in self){
		NSDecimalNumber *number = numerator(obj);
		if (number == nil){
			continue; // Treat it as zero
		}
		result = [result decimalNumberByAdding:number];
	}
	return result;
}
-(CGFloat)sumFloat:(CGFloat(^)(id obj))numerator{
	CGFloat result = 0.0;
	for (id obj in self){
		result += numerator(obj);
	}
	return result;
}
-(NSUInteger)sumUnsigned:(NSUInteger(^)(id obj))numerator{
	NSUInteger result = 0;
	for (id obj in self){
		result += numerator(obj);
	}
	return result;
}
@end

@implementation NSMutableArray (NSMutableArrayAdditions)

-(void)moveObject:(id)object toIndex:(NSUInteger)index{
	[self moveObjectAtIndex:[self indexOfObject:object] toIndex:index];
}
-(void)moveObjectAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex{
	if (toIndex == fromIndex){
		return;
	}
	
	if (toIndex >= fromIndex){
		--toIndex;
	}
	
	id obj = [self objectAtIndex:fromIndex];
	[self removeObjectAtIndex:fromIndex];
	if (toIndex >= [self count]) {
		[self addObject:obj];
	}else{
		[self insertObject:obj atIndex:toIndex];
	}
}
-(void)removeObjectsMatching:(BOOL (^)(id))filter{
	for (NSInteger i = [self count] - 1; i >= 0; --i){
		if (filter([self objectAtIndex:i])){
			[self removeObjectAtIndex:i];
		}
	}
}
-(void)removeObjectsPassingTest:(BOOL (^)(id))filter{
	[self removeObjectsMatching:filter];
}

@end

