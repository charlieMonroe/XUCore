// 
// FCAppScopeBookmarksManager.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "FCAppScopeBookmarksManager.h"

#import "FCLog.h"

@implementation FCAppScopeBookmarksManager

+(FCAppScopeBookmarksManager*)sharedManager{
	static dispatch_once_t once;
	static FCAppScopeBookmarksManager *_bookmarksManager;
	dispatch_once(&once, ^ {
		_bookmarksManager = [[FCAppScopeBookmarksManager alloc] init];
        });
	return _bookmarksManager;
}

-(id)init{
	if ((self = [super init]) != nil){
		_cache = [[NSMutableDictionary alloc] initWithCapacity:1]; // Typically 1 or 2 such URLs per app
	}
	return self;
}
-(void)setURL:(NSURL *)url forKey:(NSString *)defaultsKey{
	@synchronized(self){
		if (url == nil){
			[_cache removeObjectForKey:defaultsKey];
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:defaultsKey];
		}else{
			// Make sure the path is different from the current one -> otherwise we probably haven't opened the open dialog -> will fail
			if (![[self URLForKey:defaultsKey] isEqual:url]){
				#if TARGET_OS_IPHONE
					[[NSUserDefaults standardUserDefaults] setObject:[url absoluteString] forKey:defaultsKey];
				#else
					[url startAccessingSecurityScopedResource];
					
					NSError *err = nil;
					NSData *bookmarkData = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:[NSArray array] relativeToURL:nil error:&err];
					FCLog(@"%s -  trying to save bookmark data for path %@ - bookmark data length = %li, error: %@", __FCFUNCTION__, [url path], [bookmarkData length], err);
					
					[[NSUserDefaults standardUserDefaults] setObject:bookmarkData forKey:defaultsKey];
					
					[url stopAccessingSecurityScopedResource];
				
					NSURL *reloadedURL = [NSURL URLByResolvingBookmarkData:bookmarkData options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:NULL error:NULL];
					if (reloadedURL != nil){
						url = reloadedURL;
					}
				#endif
				
				[_cache setObject:url forKey:defaultsKey];
				[[NSUserDefaults standardUserDefaults] synchronize];
			}
		}
	}
}
-(NSURL *)URLForKey:(NSString *)defaultsKey{
	@synchronized(self){
		NSURL *result = nil;
		if ((result = [_cache objectForKey:defaultsKey]) != nil){
			return result;
		}
		
		#if TARGET_OS_IPHONE
			NSString *absoluteURLString = [[NSUserDefaults standardUserDefaults] objectForKey:defaultsKey];
			if (absoluteURLString == nil){
				return nil;
			}
			result = [NSURL URLWithString:absoluteURLString];
		#else
			NSData *bookmarkData = [[NSUserDefaults standardUserDefaults] objectForKey:defaultsKey];
			BOOL stale = NO;
			NSError *err = nil;
			if ([bookmarkData length] > 0){
				result = [NSURL URLByResolvingBookmarkData:bookmarkData options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&stale error:&err];
				FCLog(@"%s - resolved bookmark data (length: %li) to %@ with error: %@ (is stale: %@)", __FCFUNCTION__, [bookmarkData length], result, err, stale ? @"YES" : @"NO");
			}
		#endif
		
		if (result != nil){
			[_cache setObject:result forKey:defaultsKey];
		}
		
		return result;
	}
}

@end

