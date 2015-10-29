// 
// NSAlertAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 

#if !TARGET_OS_IPHONE

#import <Cocoa/Cocoa.h>


@interface NSAlert (FCAlertAdditions)

/** This creates a pop up button as accessory view in the alert and populates it
 * with menuItems.
 */
-(nonnull NSPopUpButton *)createAccessoryPopUpButtonWithMenuItems:(nonnull NSArray *)menuItems;

-(void)beginSheetModalWithTextField:(nonnull NSString *)initialValue forWindow:(nonnull NSWindow *)window modalDelegate:(nullable id)delegate didEndSelector:(nullable SEL)didEndSelector DEPRECATED_ATTRIBUTE; // The NSTextField containing the value is set as contextInfo

-(void)beginSheetModalWithSecureTextField:(nonnull NSString *)initialValue forWindow:(nonnull NSWindow *)window completionHandler:(nullable void (^)(NSModalResponse))handler;
-(void)beginSheetModalWithTextField:(nonnull NSString *)initialValue forWindow:(nonnull NSWindow *)window completionHandler:(nullable void (^)(NSModalResponse))handler; // Use [alert accessoryView] to get the message field
-(void)beginSheetModalWithTextField:(nonnull NSString *)initialValue secure:(BOOL)secure forWindow:(nonnull NSWindow *)window completionHandler:(nullable void (^)(NSModalResponse))handler;

-(NSModalResponse)runModalOnMainThread;

-(nullable NSString *)runModalWithTextField:(nonnull NSString *)initialValue; //Returns nil if the dialog is cancelled (NSAlertAlternateReturn) or the string value
-(nullable NSString *)runModalOnMainThreadWithTextField:(nonnull NSString *)initialValue; //Returns nil if the dialog is cancelled (NSAlertAlternateReturn) or the string value
-(nullable NSString *)runModalOnMainThreadWithTextField:(nonnull NSString *)initialValue secure:(BOOL)secure;

@end

#endif
