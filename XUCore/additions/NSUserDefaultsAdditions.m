// 
// NSUserDefaultsAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSUserDefaultsAdditions.h"

#if !TARGET_OS_IPHONE
	#import <ServiceManagement/ServiceManagement.h>

BOOL FCApplicationIsInLoginItems(){
	BOOL isEnabled  = NO;
	
	NSString *appIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	
	// the easy and sane method (SMJobCopyDictionary) can pose problems when sandboxed. -_-
	CFArrayRef cfJobDicts = SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
	NSArray* jobDicts = (__bridge NSArray*)cfJobDicts;
	
	if (jobDicts && [jobDicts count] > 0) {
		for (NSDictionary* job in jobDicts) {
			//NSLog(@"%@", [job objectForKey:@"Label"]);
			if ([appIdentifier isEqualToString:[job objectForKey:@"Label"]]) {
				isEnabled = [[job objectForKey:@"OnDemand"] boolValue];
				break;
			}
		}
	}
	
	if (cfJobDicts != NULL){
		CFRelease(cfJobDicts);
	}
	
	return isEnabled;
}
void FCAddApplicationToLoginItems(){
	SMLoginItemSetEnabled((__bridge CFStringRef)[[NSBundle mainBundle] bundleIdentifier], true);
}
void FCRemoveApplicationFromLoginItems(){
	SMLoginItemSetEnabled((__bridge CFStringRef)[[NSBundle mainBundle] bundleIdentifier], false);
}

@implementation NSUserDefaults (FCAdditions)

+(void)addApplicationToLoginItems  __attribute__((deprecated)){
	[self addPathToLoginItems:[[NSBundle mainBundle] bundlePath]];
}
+(void)addPathToLoginItems:(NSString*)filePath  __attribute__((deprecated)){
	// Reference to shared file list
	LSSharedFileListRef theLoginItemsRefs = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	// CFURLRef to the insertable item.
	CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:filePath];
	
	// Actual insertion of an item.
	LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(theLoginItemsRefs, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
	
	// Clean up in case of success
	if (item)
		CFRelease(item);
}
+(BOOL)applicationIsInLoginItems __attribute__((deprecated)){
	return [self applicationIsInLoginItems:[[NSBundle mainBundle] bundlePath]];
}
+(BOOL)applicationIsInLoginItems:(NSString*)filePath __attribute__((deprecated)){
	filePath = [filePath stringByStandardizingPath];
	
	UInt32 seedValue;
	
	LSSharedFileListRef theLoginItemsRefs = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	CFURLRef thePath = NULL;
	
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	NSArray  *loginItemsArray = (__bridge_transfer NSArray *)LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	for (id item in loginItemsArray) {
		LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
		
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
			if ([[(__bridge NSURL *)thePath path] hasPrefix:filePath]){
				CFRelease(theLoginItemsRefs);
				return YES;
			}
		}
	}
	
	CFRelease(theLoginItemsRefs);
	if (thePath != NULL){
		CFRelease(thePath);
	}
	
	return NO;
}
+(void)removeApplicationFromLoginItems __attribute__((deprecated)){
	[self removePathFromLoginItems:[[NSBundle mainBundle] bundlePath]];
}
+(void)removePathFromLoginItems:(NSString*)filePath __attribute__((deprecated)){
	filePath = [filePath stringByStandardizingPath];
	
	UInt32 seedValue;
	
	LSSharedFileListRef theLoginItemsRefs = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	CFURLRef thePath = NULL;
	
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	NSArray  *loginItemsArray = (__bridge_transfer NSArray *)LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	for (id item in loginItemsArray) {
		LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, &thePath, NULL) == noErr) {
			if ([[(__bridge NSURL *)thePath path] hasPrefix:filePath]){
				LSSharedFileListItemRemove(theLoginItemsRefs, itemRef);
			}
		}
	}
	CFRelease(theLoginItemsRefs);
}

- (void)setColor:(NSColor *)aColor forKey:(NSString *)aKey{
	NSData *theData=[NSArchiver archivedDataWithRootObject:aColor];
	[self setObject:theData forKey:aKey];
}
- (NSColor *)colorForKey:(NSString *)aKey{
	NSColor *theColor=nil;
	NSData *theData=[self dataForKey:aKey];
	if (theData != nil)
		theColor=(NSColor *)[NSUnarchiver unarchiveObjectWithData:theData];
	return theColor;
}

@end

#endif

BOOL FCUserDefaultsGetBoolForKey(NSString *key){
	return FCUserDefaultsGetBoolForKeyWithDefault(key, NO);
}
BOOL FCUserDefaultsGetBoolForKeyWithDefault(NSString *key, BOOL defaultValue){
	NSNumber *numberObj = [[NSUserDefaults standardUserDefaults] objectForKey:key];
	return numberObj == nil ? defaultValue : [numberObj boolValue];
}



