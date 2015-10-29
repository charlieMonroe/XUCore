// 
// FCCURLConnection.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCCURLConnection.h"
#import "NSStringAdditions.h"

#import "FCLog.h"

NSString *FCCURLConnectionIgnoreInvalidCertificatesDefaultsKey = @"FCCURLConnectionIgnoreInvalidCertificates";

@implementation FCCURLConnection

@synthesize password = _password, POST = _POST, POSTData = _POSTData, URL = _URL, username = _username,
			includeHeaders = _includeHeaders, responseCodeOnly = _responseCodeOnly, allowsRedirects = _allowsRedirects,
			forcedURLString = _forcedURLString;

+(BOOL)connectionResponseWithin200Range:(NSData *)data{
	NSString *response = [NSString stringWithData:data];
	FCLog(@"%s - response %@", __FCFUNCTION__, response);
	
	NSInteger responseCode = [response integerValue];
	return responseCode >= 200 && responseCode < 300;
}
+(FCCURLConnection *)connectionWithForcedURLString:(NSString *)urlString{
	FCCURLConnection *connection = [[FCCURLConnection alloc] initWithForcedURLString:urlString];
	return connection;
}
+(FCCURLConnection *)connectionWithURL:(NSURL *)url{
	FCCURLConnection *connection = [[FCCURLConnection alloc] initWithURL:url];
	return connection;
}

-(void)addHeaderField:(NSString *)field{
	[_headerFields addObject:field];
}
-(void)addJSONAcceptToHeader{
	[self addHeaderField:@"Accept: application/json"];
}
-(void)addJSONContentToHeader{
	[self addHeaderField:@"Content-Type: application/json"];
}
-(void)addURLEncodedWebFormContentToHeader{
	[self addHeaderField:@"Content-Type: application/x-www-form-urlencoded"];
}
-(void)addXMLAcceptToHeader{
	[self addHeaderField:@"Accept: application/xml"];
}
-(void)addXMLContentToHeader{
	[self addHeaderField:@"Content-Type: application/xml"];
}
-(id)initWithForcedURLString:(NSString *)urlString{
	if ((self = [super init]) != nil){
		[self setForcedURLString:urlString];
		
		_headerFields = [[NSMutableArray alloc] init];
	}
	return self;
}
-(id)initWithURL:(NSURL*)url{
	if ((self = [super init]) != nil){
		[self setURL:url];
		
		_headerFields = [[NSMutableArray alloc] init];
	}
	return self;
}
-(NSData *)sendSynchronousRequest{
	NSMutableArray *args = [NSMutableArray array];
	
	if ([self responseCodeOnly]){
		[args addObject:@"-sL"];
		[args addObject:@"-w"];
		[args addObject:@"%{http_code}"];
	}else if ([self includeHeaders]){
		[args addObject:@"-i"];
	}
	
	if ([self POSTData] != nil || [self isPOST]){
		[args addObject:@"-d"];
		[args addObject:[self POSTData] == nil ? @"" : [self POSTData]];
		if (![self isPOST] && [self HTTPMethod] == nil){
			[args addObject:@"-G"];
		}
	}
	
	if ([self allowsRedirects]){
		[args addObject:@"-L"];
	}
		
	for (NSString *headerField in _headerFields){
		[args addObject:@"-H"];
		[args addObject:headerField];
	}
	
	if ([self username] != nil && [self password] != nil){
		[args addObject:@"-u"];
		[args addObject:[NSString stringWithFormat:@"%@:%@", [self username], [self password]]];
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:FCCURLConnectionIgnoreInvalidCertificatesDefaultsKey] || [self ignoresInvalidCertificates]) {
		[args addObject:@"-k"];
	}
	
	if ([self HTTPMethod] != nil){
		[args addObject:@"-X"];
		[args addObject:[self HTTPMethod]];
	}
	
	[args addObject:[self forcedURLString] == nil ? [[self URL] absoluteString] : [self forcedURLString]];

	if ([self responseCodeOnly]){
		[args addObject:@"-o"];
		[args addObject:@"/dev/null"];
	}
	
	if (FCShouldLog()){
		NSMutableArray *argsCopy = [args mutableCopy];
		NSInteger userIndex = [argsCopy indexOfObject:@"-u"];
		if (userIndex != NSNotFound){
			userIndex++;
			
			NSString *authFieldString = [argsCopy objectAtIndex:userIndex];
			if ([authFieldString rangeOfString:@"\n"].location != NSNotFound){
				FCLog(@"%s - WARNING: new line in username or password", __FCFUNCTION__);
			}
			
			NSArray *components = [authFieldString componentsSeparatedByString:@":"];
			if ([[components objectAtIndex:1] isEqualToString:@"X"]){
				// API key
				authFieldString = @"***API_KEY***:X";
			}else{
				authFieldString = [NSString stringWithFormat:@"%@:***PASSWORD***", [[authFieldString componentsSeparatedByString:@":"] objectAtIndex:0]];
			}
			
			[argsCopy replaceObjectAtIndex:userIndex withObject:authFieldString];
		}
		
		FCLog(@"%s - %@", __FCFUNCTION__, argsCopy);
	}
	
	NSPipe *pipe = [NSPipe pipe];
	NSTask *t = [[NSTask alloc] init];
	[t setLaunchPath:@"/usr/bin/curl"];
	[t setArguments:args];
	[t setStandardOutput:pipe];
	[t setStandardError:[NSPipe pipe]];
	
	[t launch];
	
	NSMutableData *content = [[NSMutableData alloc] init];
	NSFileHandle *handle = [pipe fileHandleForReading];
	NSData *data = nil;
	while ((data = [handle availableData]) != nil && [data length] > 0) {
		[content appendData:data];
	}
	
	[t waitUntilExit];

	return content;
}
-(id)sendSynchronousRequestAndReturnJSONObject{
	NSData *data = [self sendSynchronousRequest];
	if (data == nil){
		FCLog(@"%s - NULL data", __FCFUNCTION__);
		return nil;
	}
	
	id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
	if (obj == nil){
		FCLog(@"%s - failed to deserialize JSON data (%@)", __FCFUNCTION__, [NSString stringWithData:data]);
	}

	return obj;
}
-(void)setPOSTData:(NSString *)data withPOSTRequest:(BOOL)post{
	[self setPOSTData:data];
	[self setPOST:post];
}
-(void)setUsername:(NSString *)name andPassword:(NSString *)pass{
	[self setUsername:name];
	[self setPassword:pass];
}
-(void)setValue:(id)value forHTTPHeaderField:(NSString *)field{
	[_headerFields addObject:[NSString stringWithFormat:@"%@: %@", field, value]];
}
@end

