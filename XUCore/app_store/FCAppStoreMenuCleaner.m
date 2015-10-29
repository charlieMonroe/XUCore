// 
// FCAppStoreMenuCleaner.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCAppStoreMenuCleaner.h"

void FCCleanMenu(NSMenu *menu){
	for (NSInteger i = [menu numberOfItems] - 1; i >= 0; --i){
		if ([[menu itemAtIndex:i] tag] == 127){
			[menu removeItemAtIndex:i];
			continue;
		}
		if ([[menu itemAtIndex:i] hasSubmenu]){
			FCCleanMenu([[menu itemAtIndex:i] submenu]);
		}
	}
}


void FCCleanMenuBar(void){
	NSMenu *menu = [[NSApplication sharedApplication] mainMenu];
	FCCleanMenu(menu);
}

