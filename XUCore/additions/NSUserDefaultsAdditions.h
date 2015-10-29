// 
// NSUserDefaultsAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 

@import Foundation;

#if TARGET_OS_IPHONE
	#import <UIKit/UIKit.h>
#else
	#import <Cocoa/Cocoa.h>
#endif

#if !TARGET_OS_IPHONE
@interface NSUserDefaults (FCAdditions)
+(void)addApplicationToLoginItems __attribute__((deprecated));
+(void)addPathToLoginItems:(NSString*)filePath __attribute__((deprecated));
+(BOOL)applicationIsInLoginItems __attribute__((deprecated));
+(BOOL)applicationIsInLoginItems:(NSString*)filePath __attribute__((deprecated));
+(void)removeApplicationFromLoginItems __attribute__((deprecated));
+(void)removePathFromLoginItems:(NSString*)filePath __attribute__((deprecated));


-(void)setColor:(NSColor*)aColor forKey:(NSString *)aKey;
-(NSColor*)colorForKey:(NSString*)aKey;

@end

//Login items
BOOL FCApplicationIsInLoginItems();
void FCAddApplicationToLoginItems();
void FCRemoveApplicationFromLoginItems();

#endif

BOOL FCUserDefaultsGetBoolForKey(NSString *key);
BOOL FCUserDefaultsGetBoolForKeyWithDefault(NSString *key, BOOL defaultValue);




