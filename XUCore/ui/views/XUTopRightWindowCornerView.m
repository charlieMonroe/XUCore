//
//  XUTopRightWindowCornerView.m
//  Downie
//
//  Created by Charlie Monroe on 10/10/13.
//  Copyright (c) 2013 Charlie Monroe Software. All rights reserved.
//

#import "XUTopRightWindowCornerView.h"

@implementation XUTopRightWindowCornerView

-(NSRect)frameForWindowBounds:(NSRect)bounds andRealFrame:(NSRect)realFrame{
	NSRect retRect = NSMakeRect(bounds.size.width - NSWidth(realFrame) - 5.0, bounds.size.height - NSHeight(realFrame), NSWidth(realFrame), NSHeight(realFrame));
	retRect = NSIntegralRect(retRect);
	
	--retRect.origin.y;
	
	return retRect;
}

@end
