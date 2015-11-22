
#import <UIKit/UIKit.h>

NSUInteger CMSystemMajorVersion(void);

static inline BOOL CMRunningPhoneDevice(void){
	return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;
}

DEPRECATED_MSG_ATTRIBUTE("We no longer support iOS 6.") static inline BOOL CMRunningOS7(void){
	return CMSystemMajorVersion() >= 7;
}


