//
//  XUPositionedWindowView.m
//  Downie
//
//  Created by Charlie Monroe on 9/10/14.
//  Copyright (c) 2014 Charlie Monroe Software. All rights reserved.
//

#import "XUPositionedWindowView.h"

#import "XUAbstract.h"

#import "NSArrayAdditions.h"
#import "FCLocalizationSupport.h"

@interface NSView (Secret)
-(void)_addKnownSubview:(NSView*)view;
@end

@implementation XUPositionedWindowView

-(void)_updateFramePosition{
	[self setFrame:[self frame]];
	
	[self setAutoresizingMask:NSViewMinXMargin];
}
-(void)awakeFromNib{
	if ([self shouldBeConnectedOnAwakeFromNib]){
		NSView *superview = [[_connectedToWindow contentView] superview];
		if ([_connectedToWindow respondsToSelector:@selector(addTitlebarAccessoryViewController:)]){
			if ([[_connectedToWindow titlebarAccessoryViewControllers] count] == 0){
				/** Since 10.10.2, the titlebar view is deferred in creation.
				 * We need to force the creation by adding a blank titlebar accessory
				 * view controller.
				 */
				NSTitlebarAccessoryViewController *controller = [[NSTitlebarAccessoryViewController alloc] init];
				[controller setLayoutAttribute:NSLayoutAttributeRight];
				[controller setView:[[NSView alloc] init]];
				[_connectedToWindow addTitlebarAccessoryViewController:controller];
			}
			
			superview = [[superview subviews] find:^BOOL(NSView *view) {
				return [view isKindOfClass:NSClassFromString(@"NSTitlebarContainerView")];
			}];
			
			superview = [[superview subviews] find:^BOOL(NSView *view) {
				return [view isKindOfClass:NSClassFromString(@"NSTitlebarView")];
			}];
			
			[superview addSubview:self];
		}else{
			[superview addSubview:self];
		}
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateFramePosition) name:NSWindowDidResizeNotification object:_connectedToWindow];
	[self _updateFramePosition];
	
	[self localizeView];
}
-(void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(NSRect)frame{
	return [self frameForWindowBounds:[[self superview] bounds] andRealFrame:[super frame]];
}
-(NSLayoutAttribute)layoutAttribute{
	return NSLayoutAttributeBottom;
}
-(BOOL)postsFrameChangedNotifications{
	return NO;
}
-(BOOL)shouldBeConnectedOnAwakeFromNib{
	return YES;
}

XUGenerateAbstractMethod(-(NSRect)frameForWindowBounds:(NSRect)bounds andRealFrame:(NSRect)realFrame);

@end
