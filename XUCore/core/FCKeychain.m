// 
// FCKeychain.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCKeychain.h"

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

/*
 The KeychainItemWrapper class is an abstraction layer for the iPhone Keychain communication. It is merely a
 simple wrapper to provide a distinct barrier between all the idiosyncracies involved with the Keychain
 CF/NS container objects.
 */
@interface KeychainItemWrapper : NSObject
{
	NSMutableDictionary *keychainItemData;      // The actual keychain item data backing store.
	NSMutableDictionary *genericPasswordQuery;  // A placeholder for the generic keychain item query used to locate the item.
}

@property (nonatomic, retain) NSMutableDictionary *keychainItemData;
@property (nonatomic, retain) NSMutableDictionary *genericPasswordQuery;

// Designated initializer.
- (id)initWithIdentifier: (NSString *)identifier accessGroup:(NSString *) accessGroup;
- (void)setObject:(id)inObject forKey:(id)key;
- (id)objectForKey:(id)key;

// Initializes and resets the default generic keychain item data.
- (void)resetKeychainItem;

@end

/*
 
 These are the default constants and their respective types,
 available for the kSecClassGenericPassword Keychain Item class:
 
 kSecAttrAccessGroup         -       CFStringRef
 kSecAttrCreationDate        -       CFDateRef
 kSecAttrModificationDate    -       CFDateRef
 kSecAttrDescription         -       CFStringRef
 kSecAttrComment             -       CFStringRef
 kSecAttrCreator             -       CFNumberRef
 kSecAttrType                -       CFNumberRef
 kSecAttrLabel               -       CFStringRef
 kSecAttrIsInvisible         -       CFBooleanRef
 kSecAttrIsNegative          -       CFBooleanRef
 kSecAttrAccount             -       CFStringRef
 kSecAttrService             -       CFStringRef
 kSecAttrGeneric             -       CFDataRef
 
 See the header file Security/SecItem.h for more details.
 
 */

@interface KeychainItemWrapper (PrivateMethods)
/*
 The decision behind the following two methods (secItemFormatToDictionary and dictionaryToSecItemFormat) was
 to encapsulate the transition between what the detail view controller was expecting (NSString *) and what the
 Keychain API expects as a validly constructed container class.
 */
- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert;
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert;

// Updates the item in the keychain, or adds it if it doesn't exist.
- (void)writeToKeychain;

@end

@implementation KeychainItemWrapper

@synthesize keychainItemData, genericPasswordQuery;

- (id)initWithIdentifier: (NSString *)identifier accessGroup:(NSString *) accessGroup;
{
	if (self = [super init])
	{
		// Begin Keychain search setup. The genericPasswordQuery leverages the special user
		// defined attribute kSecAttrGeneric to distinguish itself between other generic Keychain
		// items which may be included by the same application.
		genericPasswordQuery = [[NSMutableDictionary alloc] init];
		
		[genericPasswordQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
		[genericPasswordQuery setObject:identifier forKey:(__bridge id)kSecAttrGeneric];
		
		// The keychain access group attribute determines if this item can be shared
		// amongst multiple apps whose code signing entitlements contain the same keychain access group.
		if (accessGroup != nil)
		{
#if TARGET_IPHONE_SIMULATOR
			// Ignore the access group if running on the iPhone simulator.
			//
			// Apps that are built for the simulator aren't signed, so there's no keychain access group
			// for the simulator to check. This means that all apps can see all keychain items when run
			// on the simulator.
			//
			// If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
			// simulator will return -25243 (errSecNoAccessForItem).
#else
			[genericPasswordQuery setObject:accessGroup forKey:(__bridge id)kSecAttrAccessGroup];
#endif
		}
		
		// Use the proper search constants, return only the attributes of the first match.
		[genericPasswordQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
		[genericPasswordQuery setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
		
		NSDictionary *tempQuery = [NSDictionary dictionaryWithDictionary:genericPasswordQuery];
		
		CFDictionaryRef outDictionaryRef = nil;
		
		if (! SecItemCopyMatching((__bridge CFDictionaryRef)tempQuery, (CFTypeRef *)&outDictionaryRef) == noErr)
		{
			// Stick these default values into keychain item if nothing found.
			[self resetKeychainItem];
			
			// Add the generic attribute and the keychain access group.
			[keychainItemData setObject:identifier forKey:(__bridge id)kSecAttrGeneric];
			if (accessGroup != nil)
			{
#if TARGET_IPHONE_SIMULATOR
				// Ignore the access group if running on the iPhone simulator.
				//
				// Apps that are built for the simulator aren't signed, so there's no keychain access group
				// for the simulator to check. This means that all apps can see all keychain items when run
				// on the simulator.
				//
				// If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
				// simulator will return -25243 (errSecNoAccessForItem).
#else
				[keychainItemData setObject:accessGroup forKey:(__bridge id)kSecAttrAccessGroup];
#endif
			}
		}
		else
		{
			// load the saved data from Keychain.
			self.keychainItemData = [self secItemFormatToDictionary:(__bridge NSDictionary*)outDictionaryRef];
		}
		
		if (outDictionaryRef != NULL){
			CFRelease(outDictionaryRef);
		}
	}
	
	return self;
}

- (void)setObject:(id)inObject forKey:(id)key
{
	if (inObject == nil) return;
	id currentObject = [keychainItemData objectForKey:key];
	if (![currentObject isEqual:inObject])
	{
		[keychainItemData setObject:inObject forKey:key];
		[self writeToKeychain];
	}
}

- (id)objectForKey:(id)key
{
	return [keychainItemData objectForKey:key];
}

- (void)resetKeychainItem
{
	OSStatus junk = noErr;
	if (!keychainItemData)
	{
		self.keychainItemData = [[NSMutableDictionary alloc] init];
	}
	else if (keychainItemData)
	{
		NSMutableDictionary *tempDictionary = [self dictionaryToSecItemFormat:keychainItemData];
		junk = SecItemDelete((__bridge CFDictionaryRef)tempDictionary);
		NSAssert( junk == noErr || junk == errSecItemNotFound, @"Problem deleting current dictionary." );
	}
	
	// Default attributes for keychain item.
	[keychainItemData setObject:@"" forKey:(__bridge id)kSecAttrAccount];
	[keychainItemData setObject:@"" forKey:(__bridge id)kSecAttrLabel];
	[keychainItemData setObject:@"" forKey:(__bridge id)kSecAttrDescription];
	
	// Default data for keychain item.
	[keychainItemData setObject:@"" forKey:(__bridge id)kSecValueData];
}

- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert
{
	// The assumption is that this method will be called with a properly populated dictionary
	// containing all the right key/value pairs for a SecItem.
	
	// Create a dictionary to return populated with the attributes and data.
	NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
	
	// Add the Generic Password keychain item class attribute.
	[returnDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
	
	// Convert the NSString to NSData to meet the requirements for the value type kSecValueData.
	// This is where to store sensitive data that should be encrypted.
	NSString *passwordString = [dictionaryToConvert objectForKey:(__bridge id)kSecValueData];
	[returnDictionary setObject:[passwordString dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
	
	return returnDictionary;
}

- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert
{
	// The assumption is that this method will be called with a properly populated dictionary
	// containing all the right key/value pairs for the UI element.
	
	// Create a dictionary to return populated with the attributes and data.
	NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
	
	// Add the proper search key and class attribute.
	[returnDictionary setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
	[returnDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
	
	// Acquire the password data from the attributes.
	CFDataRef passwordDataRef = NULL;
	if (SecItemCopyMatching((__bridge CFDictionaryRef)returnDictionary, (CFTypeRef *)&passwordDataRef) == noErr)
	{
		// Remove the search, class, and identifier key/value, we don't need them anymore.
		[returnDictionary removeObjectForKey:(__bridge id)kSecReturnData];
		
		// Add the password to the dictionary, converting from NSData to NSString.
		NSString *password = [[NSString alloc] initWithBytes:[(__bridge NSData*)passwordDataRef bytes] length:[(__bridge NSData*)passwordDataRef length]
									    encoding:NSUTF8StringEncoding];
		[returnDictionary setObject:password forKey:(__bridge id)kSecValueData];
	}
	else
	{
		// Don't do anything if nothing is found.
		NSAssert(NO, @"Serious error, no matching item found in the keychain.\n");
	}
	
	CFRelease(passwordDataRef);
	
	return returnDictionary;
}

- (void)writeToKeychain
{
	CFDictionaryRef attributesRef = NULL;
	NSMutableDictionary *updateItem = NULL;
	OSStatus result;
	
	if (SecItemCopyMatching((__bridge CFDictionaryRef)genericPasswordQuery, (CFTypeRef *)&attributesRef) == noErr)
	{
		// First we need the attributes from the Keychain.
		updateItem = [NSMutableDictionary dictionaryWithDictionary:(__bridge id)attributesRef];
		// Second we need to add the appropriate search key/values.
		[updateItem setObject:[genericPasswordQuery objectForKey:(__bridge id)kSecClass] forKey:(__bridge id)kSecClass];
		
		// Lastly, we need to set up the updated attribute list being careful to remove the class.
		NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:keychainItemData];
		[tempCheck removeObjectForKey:(__bridge id)kSecClass];
		
#if TARGET_IPHONE_SIMULATOR
		// Remove the access group if running on the iPhone simulator.
		//
		// Apps that are built for the simulator aren't signed, so there's no keychain access group
		// for the simulator to check. This means that all apps can see all keychain items when run
		// on the simulator.
		//
		// If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
		// simulator will return -25243 (errSecNoAccessForItem).
		//
		// The access group attribute will be included in items returned by SecItemCopyMatching,
		// which is why we need to remove it before updating the item.
		[tempCheck removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
#endif
		
		// An implicit assumption is that you can only update a single item at a time.
		
		result = SecItemUpdate((__bridge CFDictionaryRef)updateItem, (__bridge CFDictionaryRef)tempCheck);
		NSAssert( result == noErr, @"Couldn't update the Keychain Item." );
	}
	else
	{
		// No previous item found; add the new one.
		result = SecItemAdd((__bridge CFDictionaryRef)[self dictionaryToSecItemFormat:keychainItemData], NULL);
		NSAssert( result == noErr, @"Couldn't add the Keychain Item." );
	}
}

@end

void FCSetPasswordInDefaultKeychain(NSString* name, NSString* password, NSString* keyItName){
	if (keyItName == nil || name == nil || password == nil){
		return;
	}
	
	KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:keyItName accessGroup:nil];
	[keychainItem setObject:name forKey:(__bridge id)(kSecAttrAccount)];
	[keychainItem setObject:password forKey:(__bridge id)(kSecValueData)];
}

NSString* FCPasswordFromDefaultKeychain(NSString* keyItName, NSString* accName){
	if (keyItName == nil || accName == nil){
		return @"";
	}
	
	KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:keyItName accessGroup:nil];
	return [keychainItem objectForKey:(__bridge id)(kSecValueData)];
}

#else

void FCSetPasswordInDefaultKeychain(NSString* name, NSString* password, NSString* keyItName){
	if (keyItName == nil || name == nil || password == nil){
		return;
	}
	
	OSStatus theStatus = noErr;
	char *utf8acc = (char *)[name UTF8String];
	char *utf8pass = (char *)[password UTF8String];
	char *utf8keychainItemName = (char*)[keyItName UTF8String];
	
	theStatus = SecKeychainAddGenericPassword(NULL, (UInt32)strlen(utf8keychainItemName), utf8keychainItemName, (UInt32)strlen(utf8acc), utf8acc, (UInt32)strlen(utf8pass), utf8pass, NULL);
	
	if (theStatus == errSecDuplicateItem){
		SecKeychainItemRef item = nil;
		char *buffer;
		UInt32 passwordLen;
		theStatus = SecKeychainFindGenericPassword(NULL, (UInt32)strlen(utf8keychainItemName), utf8keychainItemName, (UInt32)strlen(utf8acc), utf8acc, &passwordLen, (void *)&buffer, &item);
		
		if (noErr == theStatus){
			SecKeychainItemFreeContent(NULL, buffer);
			if ([[[NSString alloc] initWithBytes:buffer length:passwordLen encoding:[NSString defaultCStringEncoding]] isEqualToString:password]){
				return;
			}
			SecKeychainItemModifyContent(item, NULL, (UInt32)strlen(utf8pass), utf8pass);
		}
	}
}
NSString* FCPasswordFromDefaultKeychain(NSString* keyItName, NSString* accName){
	if (keyItName == nil || accName == nil){
		return @"";
	}
	SecKeychainItemRef item = nil;
	OSStatus theStatus = noErr;
	char *buffer;
	UInt32 passwordLen;
	
	char *utf8 = (char *)[accName UTF8String];
	char *utf8keychainItemName = (char*)[keyItName UTF8String];
	
	theStatus = SecKeychainFindGenericPassword(NULL, (UInt32)strlen(utf8keychainItemName), utf8keychainItemName, (UInt32)strlen(utf8), utf8, &passwordLen, (void *)&buffer, &item);
	
	if (noErr == theStatus)
	{
		if (passwordLen > 0){
			// release buffer allocated by SecKeychainFindGenericPassword
			NSString *str = [[NSString alloc] initWithBytes:buffer length:passwordLen encoding:[NSString defaultCStringEncoding]];
			SecKeychainItemFreeContent(NULL, buffer);
			return str;
		}else{
			// release buffer allocated by SecKeychainFindGenericPassword
			SecKeychainItemFreeContent(NULL, buffer);
			return @""; // if we have noErr but also no length, password is empty
		}
	}
	return nil;
}


#endif
