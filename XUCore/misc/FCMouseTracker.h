// 
// FCMouseTracker.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>

@protocol FCMouseTrackingObserver <NSObject>
@optional
-(void)mouseClickedAtPoint:(CGPoint)point atDisplay:(CGDirectDisplayID)displayID withEventFlags:(CGEventFlags)flags;
-(void)mouseMovedToPoint:(CGPoint)point atDisplay:(CGDirectDisplayID)displayID withEventFlags:(CGEventFlags)flags;

@end

@interface FCMouseTracker : NSObject {
	NSMutableArray *_observers;
}

+(FCMouseTracker*)sharedMouseTracker;

-(void)addObserver:(id<FCMouseTrackingObserver>)observer;
-(void)removeObserver:(id<FCMouseTrackingObserver>)observer;

@end

