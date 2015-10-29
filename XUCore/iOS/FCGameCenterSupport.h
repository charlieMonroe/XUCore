// 
// FCGameCenterSupport.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@interface FCGameCenterSupport : NSObject
#if TARGET_OS_IPHONE
	<UIAlertViewDelegate>
#endif

+(FCGameCenterSupport*)sharedSupport;

-(BOOL)applicationUsesGameCenter;
-(void)authenticateLocalPlayer;
-(GKLocalPlayer*)localPlayer; // Returns nil if not authenticated yet
-(BOOL)gameCenterIsAvailable;
-(void)reportProgress:(double)percent forAchievement:(NSString*)identifier;
-(void)submitScore:(int64_t)score toLeaderBoard:(NSString*)leaderBoard;

@end

extern NSString *FCGameCenterEnabledDefaultsKey;


