// 
// NSButtonCellAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSButtonCellAdditions.h"


@implementation NSButtonCell (MouseLocationAdditions)

-(BOOL)mouseInside{
	return self->_bcFlags2.mouseInside;
}
-(void)setMouseInside:(BOOL)isInside{
	self->_bcFlags2.mouseInside = (int)isInside;
}

@end
