// 
// FCApplication.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCApplication.h"

#import "NSEventAdditions.h"

#import "FCLocalizationSupport.h"
#import "FCLog.h"

@interface NSView (FCFirstReponderSearchingAdditions)
-(id)suitableFirstResponder;
@end
@implementation NSView (FCFirstReponderSearchingAdditions)
-(id)suitableFirstResponder{
	for (NSView *view in [self subviews]){
		if ([view isKindOfClass:[NSTextField class]]){
			NSTextField *field = (NSTextField*)view;
			if ([field isEditable]){
				return view;
			}
		}
		id result = [view suitableFirstResponder];
		if (result != nil){
			return result;
		}
	}
	return nil;
}
@end



@implementation FCApplication


+(NSString *)versionNumber{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: @"1.0";
}
+(NSString *)buildNumber{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] ?: @"0";
}



-(id<FCArrowKeyEventObserver>)currentArrayKeyEventsObserver{
	return _arrowKeyEventObserver;
}
-(BOOL)isForegroundApplication{
	return [[NSRunningApplication currentApplication] isActive];
}
-(BOOL)isRunningInModalMode{
	return _isModal;
}
-(void)registerObjectForArrowKeyEvents:(id<FCArrowKeyEventObserver>)obj{
	FCLog(@"%s - registering %@ as arrow key event observer", __FCFUNCTION__, obj);
	_arrowKeyEventObserver = obj;
}
-(void)restart{
	NSURL *bundleURL = [[NSBundle mainBundle] bundleURL];
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:bundleURL]];
	
	[NSApp activateIgnoringOtherApps:YES];
	
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:FCLocalizedFormattedString(@"%@ will now quit. Please, launch it again manually.", [[NSProcessInfo processInfo] processName])];
	[alert addButtonWithTitle:FCLocalizedString(@"OK")];
	[alert runModal];
	exit(0);
}
-(NSInteger)runModalForWindow:(NSWindow *)theWindow{
	[self activateIgnoringOtherApps:YES];
	_isModal = YES;
	
	NSResponder *firstResp = [theWindow firstResponder];
	if (firstResp == nil || firstResp == theWindow){
		firstResp = [[theWindow contentView] suitableFirstResponder];
	}
	
	[theWindow makeFirstResponder:firstResp];
	
	return [super runModalForWindow:theWindow];
}
-(void)sendEvent:(NSEvent *)theEvent{
	if (_isModal && [theEvent type] == NSKeyDown){
		NSWindow *w = [self keyWindow];
		unsigned short keyCode = [theEvent keyCode];
		if (keyCode == FCEscape || keyCode == FCEnter || keyCode == FCReturn){
			[w makeFirstResponder:[w nextResponder]];
			[w keyDown:theEvent];
		}else if (keyCode == 9 && [theEvent modifierFlags] & NSCommandKeyMask){
			//Command-V
			if ([[w firstResponder] isKindOfClass:[NSTextView class]]){
				if ([[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString] != nil){
					[(NSTextView*)[w firstResponder] paste:nil];
				}
			}else{
				[super sendEvent:theEvent];
			}
		}else{
			[super sendEvent:theEvent];
		}
		return;
	}
	
	// Not modal
	
	BOOL windowIsEditingAField = [[[self mainWindow] firstResponder] isKindOfClass:[NSTextView class]];
	if ([_arrowKeyEventObserver respondsToSelector:@selector(selectionChangeAllowedEvenWhenEditing)]){
		if ([_arrowKeyEventObserver selectionChangeAllowedEvenWhenEditing]){
			windowIsEditingAField = NO;
		}
	}
	
	if ([theEvent type] == NSKeyDown && !windowIsEditingAField){
		NSUInteger flags = [theEvent modifierFlags];
		if (((flags & NSCommandKeyMask) == 0)
			&& ((flags & NSShiftKeyMask) == 0)
			&& ((flags & NSAlternateKeyMask) == 0)
			){
			unsigned short keyCode = [theEvent keyCode];
			if (keyCode == FCKeyDown && _arrowKeyEventObserver != nil){
				[_arrowKeyEventObserver selectNext:theEvent];
				return;
			}else if (keyCode == FCKeyUp && _arrowKeyEventObserver != nil){
				[_arrowKeyEventObserver selectPrevious:theEvent];
				return;
			}else if ((keyCode == FCReturn || keyCode == FCEnter) && _arrowKeyEventObserver != nil){
				[_arrowKeyEventObserver select:theEvent];
				return;
			}
		}
	}
	
	if ([theEvent type] == NSKeyUp && !windowIsEditingAField){
		unsigned short keyCode = [theEvent keyCode];
		if ((keyCode == FCEscape) && _arrowKeyEventObserver != nil){
			if ([_arrowKeyEventObserver respondsToSelector:@selector(cancel:)]){
				[_arrowKeyEventObserver cancel:theEvent];
				return;
			}
		}
	}
	
	[super sendEvent:theEvent];
}
-(void)stopModal{
	_isModal = NO;
	[super stopModal];
}
-(void)stopModalWithCode:(NSInteger)returnCode{
	_isModal = NO;
	[super stopModalWithCode:returnCode];
}
-(void)unregisterArrowKeyEventsObserver{
	FCLog(@"%s - unregistering %@ as arrow key event observer", __FCFUNCTION__, _arrowKeyEventObserver);
	_arrowKeyEventObserver = nil;
}
@end

