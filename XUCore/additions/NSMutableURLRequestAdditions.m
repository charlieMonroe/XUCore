// 
// NSMutableURLRequestAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-14 Charlie Monroe Software. All rights reserved.
// 


#import "NSMutableURLRequestAdditions.h"

#import "NSArrayAdditions.h"
#import "NSDataAdditions.h"
#import "NSStringAdditions.h"

@implementation NSMutableURLRequest (Additions)

-(void)addAccept:(NSString*)accept{
	[self addValue:accept forHTTPHeaderField:@"Accept"];
}
-(void)addContentType:(NSString*)contentType{
	[self addValue:contentType forHTTPHeaderField:@"Content-Type"];
}
-(void)addJSONAcceptToHeader{
	[self addAccept:@"application/json"];
}
-(void)addJSONContentToHeader{
	[self addContentType:@"application/json"];
}
-(void)addMultipartFormDataContentToHeader{
	[self addContentType:@"multipart/form-data"];
}
-(void)addWWWFormContentToHeader{
	[self addContentType:@"application/x-www-form-urlencoded"];
}
-(void)addXMLAcceptToHeader{
	[self addAccept:@"application/xml"];
}
-(void)addXMLContentToHeader{
	[self addContentType:@"application/xml"];
}
-(NSString *)referer{
	return [self valueForHTTPHeaderField:@"Referer"];
}
-(void)setFormBody:(NSDictionary *)formBody{
	NSString *bodyString = [[[formBody allKeys] map:^id(NSString *key) {
		return [NSString stringWithFormat:@"%@=%@", key, [[formBody objectForKey:key] stringByEncodingIllegalURLCharacters]];
	}] componentsJoinedByString:@"&"];
	[self setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
}
-(void)setJSONBody:(id)obj{
	[self setHTTPBody:[NSJSONSerialization dataWithJSONObject:obj options:0 error:NULL]];
}
-(void)setReferer:(NSString *)referer{
	[self setValue:referer forHTTPHeaderField:@"Referer"];
}
-(void)setUserAgent:(NSString *)useragent{
	[self setValue:useragent forHTTPHeaderField:@"User-Agent"];
}
-(void)setUsername:(NSString*)name andPassword:(NSString*)password{
	NSString *b64 = [[[NSString stringWithFormat:@"%@:%@", name, password] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
	[self addValue:[NSString stringWithFormat:@"Basic %@", b64] forHTTPHeaderField:@"Authorization"];
}
-(NSString *)userAgent{
	return [self valueForHTTPHeaderField:@"User-Agent"];
}

@end

