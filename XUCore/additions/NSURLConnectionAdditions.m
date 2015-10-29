// 
// NSURLConnectionAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSURLConnectionAdditions.h"

@interface FCURLConnectionLoader : NSObject {
@private
	NSURLConnection *_connection;
	NSURLResponse *_response;
	NSError *_error;
	NSMutableData *_data;
	BOOL _jobFinished;
}

-(NSData*)loadData;

@property (readwrite, strong) NSURLConnection *connection;
@property (readwrite, strong) NSURLResponse *response;
@property (readwrite, strong) NSError *error;
@property (readonly, strong) NSData *data;
@property (readwrite, strong) NSString *userAgent;

@end

@implementation FCURLConnectionLoader

@synthesize response = _response, error = _error, data = _data, connection = _connection;

-(void)_loadData{
	@autoreleasepool {
	
		NSRunLoop *loop = [NSRunLoop currentRunLoop];
		
		[[self connection] scheduleInRunLoop:loop forMode:NSDefaultRunLoopMode];
		[[self connection] start];
		
		while (!_jobFinished){
			[loop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
		}
	
	}
}
-(BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection{
	return YES;
}
-(BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace{
	return YES;
}
-(NSURLRequest *)connection:(NSURLConnection*)connection willSendRequest:(NSURLRequest*)request redirectResponse:(NSURLResponse*)redirectResponse{
	if ([self userAgent] == nil){
		return request;
	}
	
	NSMutableURLRequest *newReq = [request mutableCopy];
	[newReq setValue:[self userAgent] forHTTPHeaderField:@"User-Agent"];
	[newReq addValue:@"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" forHTTPHeaderField:@"Accept"];
	return newReq;
}
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
	[self setError:error];
	_jobFinished = YES;
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
	[_data appendData:data];
}
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	[self setResponse:response];
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
	_jobFinished = YES;
}
-(void)dealloc {
	[self setConnection:nil];
	[self setResponse:nil];
	[self setError:nil];
}
-(id)init{
	if ((self = [super init]) != nil){
		_data = [[NSMutableData alloc] init];
	}
	return self;
}
-(NSData *)loadData{
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[queue addOperationWithBlock:^(void){
		[[self connection] start];
	}];
	
	[queue waitUntilAllOperationsAreFinished];
	while (!_jobFinished) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
	}
	return [self data];
}

@end


@interface FCLengthGetter : NSObject <NSURLConnectionDownloadDelegate> {
	BOOL _jobFinished;
}

-(void)loadInformation;

@property (readwrite, assign) long long length;
@property (readwrite, strong) NSURLResponse *response;
@property (readwrite, strong) NSURLConnection *connection;
@end

@implementation FCLengthGetter

-(void)connectionDidFinishDownloading:(NSURLConnection *)connection destinationURL:(NSURL *)destinationURL{
	_jobFinished = YES;
}
-(void)connection:(NSURLConnection *)connection didWriteData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes{
	_jobFinished = YES;
	[connection cancel];
	[self setLength:expectedTotalBytes];
}
-(void)dealloc{
	[self setResponse:nil];
	[self setConnection:nil];
}
-(void)loadInformation{
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[queue addOperationWithBlock:^(void){
		[[self connection] start];
	}];
	
	[queue waitUntilAllOperationsAreFinished];
	while (!_jobFinished) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
	}
}
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	[self setResponse:response];
}

@end


@implementation NSURLConnection (NSURLConnectionAdditions)


+(long long)getLenghtOfRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response{
	FCLengthGetter *getter = [[FCLengthGetter alloc] init];
	NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:getter];
	[getter setConnection:connection];
	[getter loadInformation];
	if (response != NULL){
		*response = [getter response];
	}
	return [getter length];
}
+(NSData *)sendSynchronousRequest:(NSURLRequest *)request asUserAgent:(NSString *)userAgent{
	return [self sendSynchronousRequest:request asUserAgent:userAgent returningResponse:NULL error:NULL];
}
+(NSData *)sendSynchronousRequest:(NSURLRequest *)request asUserAgent:(NSString *)userAgent returningResponse:(NSURLResponse **)response error:(NSError **)error{
	FCURLConnectionLoader *loader = [[FCURLConnectionLoader alloc] init];
	NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:loader];
	[loader setUserAgent:userAgent];
	[loader setConnection:connection];
	NSData *data = [loader loadData];
	if (response != NULL){
		*response = [loader response];
	}
	if (error != NULL){
		*error = [loader error];
	}
	return data;
}
+(NSData *)sendAuthenticatedSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error{
	FCURLConnectionLoader *loader = [[FCURLConnectionLoader alloc] init];
	NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:loader];
	
	[loader setConnection:connection];
	NSData *data = [loader loadData];
	if (response != NULL){
		*response = [loader response];
	}
	if (error != NULL){
		*error = [loader error];
	}
	
	return data;
}
@end

