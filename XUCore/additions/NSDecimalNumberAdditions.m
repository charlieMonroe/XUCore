//
//  NSDecimalNumber+Additions.m
//  UctoX
//
//  Created by Charlie Monroe on 8/1/13.
//
//

#import "NSDecimalNumberAdditions.h"

@implementation NSDecimalNumber (Additions)

+(void)initialize{
	[self setDefaultBehavior:[NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundBankers scale:8 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO]];
}

+(NSDecimalNumber*)decimalNumberWithDouble:(double)value{
	return [self decimalNumberWithNumber:@(value)];
}
+(NSDecimalNumber*)decimalNumberWithNumber:(NSNumber*)number{
	if (number == nil) {
		return [NSDecimalNumber zero];
	}
	if ([number isKindOfClass:[self class]]){
		return (NSDecimalNumber*)number;
	}
	if ([number isKindOfClass:[NSString class]]){
		return [self decimalNumberWithString:(NSString*)number];
	}
	return [NSDecimalNumber decimalNumberWithDecimal:[number decimalValue]];
}

-(NSDecimalNumber*)ceiledDecimalNumber{
	if ([[self decimalPart] doubleValue] < 0.01){
		/* Consider self already ceiled. */
		return self;
	}
	return [NSDecimalNumber decimalNumberWithDouble:ceil([self doubleValue])];
}
-(NSDecimalNumber *)decimalPart{
	return [self subtractDecimal:[self integralDecimalNumber]];
}
-(NSDecimalNumber*)integralDecimalNumber{
	return [NSDecimalNumber decimalNumberWithDouble:(double)((NSUInteger)[self doubleValue])];
}
-(NSDecimalNumber*)roundedDecimalNumber{
	if ([[self decimalPart] doubleValue] < 0.01){
		/* Consider self already rounded. */
		return self;
	}
	return [NSDecimalNumber decimalNumberWithDouble:round([self doubleValue])];
}

-(NSDecimalNumber*)add:(double)value{
	return [self decimalNumberByAdding:[NSDecimalNumber decimalNumberWithNumber:@(value)]];
}
-(NSDecimalNumber*)divide:(double)value{
	return [self decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithNumber:@(value)]];
}
-(NSDecimalNumber*)multiply:(double)value{
	return [self decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithNumber:@(value)]];
}
-(NSDecimalNumber*)subtract:(double)value{
	return [self decimalNumberBySubtracting:[NSDecimalNumber decimalNumberWithNumber:@(value)]];
}

-(nonnull instancetype)absoluteValueDecimalNumber{
	if ([self doubleValue] < 0.0){
		return [self multiply:-1.0];
	}
	return self;
}

-(NSDecimalNumber*)addDecimal:(NSDecimalNumber*)value{
	if (value == nil){
		return self;
	}
	return [self decimalNumberByAdding:value];
}
-(NSDecimalNumber*)divideDecimal:(NSDecimalNumber*)value{
	if (value == nil){
		return [NSDecimalNumber notANumber];
	}
	return [self decimalNumberByDividingBy:value];
}
-(NSDecimalNumber*)multiplyDecimal:(NSDecimalNumber*)value{
	if (value == nil){
		return [NSDecimalNumber zero];
	}
	return [self decimalNumberByMultiplyingBy:value];
}
-(NSDecimalNumber*)subtractDecimal:(NSDecimalNumber*)value{
	if (value == nil){
		return self;
	}
	return [self decimalNumberBySubtracting:value];
}

-(BOOL)isInteger{
	return [[self decimalPart] doubleValue] == 0.0;
}

@end
