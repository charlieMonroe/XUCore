// 
// FCApplication.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Cocoa/Cocoa.h>

/*
 Over NSApplication adds better support for modal windows.
 */

@protocol FCArrowKeyEventObserver;

@interface FCApplication : NSApplication {
	BOOL _isModal;
	__weak id<FCArrowKeyEventObserver> _arrowKeyEventObserver; //weak-ref
}

/// Returns build number, e.g. 345
+(nonnull NSString *)buildNumber;

/// Returns version number, e.g. 1.2.3
+(nonnull NSString *)versionNumber;


-(nullable id<FCArrowKeyEventObserver>)currentArrayKeyEventsObserver;
-(BOOL)isForegroundApplication;
-(BOOL)isRunningInModalMode;
-(void)registerObjectForArrowKeyEvents:(nonnull id <FCArrowKeyEventObserver>)obj;
-(void)restart;
-(void)unregisterArrowKeyEventsObserver;

@end

@protocol FCArrowKeyEventObserver <NSObject>

-(void)select:(nonnull NSEvent *)anEvent;
-(void)selectNext:(nonnull NSEvent *)anEvent;
-(void)selectPrevious:(nonnull NSEvent *)anEvent;

@optional

-(void)cancel:(nonnull NSEvent *)anEvent;
-(BOOL)selectionChangeAllowedEvenWhenEditing;

@end


