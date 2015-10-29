// 
// NSAlertAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSAlertAdditions.h"

@implementation NSAlert (FCAlertAdditions)

-(BOOL)_isDefaultButton:(NSModalResponse)response{
	if ([[[self buttons] firstObject] tag] == NSAlertFirstButtonReturn){
		return response == NSAlertFirstButtonReturn;
	}
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-W"
		return response == NSAlertDefaultReturn;
	#pragma clang diagnostic pop
}
-(void)_prepareAccessoryTextFieldWithInitialValue:(NSString*)initialValue secure:(BOOL)secure{
	if (initialValue == nil){
		initialValue = @"";
	}
	
	Class cl = secure ? [NSSecureTextField class] : [NSTextField class];
	NSTextField *accessory = [[cl alloc] initWithFrame:NSMakeRect(0.0, 0.0, 290.0, 22.0)];
	[accessory setStringValue:initialValue];
	[self setAccessoryView:accessory];
	[accessory becomeFirstResponder];
}

-(NSPopUpButton *)createAccessoryPopUpButtonWithMenuItems:(NSArray *)menuItems{
	NSPopUpButton *popUpButton = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0.0, 0.0, 300.0, 22.0) pullsDown:NO];
	[self setAccessoryView:popUpButton];
	
	BOOL anyImageTooLargeForInlineDisplay = NO;
	
	NSMenu *menu = [[NSMenu alloc] init];
	for (NSMenuItem *item in menuItems){
		if ([item image].size.height > 16.0){
			// This image wouldn't fit the pop up button -> we need to allow scaling
			anyImageTooLargeForInlineDisplay = YES;
		}
		[menu addItem:item];
	}
	[popUpButton setMenu:menu];
	
	if (anyImageTooLargeForInlineDisplay){
		[[popUpButton cell] setImageScaling:NSImageScaleProportionallyDown];
	}
	
	return popUpButton;
}

-(void)beginSheetModalWithTextField:(NSString*)initialValue forWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector{
	if (initialValue == nil){
		initialValue = @"";
	}
	
	NSTextField *accessory = [[NSTextField alloc] initWithFrame:NSMakeRect(0.0, 0.0, 290.0, 22.0)];
	[accessory setStringValue:initialValue];
	[self setAccessoryView:accessory];
	
	[self beginSheetModalForWindow:window modalDelegate:delegate didEndSelector:didEndSelector contextInfo:(void*)accessory];
	
	// Make sure the field's focused
	[[accessory window] makeFirstResponder:accessory];
}

-(void)beginSheetModalWithSecureTextField:(NSString*)initialValue forWindow:(NSWindow *)window completionHandler:(void (^)(NSModalResponse))handler{
	[self beginSheetModalWithTextField:initialValue secure:YES forWindow:window completionHandler:handler];
}
-(void)beginSheetModalWithTextField:(NSString*)initialValue forWindow:(NSWindow *)window completionHandler:(void (^)(NSModalResponse))handler{
	[self beginSheetModalWithTextField:initialValue secure:NO forWindow:window completionHandler:handler];
}
-(void)beginSheetModalWithTextField:(NSString*)initialValue secure:(BOOL)secure forWindow:(NSWindow *)window completionHandler:(void (^)(NSModalResponse))handler{
	if (initialValue == nil){
		initialValue = @"";
	}
	
	NSTextField *accessory = [[secure ? [NSSecureTextField class] : [NSTextField class] alloc] initWithFrame:NSMakeRect(0.0, 0.0, 290.0, 22.0)];
	[accessory setStringValue:initialValue];
	[self setAccessoryView:accessory];
	
	[self beginSheetModalForWindow:window completionHandler:handler];
	
	// Make sure the field's focused
	[[accessory window] makeFirstResponder:accessory];
}

-(NSModalResponse)runModalOnMainThread{
	if ([NSThread currentThread] == [NSThread mainThread]){
		return [self runModal];
	}
	
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(runModal)]];
	[invocation setSelector:@selector(runModal)];
	[invocation performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:self waitUntilDone:YES];
	
	void *result = NULL;
	[invocation getReturnValue:&result];
	
	return (NSModalResponse)result;
}
-(NSString*)runModalWithTextField:(NSString*)initialValue{
	[self _prepareAccessoryTextFieldWithInitialValue:initialValue secure:NO];
	
	
	
	if (![self _isDefaultButton:[self runModal]]){
		return nil; //Cancelled
	}
	
	return [(NSTextField*)[self accessoryView] stringValue];
}
-(NSString*)runModalOnMainThreadWithTextField:(NSString *)initialValue{
	return [self runModalOnMainThreadWithTextField:initialValue secure:NO];
}
-(NSString *)runModalOnMainThreadWithTextField:(NSString *)initialValue secure:(BOOL)secure{
	[self _prepareAccessoryTextFieldWithInitialValue:initialValue secure:secure];
	
	if (![self _isDefaultButton:[self runModalOnMainThread]]){
		return nil; //Cancelled
	}
	
	return [(NSTextField*)[self accessoryView] stringValue];
}
@end

