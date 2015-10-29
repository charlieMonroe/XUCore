// 
// FCTimeUtilities.c
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#include <stdio.h>
#include "FCTimeUtilities.h"


unsigned long long FCRoundTime(unsigned long long t, FCTimeRoundingDirection direction, unsigned int minutes){
	unsigned long long remains = t % minutes;
	
	if (remains == 0){
		// Keep it
		return t;
	}

	if (direction == FCTimeRoundingFloor || (direction == FCTimeRoundingNearest && (remains < (minutes / 2)))){
		//down
		t -= remains;
	}else{
		//up
		t += (minutes - remains);
	}
	
	return t;
}

