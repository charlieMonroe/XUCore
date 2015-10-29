//
//  XURegex.h
//  DownieCore
//
//  Created by Charlie Monroe on 2/14/14.
//  Copyright (c) 2014 Charlie Monroe Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, XURegexOptions) {
	XURegexOptionNone = 0,
	XURegexOptionCaseless = 1 << 0,
	XURegexOptionMultiline = 1 << 1,
	XURegexOptionNotGreedy = 1 << 2
};

@interface XURegex : NSObject

+(nonnull instancetype)regexWithPattern:(nonnull NSString *)pattern andOptions:(XURegexOptions)options;

-(nonnull NSArray<NSString *> *)allOccurencesInString:(nonnull NSString *)string;
-(nonnull NSArray<NSString *> *)allOccurencesOfVariableNamed:(nonnull NSString *)varName inString:(nonnull NSString *)string;
-(nonnull NSDictionary<NSString *, NSString *> *)allVariablePairsInString:(nonnull NSString *)string;
-(nullable NSString *)firstMatchInString:(nonnull NSString *)string;
-(nullable NSString *)getVariableNamed:(nonnull NSString *)varName inString:(nonnull NSString *)string;

-(nonnull instancetype)init UNAVAILABLE_ATTRIBUTE;
-(nonnull instancetype)initWithPattern:(nonnull NSString *)pattern andOptions:(XURegexOptions)options;

-(BOOL)matchesString:(nonnull NSString *)string;

@property (readonly, nonnull, nonatomic) NSString *pattern;
@property (readonly, nonatomic) XURegexOptions options;

@end
