// 
// NSArrayAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-14 Charlie Monroe Software. All rights reserved.
// 

/*
 * This file contains a category to NSArray which adds several
 * methods that make work with arrays much more simple.
 */

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
	/* Required for CGFloat. */
	#import <UIKit/UIKit.h>
#endif


@interface NSArray<__covariant ObjectType> (NSArrayAdditions)

+(nonnull instancetype)arrayWithInterlacedArrays:(nonnull NSArray<NSArray<ObjectType> *> *)arrays NS_SWIFT_UNAVAILABLE("Use Swift's Array.");

-(BOOL)all:(nonnull BOOL (^)(ObjectType __nonnull obj))validator NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Returns YES if all objects pass the validator.
-(BOOL)any:(nonnull BOOL (^)(ObjectType __nonnull obj))validator NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Returns YES if at least one object passes the validator.

/*
 * Assumes the array (self) contains instances of NSDictionary and allocates
 * instances of class objectClass and calls -initWithDictionary: on each newly
 * created instance.
 */
-(nonnull instancetype)arrayWithAllocatedObjectsOfClass:(nonnull Class)objectClass NS_SWIFT_UNAVAILABLE("Use Swift's Array.");

-(nonnull instancetype)arrayByRemovingObjectsMatching:(nonnull BOOL (^)(ObjectType __nonnull obj))filter NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Returns array with all objects matching filter removed
-(nonnull instancetype)arrayByInterlacingWithArrays:(nonnull NSArray *)arrays NS_SWIFT_UNAVAILABLE("Use Swift's Array.");

/// Returns YES if all objects in otherArray are contained by the receiver.
-(BOOL)containsAllObjectsFromArray:(nonnull NSArray *)otherArray NS_SWIFT_UNAVAILABLE("Use Swift's Array.");

-(BOOL)containsString:(nonnull NSString *)string NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Calls -searchForString: on self and returns YES if non-nil value is returned
-(NSUInteger)count:(nonnull BOOL (^)(ObjectType __nonnull obj))filter NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Returns number of items matching filter
-(nonnull instancetype)dictionaryRepresentation NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Returns an array of items returned by calling -dictionaryRepresentation on each item
-(nonnull instancetype)distinctUsingBlock:(nonnull BOOL(^)(ObjectType __nonnull resultObj, ObjectType __nonnull obj))comparator NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Returns distinct array - comparator must return YES is resultObj and obj are the same
-(nonnull instancetype)distinctUsingSelector:(nonnull SEL)aSelector NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Distinct array using a selector which must have a BOOL result
-(nonnull instancetype)filter:(nonnull BOOL (^)(ObjectType __nonnull obj))filter NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Filtered array
-(nullable id)find:(nonnull BOOL (^)(ObjectType __nonnull obj))filter NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Returns first object matching filter
-(nullable id)findMapped:(nonnull id __nullable (^)(ObjectType __nonnull obj))mapper NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // mapper returns either nil for non-matching obj, or non-nil object (first non-nil object is returned)
-(nullable id)findMin:(nonnull NSUInteger (^)(ObjectType __nonnull obj))transformer NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Finds minimum using the transformer
-(NSUInteger)findMinValue:(nonnull NSUInteger (^)(ObjectType __nonnull obj))transformer NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Finds minimum using the transformer and returns the min value returned. NSNotFound for empty arrays
-(nullable ObjectType)findMax:(nonnull NSUInteger (^)(ObjectType __nonnull obj))transformer NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Finds maximum using the transformer
-(NSUInteger)findMaxValue:(nonnull NSUInteger (^)(ObjectType __nonnull obj))transformer NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Finds maximum using the transformer and returns the min value returned. NSNotFound for empty arrays
-(nonnull instancetype)flattenedArray NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Assumes this array is an array of arrays and puts all arrays into one large array
-(nonnull instancetype)map:(nonnull id __nullable (^)(ObjectType __nonnull obj))mapper NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Maps the array using the mapper into another array. Return nil to skip the object
-(nonnull instancetype)mapIndexed:(nonnull id __nullable (^)(ObjectType __nonnull obj, NSUInteger index))mapper NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // The same as -map:, but passes index of the object as well
-(BOOL)isIndexInRange:(NSInteger)index NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Returns YES if index >= 0 && index < [self count]
-(NSInteger)numberOfOccurrences:(nonnull ObjectType)obj NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Calls -isEqual: on each object and returns number of positive comparisons
-(nonnull instancetype)randomizedArray NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Randomly shuffles the array.
-(nonnull instancetype)resultsOfSelectorPerformed:(nonnull SEL)action NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Pretty much like -map:, but the object mustn't return nil for the action
-(nonnull instancetype)reversedArray NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Reversed array
-(nullable NSString *)searchForString:(nonnull NSString *)string NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Supports NSString, NSDate and NSNumber
-(NSInteger)sum:(nonnull NSInteger(^)(ObjectType __nonnull obj))numerator NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Adds the integral value of objects
-(nonnull NSDecimalNumber *)sumDecimal:(nonnull NSDecimalNumber * __nonnull (^)(ObjectType __nonnull obj))numerator NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Adds the value of objects
-(CGFloat)sumFloat:(nonnull CGFloat(^)(ObjectType __nonnull obj))numerator NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Adds the float value of objects
-(NSUInteger)sumUnsigned:(nonnull NSUInteger(^)(ObjectType __nonnull obj))numerator NS_SWIFT_UNAVAILABLE("Use Swift's Array."); // Adds the unsigned integral value of objects

@end

@interface NSMutableArray (NSMutableArrayAdditions)

-(void)moveObject:(nonnull id)object toIndex:(NSUInteger)index NS_SWIFT_UNAVAILABLE("Use Swift's Array.");
-(void)moveObjectAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex NS_SWIFT_UNAVAILABLE("Use Swift's Array.");
-(void)removeObjectsMatching:(nonnull BOOL (^)(id __nonnull obj))filter NS_SWIFT_UNAVAILABLE("Use Swift's Array.");

@end

