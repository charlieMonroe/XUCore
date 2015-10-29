// 
// NSMutableURLRequestAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-14 Charlie Monroe Software. All rights reserved.
// 


#import <Foundation/Foundation.h>


@interface NSMutableURLRequest (Additions)

-(void)addAccept:(nonnull NSString *)accept; // Adds a MIME type to the Accept HTTP header field
-(void)addContentType:(nonnull NSString *)contentType; // Adds a MIME type to the Content HTTP header field
-(void)addJSONAcceptToHeader; // Adds application/json to the Accept HTTP header field
-(void)addJSONContentToHeader; // Adds application/json to the Content HTTP header field
-(void)addMultipartFormDataContentToHeader; // Adds multipart/form-data to the Content HTTP header field
-(void)addWWWFormContentToHeader; // Adds application/x-www-form-urlencoded to the Content HTTP header field
-(void)addXMLAcceptToHeader; // Adds application/json to the Accept HTTP header field
-(void)addXMLContentToHeader; // Adds application/xml to the Content HTTP header field

-(void)setFormBody:(nonnull NSDictionary *)formBody;
-(void)setJSONBody:(nonnull id)obj;
-(void)setUsername:(nonnull NSString *)name andPassword:(nonnull NSString *)password;  // Sets the Authorization HTTP header field with username and password

/** Sets the referer HTTP header field. */
@property (readwrite, nullable, nonatomic) NSString *referer;

/** Sets the user agent HTTP header field. */
@property (readwrite, nullable, nonatomic) NSString *userAgent;

@end

