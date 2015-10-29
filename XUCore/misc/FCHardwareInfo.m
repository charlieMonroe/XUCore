// 
// FCHardwareInfo.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCHardwareInfo.h"

#import "FCLog.h"
#import "NSStringAdditions.h"

#include <sys/sysctl.h>
#import <SystemConfiguration/SystemConfiguration.h>

#if !TARGET_OS_IPHONE
	NSString *FCComputerIP4Address(void){
		SCDynamicStoreRef dynRef=SCDynamicStoreCreate(kCFAllocatorSystemDefault, (CFStringRef)@"Whatever you want", NULL, NULL);
		// Get all available interfaces IPv4 addresses
		NSArray *interfaceList=(__bridge_transfer NSArray*)SCDynamicStoreCopyKeyList(dynRef,(CFStringRef)@"State:/Network/Interface/.*/IPv4");

		FCLog(@"FCComputerIP4Address() - Found interfaces: %@", interfaceList);
		
		for (NSString *interface in interfaceList) {
			NSDictionary *interfaceEntry = (__bridge_transfer NSDictionary*)SCDynamicStoreCopyValue(dynRef,(__bridge CFStringRef)interface);
			NSArray *adList = [interfaceEntry objectForKey:@"Addresses"];
			
			FCLog(@"FCComputerIP4Address() - %@ -> addresses: %@", interface, adList);
			
			for (NSString *address in adList){
				if ([address isEqualToString:@"127.0.0.1"] || [address isEqualToString:@"0.0.0.0"]){
					continue;
				}
				
				return address;
			}
		}
		
		return @"";
	}
#endif

NSString *FCComputerSerialNumber(){
	#if !TARGET_OS_IPHONE
		CFStringRef serialNumber = NULL;
		io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
		if (platformExpert){
			CFTypeRef serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, CFSTR(kIOPlatformSerialNumberKey), kCFAllocatorDefault, 0);
			serialNumber = (CFStringRef)serialNumberAsCFString;
			IOObjectRelease(platformExpert);
		}
		NSString *result;
		if (serialNumber){
			result = (__bridge NSString*)serialNumber;
		}else{
			result = @"unknown";
		}
		
		return result;
	#else
		return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
	#endif
}

NSString *FCMD5Hash(NSString *inputString){
	return [inputString MD5Digest];
}

NSString *FCComputerModel(void){
	size_t len = 0;
	sysctlbyname("hw.model", NULL, &len, NULL, 0);
	
	if (len)
	{
		char *model = malloc(len*sizeof(char));
		sysctlbyname("hw.model", model, &len, NULL, 0);
		NSString *model_ns = [NSString stringWithUTF8String:model];
		free(model);
		return model_ns;
	}
	
	return @"Just an Apple Computer"; //incase model name can't be read
}

