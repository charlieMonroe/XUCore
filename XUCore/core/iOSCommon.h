
#import <UIKit/UIKit.h>

NSUInteger CMSystemMajorVersion(void);

static inline BOOL CMRunningPhoneDevice(void){
	return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;
}
static inline BOOL CMRunningOS7(void){
	return CMSystemMajorVersion() >= 7;
}


