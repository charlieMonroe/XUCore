// 
// FCMouseTracker.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCMouseTracker.h"
#import "FCLog.h"

@interface FCMouseTracker (FCPrivates)
-(void)_notifyObserversAboutClickAtPoint:(CGPoint)point atDisplay:(CGDirectDisplayID)displayID withEventFlags:(CGEventFlags)flags;
-(void)_notifyObserversAboutMovementToPoint:(CGPoint)point atDisplay:(CGDirectDisplayID)displayID withEventFlags:(CGEventFlags)flags;
@end



static CGEventRef FCMouseMovementEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon){
	CGPoint point = CGEventGetLocation(event);
	CGDirectDisplayID displayID = 0;
	uint32_t numOfDisplays = 0;
	CGGetDisplaysWithPoint(point, 1, &displayID, &numOfDisplays);
	if (numOfDisplays == 0){
		FCLog(@"%s - No displays at { %f, %f }", __FCFUNCTION__, point.x, point.y);
		return event;
	}
	
	CGEventFlags flags = CGEventGetFlags(event);
	FCMouseTracker *tracker = (__bridge FCMouseTracker*)refcon;
	
	if (type == kCGEventMouseMoved){
		[tracker _notifyObserversAboutMovementToPoint:point atDisplay:displayID withEventFlags:flags];
	}else if (type == kCGEventLeftMouseDown){
		[tracker _notifyObserversAboutClickAtPoint:point atDisplay:displayID withEventFlags:flags];
	}
	
	CGEventSetFlags(event, CGEventMaskBit(kCGEventMouseMoved));
	
	return event;
}

@implementation FCMouseTracker

+(FCMouseTracker *)sharedMouseTracker{
	static FCMouseTracker *_sharedTracker;
	if (_sharedTracker == nil){
		_sharedTracker = [[self alloc] init];
	}
	return _sharedTracker;
}

-(void)_notifyObserversAboutClickAtPoint:(CGPoint)point atDisplay:(CGDirectDisplayID)displayID withEventFlags:(CGEventFlags)flags{
	@synchronized(self){
		for (id<FCMouseTrackingObserver> observer in [_observers copy]){
			if ([observer respondsToSelector:@selector(mouseClickedAtPoint:atDisplay:withEventFlags:)]){
				[observer mouseClickedAtPoint:point atDisplay:displayID withEventFlags:flags];
			}
		}
	}
}
-(void)_notifyObserversAboutMovementToPoint:(CGPoint)point atDisplay:(CGDirectDisplayID)displayID withEventFlags:(CGEventFlags)flags{
	@synchronized(self){
		for (id<FCMouseTrackingObserver> observer in [_observers copy]){
			if ([observer respondsToSelector:@selector(mouseMovedToPoint:atDisplay:withEventFlags:)]){
				[observer mouseMovedToPoint:point atDisplay:displayID withEventFlags:flags];
			}
		}
	}
}
-(void)_trackingThread{
	@autoreleasepool {
	
		CFRunLoopSourceRef  eventSrc = NULL;
		CFRunLoopRef    runLoop = NULL;
		
		CFMachPortRef machPort = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionListenOnly, CGEventMaskBit(kCGEventLeftMouseDragged) | CGEventMaskBit(kCGEventLeftMouseDown) | CGEventMaskBit(kCGEventMouseMoved), FCMouseMovementEventCallback, (__bridge void *)(self));
		
		if ( machPort == NULL ){
			printf("[FCMouseTrackingColorPicker _trackingThread] - NULL event port\n");
			goto cleanup;
		}
		
		eventSrc = CFMachPortCreateRunLoopSource(NULL, machPort, 0);
		if ( eventSrc == NULL ){
			printf( "[FCMouseTrackingColorPicker _trackingThread] - No event run loop src?\n" );
			goto cleanup;
		}
		
		runLoop = CFRunLoopGetCurrent();
		if ( runLoop == NULL ){
			printf( "[FCMouseTrackingColorPicker _trackingThread] - No run loop?\n" );
			goto cleanup;
		}
		
		CFRunLoopAddSource(runLoop,  eventSrc, kCFRunLoopDefaultMode);
		CFRunLoopRun();
		
cleanup:
		if (machPort != NULL){
			CFRelease(machPort);
		}
		if (eventSrc != NULL){
			CFRelease(eventSrc);
		}
	
	}
}
-(void)addObserver:(id<FCMouseTrackingObserver>)observer{
	@synchronized(self){
		FCLog(@"%s - adding an observer %@", __FCFUNCTION__, observer);
		[_observers addObject:observer];
	}
}
-(id)init{
	if ((self = [super init]) != nil){
		_observers = [[NSMutableArray alloc] initWithCapacity:1];
		[NSThread detachNewThreadSelector:@selector(_trackingThread) toTarget:self withObject:nil];
	}
	return self;
}
-(void)removeObserver:(id<FCMouseTrackingObserver>)observer{
	@synchronized(self){
		[_observers removeObject:observer];
	}
}

@end

