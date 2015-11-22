//
//  UIAlertViewAdditions.h
//  Pexeso
//
//  Created by Charlie Monroe on 4/23/13.
//  Copyright (c) 2013 Charlie Monroe Software. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *
 *	NOTE: This entire file is deprecated and will be removed soon.
 *
 */


typedef enum {
	UIAlertViewReturnDefault,
	UIAlertViewReturnAlternate,
	UIAlertViewReturnOther
} UIAlertViewReturnType;

typedef void(^XUAlertViewHandler)(UIAlertView *alertView, NSInteger clickedButton);

@interface UIAlertView (ModalAdditions)

+(UIAlertView*)alertWithMessageText:(NSString*)message defaultButton:(NSString*)defaultButton alternateButton:(NSString*)alternate otherButton:(NSString*)other informativeText:(NSString*)info DEPRECATED_ATTRIBUTE;

-(UIAlertViewReturnType)runModal DEPRECATED_ATTRIBUTE;

@end

@interface UIAlertView (BlocksAdditions)

+(instancetype)alertWithTitle:(NSString *)title message:(NSString *)message handler:(XUAlertViewHandler)handler cancelButtonTitle:(NSString *)cancelButtonTitle DEPRECATED_MSG_ATTRIBUTE("Use UIAlertController.");
+(instancetype)alertWithTitle:(NSString *)title message:(NSString *)message handler:(XUAlertViewHandler)handler cancelButtonTitle:(NSString *)cancelButtonTitle andSecondButtonTitle:(NSString*)secondButtonTitle DEPRECATED_MSG_ATTRIBUTE("Use UIAlertController.");
+(instancetype)alertWithTitle:(NSString *)title message:(NSString *)message handler:(XUAlertViewHandler)handler cancelButtonTitle:(NSString *)cancelButtonTitle secondButtonTitle:(NSString*)secondButtonTitle andThirdButtonTitle:(NSString*)thirdButtonTitle DEPRECATED_MSG_ATTRIBUTE("Use UIAlertController.");

@end


@interface UIAlertView (NonMainThreadModality)

/** Calls -show on main thread and waits for the alert to be dismissed. Must be 
 * called from non-main thread.
 */
-(UIAlertViewReturnType)runModalOnMainThread DEPRECATED_MSG_ATTRIBUTE("Use UIAlertController.");

@end

@interface UIAlertView (OSXCompatibility)
@property (readwrite, retain, nonatomic) NSString *informativeText DEPRECATED_MSG_ATTRIBUTE("Use UIAlertController.");
@property (readwrite, retain, nonatomic) NSString *messageText DEPRECATED_MSG_ATTRIBUTE("Use UIAlertController.");
@end


@interface UIAlertView (XUAlertViewErrorAdditions)

/** Presents an alert view with error description. */
+(instancetype)alertViewWithError:(NSError*)error DEPRECATED_MSG_ATTRIBUTE("Use UIAlertController.");;

@end
