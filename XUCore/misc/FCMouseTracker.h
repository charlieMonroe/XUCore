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

@interface FCMouseTracker : NSObject

+(nonnull instancetype)sharedMouseTracker;

-(void)addObserver:(nonnull id<FCMouseTrackingObserver>)observer;
-(void)removeObserver:(nonnull id<FCMouseTrackingObserver>)observer;

@end

