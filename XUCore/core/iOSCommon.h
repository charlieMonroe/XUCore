
#import <UIKit/UIKit.h>

NS_AVAILABLE(10_10, 8_0)
static inline NSUInteger XUSystemMajorVersion(void) {
	return [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion;
}

static inline BOOL XURunningPhoneDevice(void){
	return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;
}

DEPRECATED_MSG_ATTRIBUTE("We no longer support iOS 6.") static inline BOOL CMRunningOS7(void){
	return XUSystemMajorVersion() >= 7;
}


