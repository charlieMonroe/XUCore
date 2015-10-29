// 
// FCKeychain.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>
#import <Security/Security.h>

void FCSetPasswordInDefaultKeychain(NSString *name, NSString* password, NSString* keyItName);
NSString* FCPasswordFromDefaultKeychain(NSString* keyItName, NSString* accName); // May return nil

