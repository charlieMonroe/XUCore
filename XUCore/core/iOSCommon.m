
#import "iOSCommon.h"

NSUInteger CMSystemMajorVersion(void){
	static NSUInteger _cachedVersion = -1;
	if (_cachedVersion == -1) {
		static dispatch_once_t once_d;
		dispatch_once(&once_d, ^{
			_cachedVersion = [[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] objectAtIndex:0] intValue];
		});
	}
	return _cachedVersion;
}


