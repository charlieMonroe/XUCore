// 
// FCAppStoreHidingView.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCAppStoreHidingView.h"


@implementation FCAppStoreHidingView

-(void)awakeFromNib{
#if FC_APP_STORE_BUILD
	[self setHidden:YES];
#endif
}

@end

