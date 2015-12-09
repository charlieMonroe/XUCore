// 
// FCCSVDocument.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>


@interface FCCSVDocument : NSObject

-(void)addContentItem:(nonnull NSDictionary *)item;

-(nullable instancetype)initWithContentsOfURL:(nonnull NSURL *)fileURL;
-(nonnull instancetype)initWithDictionaries:(nonnull NSArray<NSDictionary *> *)dictionaries;
-(nullable instancetype)initWithString:(nonnull NSString *)body;
-(nullable instancetype)initWithString:(nonnull NSString *)body andColumnSeparator:(unichar)columnSeparator;

-(BOOL)writeToURL:(nonnull NSURL *)url;


@property (readwrite, nonnull, nonatomic) NSArray<NSDictionary<NSString *, NSString *> *> *content;

/** Char that separates columns. ',' by default, but some files use ';' instead. */
@property (readonly, nonatomic) unichar columnSeparator;

@property (readwrite, nonnull, nonatomic) NSMutableArray<NSString *> *headerNames;

@property (readonly, nonnull, nonatomic) NSString *stringRepresentation;

@end

@interface FCCSVDocument (Deprecated)
-(nullable id)initWithFile:(nonnull NSString *)path DEPRECATED_MSG_ATTRIBUTE("Use -initWithContentsOfURL: instead");
-(BOOL)writeToFile:(nonnull NSString *)path DEPRECATED_MSG_ATTRIBUTE("Use -writeToURL: instead");
@end

