//
//  XUTopLeftWindowCornerView.m
//  Downie
//
//  Created by Charlie Monroe on 10/10/13.
//  Copyright (c) 2013 Charlie Monroe Software. All rights reserved.
//

#import "XUTopLeftWindowCornerView.h"

@implementation XUTopLeftWindowCornerView

-(NSRect)frameForWindowBounds:(NSRect)bounds andRealFrame:(NSRect)realFrame{
	NSRect retRect = NSMakeRect(0.0, bounds.size.height - NSHeight(realFrame), NSWidth(realFrame), NSHeight(realFrame));
	return retRect;
}

@end
