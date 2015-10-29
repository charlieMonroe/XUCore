// 
// FCHardwareInfo.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>

#if !TARGET_OS_IPHONE
	extern NSString *FCComputerIP4Address(void);
#endif

extern NSString *FCComputerSerialNumber(void);
extern NSString *FCMD5Hash(NSString *inputString);

extern NSString *FCComputerModel(void);

