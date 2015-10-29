// 
// FCTimeUtilities.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#ifndef Eon_FCTimeUtilities_h
#define Eon_FCTimeUtilities_h

typedef enum {
	FCTimeRoundingFloor,
	FCTimeRoundingNearest,
	FCTimeRoundingCeiling
} FCTimeRoundingDirection;

unsigned long long FCRoundTime(unsigned long long t, FCTimeRoundingDirection direction, unsigned int minutes);

#endif

