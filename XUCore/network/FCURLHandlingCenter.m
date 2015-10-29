// 
// FCURLHandlingCenter.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCURLHandlingCenter.h"

static FCURLHandlingCenter *_defaultCenter;

@implementation FCURLHandlingCenter

+(FCURLHandlingCenter*)defaultCenter{
	static dispatch_once_t once;
	dispatch_once(&once, ^ { 
		_defaultCenter = [[FCURLHandlingCenter alloc] init]; 
        });
	return _defaultCenter;
}

-(void)addHandler:(id <FCURLHandler>)handler forURLScheme:(NSString*)scheme{
	scheme = [scheme lowercaseString];
	NSMutableArray *handlers = [_handlers objectForKey:scheme];
	if (handlers == nil){
		handlers = [NSMutableArray arrayWithCapacity:1];
		[_handlers setObject:handlers forKey:scheme];
	}
	
	[handlers addObject:handler];
}
-(void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent{
	NSString *receivedURLString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	NSURL *url = [NSURL URLWithString:receivedURLString];
	for (id<FCURLHandler> handler in [_handlers objectForKey:[[url scheme] lowercaseString]]){
		[handler handlerShouldProcessURL:url];
	}
}
-(instancetype)init{
	if (_defaultCenter != nil){
		self = _defaultCenter;
		return self;
	}
	if ((self = [super init]) != nil){
		_handlers = [[NSMutableDictionary alloc] init];
		[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	}
	return self;
}
-(void)removeHandler:(id <FCURLHandler>)handler{
	for (NSString *scheme in _handlers){
		[self removeHandler:handler forURLScheme:scheme];
	}
}
-(void)removeHandler:(id <FCURLHandler>)handler forURLScheme:(NSString*)scheme{
	NSMutableArray *handlers = [_handlers objectForKey:scheme];
	[handlers removeObject:handler];
}

@end

