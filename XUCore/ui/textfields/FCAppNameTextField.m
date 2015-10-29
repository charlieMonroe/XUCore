// 
// FCAppNameTextField.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCAppNameTextField.h"

#import "FCLocalizationSupport.h"


@implementation FCAppNameTextField
-(void)awakeFromNib{
	[self setStringValue:FCLocalizedString([self stringValue])];
	[self setStringValue:[[self stringValue] stringByReplacingOccurrencesOfString:@"%AppName%" withString:[[NSProcessInfo processInfo] processName]]];
}
@end

