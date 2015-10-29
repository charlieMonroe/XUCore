//
// FCGameCenterSupport.m
//
// Created by Charlie Monroe
//
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
//


#import "FCGameCenterSupport.h"

#if !TARGET_OS_IPHONE
#define UIViewController NSViewController<GKViewController>
#endif

NSString *FCGameCenterEnabledDefaultsKey = @"FCGameCenterEnabled";
static FCGameCenterSupport *_sharedSupport;

@implementation FCGameCenterSupport

+(FCGameCenterSupport*)sharedSupport{
	if (_sharedSupport == nil){
		_sharedSupport = [[self alloc] init];
	}
	return _sharedSupport;
}

#if TARGET_OS_IPHONE
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:(BOOL)buttonIndex] forKey:FCGameCenterEnabledDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[self authenticateLocalPlayer];
}
#endif

-(BOOL)applicationUsesGameCenter{
	if (![self gameCenterIsAvailable]){
		return NO;
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:FCGameCenterEnabledDefaultsKey]){
		return YES;
	}
	
	NSNumber *enabled = [[NSUserDefaults standardUserDefaults] objectForKey:FCGameCenterEnabledDefaultsKey];
	if (enabled != nil){
		return [enabled boolValue];
	}
	
	#if TARGET_OS_IPHONE
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Do you want to use Game Center?" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Use", nil];
		[alert show];
	#else
		NSAlert *alert = [NSAlert alertWithMessageText:@"Do you want to use Game Center?" defaultButton:@"Use Game Center" alternateButton:@"Cancel" otherButton:@"" informativeTextWithFormat:@""];
		NSInteger result = [alert runModal];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:(BOOL)(result == NSAlertDefaultReturn)] forKey:FCGameCenterEnabledDefaultsKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		[self authenticateLocalPlayer];
	#endif
	
	
	return NO;
}

#if TARGET_OS_IPHONE
	#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#else
	#define SYSTEM_VERSION_LESS_THAN(v) NO
#endif
-(void)authenticateLocalPlayer{
	// Force-loads the local player
	GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
	
        if (SYSTEM_VERSION_LESS_THAN(@"6.0")){
		// ios 5.x and below
		[localPlayer authenticateWithCompletionHandler:^(NSError *error){
			// Nothing really
		}];
        }else{
		// ios 6.0 and above
		[localPlayer setAuthenticateHandler:(^(UIViewController* viewcontroller, NSError *error) {
			if (!error && viewcontroller){
			#if TARGET_OS_IPHONE
				[[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:viewcontroller animated:YES completion:nil];
			#else
				[[GKDialogController sharedDialogController] presentViewController:viewcontroller];
			#endif
			}
		})];
        }
}


-(GKLocalPlayer*)localPlayer{
	return [GKLocalPlayer localPlayer];
}
-(BOOL)gameCenterIsAvailable{
	return YES; // We don't support that old devices anymore
}
-(void)reportProgress:(double)percent forAchievement:(NSString*)identifier{
	GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:identifier];
	if (achievement){
		[achievement setPercentComplete:percent];
		[achievement reportAchievementWithCompletionHandler:^(NSError *error){
			if (error != nil){
				// Oh well...
			}
		}];
	}
}
-(void)submitScore:(int64_t)score toLeaderBoard:(NSString*)leaderBoard{
	NSLog(@"Submitting %qu to %@", score, leaderBoard);
	
	GKScore *scoreReporter = [[GKScore alloc] initWithCategory:leaderBoard];
	[scoreReporter setValue:score];
	
	[scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {
		if (error != nil){
			NSLog(@"Error reporting score %@", error);
		}
	}];
}

@end



