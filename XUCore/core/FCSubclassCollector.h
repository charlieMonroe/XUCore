// 
// FCSubclassCollector.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>

BOOL FCClassIsSubclassOfClass(Class __nonnull superclass, Class __nonnull subclass);

NSArray<Class>  * _Nonnull FCAllSubclassesOfClass(Class __nonnull class);



