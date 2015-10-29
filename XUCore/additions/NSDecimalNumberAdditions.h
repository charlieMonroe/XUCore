//
//  NSDecimalNumber+Additions.h
//  UctoX
//
//  Created by Charlie Monroe on 8/1/13.
//
//

#import <Foundation/Foundation.h>

@interface NSDecimalNumber (Additions)

+(nonnull instancetype)decimalNumberWithDouble:(double)value;

/** If number == nil, return [NSDecimalNumber zero]. */
+(nonnull instancetype)decimalNumberWithNumber:(nullable NSNumber *)number;


/** If the number is negative, returns self * -1.0, otherwise returns self. */
-(nonnull instancetype)absoluteValueDecimalNumber;

-(nonnull instancetype)ceiledDecimalNumber;
-(nonnull instancetype)decimalPart; /* 4.63 ---> 0.63 */
-(nonnull instancetype)integralDecimalNumber;
-(nonnull instancetype)roundedDecimalNumber;

-(nonnull instancetype)add:(double)value;
-(nonnull instancetype)addDecimal:(nullable NSNumber *)value;
-(nonnull instancetype)divide:(double)value;
-(nonnull instancetype)divideDecimal:(nullable NSNumber *)value;
-(nonnull instancetype)multiply:(double)value;
-(nonnull instancetype)multiplyDecimal:(nullable NSNumber *)value;
-(nonnull instancetype)subtract:(double)value;
-(nonnull instancetype)subtractDecimal:(nullable NSNumber *)value;

/** If decimalPart is 0, returns YES. */
@property (readonly, nonatomic) BOOL isInteger;

@end
