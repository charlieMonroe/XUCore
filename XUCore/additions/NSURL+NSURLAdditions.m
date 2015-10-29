// 
// NSURL+NSURLAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSURL+NSURLAdditions.h"
#import "NSStringAdditions.h"

@implementation NSURL (NSURLAdditions)

+(id)fileReferenceURLWithPath:(NSString *)path{
	if (path == nil){
		return nil;
	}
	NSURL *fileURL = [self fileURLWithPath:path];
	NSURL *referenceURL = [fileURL fileReferenceURL];
	return (referenceURL == nil ? fileURL : referenceURL);
}

-(NSInteger)fileSize{
	if (![self isFileURL]){
		return 0;
	}
	return [[[[NSFileManager defaultManager] attributesOfItemAtPath:[self path] error:NULL] objectForKey:NSFileSize] integerValue];
}
-(NSString *)fileSizeString{
	if (![self isFileURL]){
		return [NSString stringWithFormat:@"Not Applicable (%@)", self];
	}
	
	return [NSByteCountFormatter stringFromByteCount:[self fileSize] countStyle:NSByteCountFormatterCountStyleFile];
}

@end

