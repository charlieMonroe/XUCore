//
//  XURegex.m
//  DownieCore
//
//  Created by Charlie Monroe on 2/14/14.
//  Copyright (c) 2014 Charlie Monroe Software. All rights reserved.
//

#import "XURegex.h"
#import "NSArrayAdditions.h"

#import "re2/re2.h"

static NSLock *_evaluationLock;

@implementation XURegex {
	re2::RE2 *_regex;
}

+(void)initialize{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_evaluationLock = [[NSLock alloc] init];
		[_evaluationLock setName:@"com.charliemonroe.Downie.XURegex"];
	});
}
+(instancetype)regexWithPattern:(NSString *)pattern andOptions:(XURegexOptions)options{
	return [[self alloc] initWithPattern:pattern andOptions:options];
}

-(NSArray *)allOccurrencesInString:(NSString *)string{
	[_evaluationLock lock];
	
	NSMutableArray *result = [NSMutableArray array];
	
	/* For some reasons, the RE2 has issues with multiline, if CRLF is used... */
	if (([self options] & XURegexOptionMultiline) != 0 && [string rangeOfString:@"\r\n"].location != NSNotFound){
		/* Removing \n works. */
		string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	}
	
	re2::StringPiece input([string UTF8String]);
	re2::RE2 tempRegex("(" + _regex->pattern() + ")");
	std::string match;
	while (re2::RE2::FindAndConsume(&input, tempRegex, &match)) {
		[result addObject:[NSString stringWithUTF8String:match.c_str()]];
	}
	
	[_evaluationLock unlock];
	
	return result;
}
-(NSArray *)allOccurrencesOfVariableNamed:(NSString *)varName inString:(NSString *)string{
	return [[self allOccurrencesInString:string] map:^id(NSString *match) {
		return [self getVariableNamed:varName inString:match];
	}];
}
-(NSDictionary *)allVariablePairsInString:(NSString *)string{
	NSArray *matches = [self allOccurrencesInString:string];
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:[matches count]];
	for (NSString *match in matches){
		NSString *key = [self getVariableNamed:@"VARNAME" inString:match];
		NSString *value = [self getVariableNamed:@"VARVALUE" inString:match];
		
		if (key == nil || value == nil){
			continue;
		}
		
		[dict setObject:value forKey:key];
	}
	
	return dict;
}
-(void)dealloc{
	if (_regex != NULL){
		delete _regex;
	}
}
-(NSString *)description{
	return [NSString stringWithFormat:@"%@ - %@", [super description], _pattern];
}
-(NSString *)firstMatchInString:(NSString *)string{
	[_evaluationLock lock];
	
	re2::StringPiece piece;
	std::string input([string UTF8String]);
	if (!_regex->Match(input, 0, (int)input.length(), RE2::UNANCHORED, &piece, 1)){
		[_evaluationLock unlock];
		return nil;
	}
	
	NSString *result = [NSString stringWithUTF8String:piece.as_string().c_str()];
	[_evaluationLock unlock];
	return result;
}
-(NSString *)getVariableNamed:(NSString *)varName inString:(NSString *)string{
	[_evaluationLock lock];
	
	if (_regex->NamedCapturingGroups().find([varName UTF8String]) == _regex->NamedCapturingGroups().end()){
		[_evaluationLock unlock];
		return nil; /* There isn't such a variable. */
	}
	
	int matchIndex = _regex->NamedCapturingGroups().at([varName UTF8String]);
	
	/* To avoid heap allocation, we assume there won't be more than 256 captures within a single regex. */
	
	if (_regex->NumberOfCapturingGroups() >= 256){
		[_evaluationLock unlock];
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"This regex has more than 256 captures." userInfo:nil];
	}
	
	re2::StringPiece matches[256];
	std::string input([string UTF8String]);
	bool matched = _regex->Match(input, 0, (int)input.length(), RE2::UNANCHORED, matches, _regex->NumberOfCapturingGroups() + 1);
	if (!matched){
		[_evaluationLock unlock];
		return nil;
	}
	
	NSString *result = [NSString stringWithUTF8String:matches[matchIndex].as_string().c_str()];
	[_evaluationLock unlock];
	
	return result;
}
-(id)init{
	@throw [NSException exceptionWithName:NSGenericException reason:@"-init is not available for XURegex" userInfo:nil];
}
-(id)initWithPattern:(NSString *)pattern andOptions:(XURegexOptions)options{
	if ((self = [super init]) != nil){
		_pattern = pattern;
		_options = options;
		
		NSString *modifiers = @"";
		NSString *modifiedPattern = pattern;
		if (options & XURegexOptionCaseless){
			modifiers = [modifiers stringByAppendingString:@"i"]; //[@"(?i)" stringByAppendingString:modifiedPattern];
		}
		if (options & XURegexOptionMultiline){
			modifiers = [modifiers stringByAppendingString:@"m"]; //modifiedPattern = [@"(?m)" stringByAppendingString:modifiedPattern];
		}
		if (options & XURegexOptionNotGreedy){
			modifiers = [modifiers stringByAppendingString:@"U"]; //modifiedPattern = [@"(?U)" stringByAppendingString:modifiedPattern];
		}
		
		if ([modifiers length] > 0){
			modifiedPattern = [NSString stringWithFormat:@"(?%@)%@", modifiers, pattern];
		}
		
		[_evaluationLock lock];
		_regex = new re2::RE2([modifiedPattern UTF8String]);
		[_evaluationLock unlock];
		
		if (!_regex->ok()){
			@throw [NSException exceptionWithName:NSGenericException reason:@"Regex compilation failed!" userInfo:nil];
		}
	}
	return self;
}
-(BOOL)matchesString:(NSString *)string{
	[_evaluationLock lock];
	std::string input([string UTF8String]);
	BOOL result = _regex->Match(input, 0, (int)input.length(), RE2::UNANCHORED, NULL, 0);
	[_evaluationLock unlock];
	
	return result;
}

@end
