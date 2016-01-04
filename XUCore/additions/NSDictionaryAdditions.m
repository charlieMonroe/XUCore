// 
// NSDictionaryAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-16 Charlie Monroe Software. All rights reserved.
// 


#import "NSDictionaryAdditions.h"

#import "NSArrayAdditions.h"

@implementation NSDictionary (NSDictionaryAdditions)

+(instancetype)dictionaryWithContentsOfData:(NSData *)data{
	// uses toll-free bridging for data into CFDataRef and CFPropertyList into NSDictionary
	CFPropertyListRef plist = CFPropertyListCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)data, kCFPropertyListImmutable, NULL, NULL);

	// we check if it is the correct type and only return it if it is
	if ([(__bridge id)plist isKindOfClass:[NSDictionary class]]){
		return (NSDictionary *)CFBridgingRelease(plist);
	}else if (plist != NULL) {
		// clean up ref
		CFRelease(plist);
		return nil;
	}
	return nil;
}
-(BOOL)containsString:(NSString*)string{
	if ([string length] == 0){
		return YES;
	}
	return [self searchForString:string] != nil;
}
-(instancetype)dictionaryRepresentation{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	for (id key in [self allKeys]){
		[dict setObject:[[self objectForKey:key] dictionaryRepresentation] forKey:key];
	}
	return dict;
}
-(id)firstNonNilObjectForKeys:(NSArray *)keys{
	for (id key in keys){
		id obj = [self objectForKey:key];
		if (obj != nil){
			return obj;
		}
	}
	return nil;
}
-(NSString *)searchForString:(NSString *)string{
	for (NSString *key in [self allKeys]){
		id obj = [self objectForKey:key];
		if ([obj isKindOfClass:[NSString class]] && [obj rangeOfString:string options:NSCaseInsensitiveSearch].location != NSNotFound){
			return obj;
		}
		if ([obj isKindOfClass:[NSNumber class]] && [[obj stringValue] rangeOfString:string options:NSCaseInsensitiveSearch].location != NSNotFound){
			return [obj stringValue];
		}
		if ([obj isKindOfClass:[NSDate class]] && [[obj description] rangeOfString:string options:NSCaseInsensitiveSearch].location != NSNotFound){
			return [obj description];
		}
		if ([obj respondsToSelector:@selector(searchForString:)]){
			NSString *result = [obj searchForString:string];
			if (result != nil){
				return result;
			}
		}
	}
	return nil;
}

-(nonnull NSString *)URLQueryString{
	NSArray *keyValuePairs = [[self allKeys] map:^id(NSString *key) {
		return [NSString stringWithFormat:@"%@=%@",
				[key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]],
				[[[self objectForKey:key] description] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]]];
	}];
	
	return [keyValuePairs componentsJoinedByString:@"&"];
}

@end

