// 
// NSBundleAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


@import Foundation;

//Returns the bundle where is the class of object
//Typically used as FCCurrentBundle(self);
NSBundle *FCCurrentBundle(NSObject *object);

@interface NSBundle (NSBundleAdditions)

@end

