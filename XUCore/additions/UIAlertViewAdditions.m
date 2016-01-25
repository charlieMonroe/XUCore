//
//  UIAlertViewAdditions.m
//  Pexeso
//
//  Created by Charlie Monroe on 4/23/13.
//  Copyright (c) 2013 Charlie Monroe Software. All rights reserved.
//

#import "UIAlertViewAdditions.h"

#import "FCLocalizationSupport.h"

@interface UIAlertView (BlockInternals)
+(NSMutableArray*)_blockDelegates;
@end

static UIAlertViewReturnType __returnType;

static NSMutableArray *____alerts;

static inline NSMutableArray *_XUActiveAlertsArray(void){
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		____alerts = [[NSMutableArray alloc] initWithCapacity:1];
	});
	return ____alerts;
}


@interface XUAlertViewDelegate : NSObject <UIAlertViewDelegate>

@property (readwrite, copy) XUAlertViewHandler handler;
@property (readwrite, copy) void(^completionHandler)(void);

@end

@implementation XUAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	[self handler](alertView, buttonIndex);
	
	[_XUActiveAlertsArray() removeObject:alertView];
	[[UIAlertView _blockDelegates] removeObject:self]; // -> releases the delegate
}
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
	if ([self completionHandler] != nil){
		[self completionHandler]();
	}
	
	[_XUActiveAlertsArray() removeObject:alertView];
}

@end


@implementation UIAlertView (NonMainThreadModality)

-(UIAlertViewReturnType)runModalOnMainThread{
	if ([[NSThread currentThread] isMainThread]){
		@throw [NSException exceptionWithName:NSGenericException reason:@"-runModalOnMainThread may only be called from non-main thread!" userInfo:nil];
	}

	id oldDelegate = [self delegate];
	
	NSLock *__modalLock = [[NSLock alloc] init];
	[__modalLock setName:@"com.charliemonroe.Downie.UIAlertView.ModalLock"];
	
	__block NSInteger clickedButton = 0;
	
	XUAlertViewDelegate *delegate = [[XUAlertViewDelegate alloc] init];
	[delegate setHandler:^(UIAlertView *alertView, NSInteger buttonIndex){
		clickedButton = buttonIndex;
		[oldDelegate alertView:alertView clickedButtonAtIndex:buttonIndex];
	}];
	[delegate setCompletionHandler:^{
		[__modalLock unlock];
	}];
	[self setDelegate:delegate];
	
	dispatch_sync(dispatch_get_main_queue(), ^{
		[__modalLock lock];
		
		[self show];
	});
	
	[__modalLock lock];
	[__modalLock unlock];
	
	switch (clickedButton) {
		case 0:
			__returnType = UIAlertViewReturnDefault;
			break;
		case 1:
			__returnType = UIAlertViewReturnAlternate;
			break;
		default:
			__returnType = UIAlertViewReturnOther;
			break;
	}
	return __returnType;
}

@end

@implementation UIAlertView (ModalAdditions)

+(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	switch (buttonIndex) {
		case 0:
			__returnType = UIAlertViewReturnDefault;
			break;
		case 1:
			__returnType = UIAlertViewReturnAlternate;
			break;
		default:
			__returnType = UIAlertViewReturnOther;
			break;
	}
	[alertView removeFromSuperview];
}
+ (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex{
	
}
+ (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
	
}

+(UIAlertView *)alertWithMessageText:(NSString *)message defaultButton:(NSString *)defaultButton alternateButton:(NSString *)alternate otherButton:(NSString *)other informativeText:(NSString *)info{
	if ([alternate isEqualToString:@""]){
		alternate = nil;
	}
	if ([other isEqualToString:@""]){
		other = nil;
	}
	
	UIAlertView *alertView = [[self alloc] initWithTitle:message message:info delegate:(id)self cancelButtonTitle:defaultButton otherButtonTitles:alternate, other, nil];
	return alertView;
}

-(UIAlertViewReturnType)runModal{
	[self show];
	
	while ([self isVisible]){
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	}
	
	return __returnType;
}

@end

@implementation UIAlertView (BlocksAdditions)

+(NSMutableArray*)_blockDelegates{
	static NSMutableArray *_blockDelegates;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_blockDelegates = [[NSMutableArray alloc] initWithCapacity:1];
	});
	return _blockDelegates;
}


+(instancetype)alertWithTitle:(NSString *)title message:(NSString *)message handler:(XUAlertViewHandler)handler cancelButtonTitle:(NSString *)cancelButtonTitle{
	return [self alertWithTitle:title message:message handler:handler cancelButtonTitle:cancelButtonTitle secondButtonTitle:nil andThirdButtonTitle:nil];
}
+(instancetype)alertWithTitle:(NSString *)title message:(NSString *)message handler:(XUAlertViewHandler)handler cancelButtonTitle:(NSString *)cancelButtonTitle andSecondButtonTitle:(NSString *)secondButtonTitle{
	return [self alertWithTitle:title message:message handler:handler cancelButtonTitle:cancelButtonTitle secondButtonTitle:secondButtonTitle andThirdButtonTitle:nil];
}
+(instancetype)alertWithTitle:(NSString *)title message:(NSString *)message handler:(XUAlertViewHandler)handler cancelButtonTitle:(NSString *)cancelButtonTitle secondButtonTitle:(NSString *)secondButtonTitle andThirdButtonTitle:(NSString *)thirdButtonTitle{
	XUAlertViewDelegate *delegate = nil;
	if (handler != nil){
		delegate = [[XUAlertViewDelegate alloc] init];
		[delegate setHandler:handler];
		[[self _blockDelegates] addObject:delegate];
	}
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:delegate cancelButtonTitle:cancelButtonTitle otherButtonTitles:secondButtonTitle, thirdButtonTitle, nil];
	[_XUActiveAlertsArray() addObject:alertView];
	return alertView;
}

@end


@implementation UIAlertView (OSXCompatibility)
-(NSString *)informativeText{
	return [self message];
}
-(void)setInformativeText:(NSString *)informativeText{
	[self setMessage:informativeText];
}

-(NSString *)messageText{
	return [self title];
}
-(void)setMessageText:(NSString *)messageText{
	[self setTitle:messageText];
}
@end

@implementation UIAlertView (XUAlertViewErrorAdditions)

+(instancetype)alertViewWithError:(NSError *)error{
	return [[self alloc] initWithTitle:[error localizedFailureReason] message:[error localizedDescription] delegate:nil cancelButtonTitle:XULocalizedString(@"OK") otherButtonTitles:nil];
}

@end
