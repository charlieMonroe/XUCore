// 
// NSBezierPathAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-16 Charlie Monroe Software. All rights reserved.
// 


#import <Cocoa/Cocoa.h>

DEPRECATED_ATTRIBUTE typedef NS_ENUM(NSInteger, FCDirection) {
	FCLeft,
	FCRight,
	FCBottom,
	FCTop
};

typedef NS_ENUM(NSInteger, XUDirection) {
	XUDirectionLeftToRight,
	XUDirectionRightToLeft,
	XUDirectionBottomToTop,
	XUDirectionTopToBottom
};


@interface NSBezierPath (NSBezierPathAdditions)

+(nonnull instancetype)bezierPathWithRoundRectAndTriangleInRect:(NSRect)inRect triangleCenteredToRect:(NSRect)centerRect windowFrame:(NSRect)windowFrame cornerRadius:(float)radius DEPRECATED_ATTRIBUTE;

+(nonnull instancetype)bezierPathWithTriangleInRect:(NSRect)rect direction:(XUDirection)direction;

+(nonnull instancetype)bezierPathWithCGPath:(nonnull CGPathRef)pathRef DEPRECATED_ATTRIBUTE;
-(nonnull CGPathRef)cgPath __attribute__((cf_returns_retained)) DEPRECATED_ATTRIBUTE;

-(nonnull instancetype)pathWithStrokeWidth:(CGFloat)strokeWidth DEPRECATED_ATTRIBUTE;

-(void)fillWithInnerShadow:(nonnull NSShadow *)shadow;
-(void)drawBlurWithColor:(nonnull NSColor *)color radius:(CGFloat)radius DEPRECATED_ATTRIBUTE;

-(void)strokeInside;
-(void)strokeInsideWithinRect:(NSRect)clipRect;

@end

DEPRECATED_ATTRIBUTE
NS_INLINE NSRect FCCenteredRectInRect(NSRect frame, NSRect insideRect){
	return NSMakeRect(NSMinX(frame) + (NSWidth(frame) - NSWidth(insideRect)) / 2.0, NSMinY(frame) + (NSHeight(frame) - NSHeight(insideRect)) / 2.0, NSWidth(insideRect), NSHeight(insideRect));
}

DEPRECATED_ATTRIBUTE
NS_INLINE NSRect FCBottomHalfOfRect(NSRect rect){
	return NSMakeRect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height / 2.0);
}

DEPRECATED_ATTRIBUTE
NS_INLINE NSRect FCTopHalfOfRect(NSRect rect){
	return NSMakeRect(rect.origin.x, rect.origin.y + rect.size.height / 2.0, rect.size.width, rect.size.height / 2.0);
}

DEPRECATED_ATTRIBUTE
NS_INLINE NSPoint FCRectCenter(NSRect rect){
	return NSMakePoint(NSMinX(rect) + (NSWidth(rect) / 2.0), NSMinY(rect) + (NSHeight(rect) / 2.0));
}


