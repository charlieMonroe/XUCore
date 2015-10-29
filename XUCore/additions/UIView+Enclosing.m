//
//  UIView+Enclosing.m
//  Navigator
//
//  Created by Charlie Monroe on 12/19/14.
//  Copyright (c) 2014 Mews Systems. All rights reserved.
//

#import "UIView+Enclosing.h"

@implementation UIView (Enclosing)

-(id)_enclosingViewOfClass:(Class)class{
	UIView *view = self;
	while (view != nil) {
		if ([view isKindOfClass:class]){
			return view;
		}
		
		view = [view superview];
	}
	
	return nil;
}

-(UIScrollView *)enclosingScrollView{
	return [self _enclosingViewOfClass:[UIScrollView class]];
}
-(UITableView *)enclosingTableView{
	return [self _enclosingViewOfClass:[UITableView class]];
}
-(UITableViewCell *)enclosingTableViewCell{
	return [self _enclosingViewOfClass:[UITableViewCell class]];
}

@end
