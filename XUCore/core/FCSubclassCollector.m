// 
// FCSubclassCollector.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCSubclassCollector.h"
#import <objc/runtime.h>

static inline BOOL FCClassKindOfClass(Class inspectedClass, Class wantedSuperclass){
	//We've hit the root, so no, it's not
	if (inspectedClass==nil){
		return NO;
	}
	//It's the class, yay!
	if (inspectedClass == wantedSuperclass){
		return YES;
	}
	//Recursively call the function on the superclass of inspectedClass
	return FCClassKindOfClass(class_getSuperclass(inspectedClass), wantedSuperclass);
}

BOOL FCClassIsSubclassOfClass(Class superclass, Class subclass){
	return FCClassKindOfClass(subclass, superclass);
}


NSMutableArray *FCAllSubclassesOfClass(Class class){
	NSMutableArray *result = [NSMutableArray array];
	
	int numClasses;
	Class *classes = NULL;
	
	//Get the number of classes in the ObjC runtime
	classes = NULL;
	numClasses = objc_getClassList(NULL, 0);
	
	if (numClasses > 0){
		//Get them all
		classes = (Class*)malloc(sizeof(Class) * numClasses);
		numClasses = objc_getClassList(classes, numClasses);
		int i;
		for (i = 0; i < numClasses; ++i){
			//Go through the classes, find out if the class is kind of _XUModule and then add it to the list	
			if (FCClassKindOfClass(classes[i], class) && classes[i] != class){
				[result addObject:classes[i]];
			}
		}
		//Free the list
		free(classes);
	}
	
	return result;
}
	



