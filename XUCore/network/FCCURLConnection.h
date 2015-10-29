// 
// FCCURLConnection.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>

@interface FCCURLConnection : NSObject {
	NSMutableArray *_headerFields;
}

+(BOOL)connectionResponseWithin200Range:(NSData*)data;
+(FCCURLConnection*)connectionWithForcedURLString:(NSString*)urlString;
+(FCCURLConnection*)connectionWithURL:(NSURL*)url;

-(void)addHeaderField:(NSString*)field;
-(void)addJSONAcceptToHeader;
-(void)addJSONContentToHeader;
-(void)addURLEncodedWebFormContentToHeader;
-(void)addXMLAcceptToHeader;
-(void)addXMLContentToHeader;

-(id)initWithForcedURLString:(NSString*)urlString;
-(id)initWithURL:(NSURL*)url;
-(NSData*)sendSynchronousRequest;
-(id)sendSynchronousRequestAndReturnJSONObject;
-(void)setPOSTData:(NSString*)data withPOSTRequest:(BOOL)post;
-(void)setUsername:(NSString*)name andPassword:(NSString*)pass;
-(void)setValue:(id)value forHTTPHeaderField:(NSString*)field;

@property (readwrite, strong) NSURL *URL;
@property (readwrite, strong) NSString *POSTData, *username, *password, *forcedURLString, *HTTPMethod; // forcedURLString is when [NSURL URLWithString:] messes up the address
@property (readwrite, assign, getter = isPOST) BOOL POST;
@property (readwrite, assign) BOOL allowsRedirects, includeHeaders, responseCodeOnly, ignoresInvalidCertificates;

@end

