// 
// NSBezierPathAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSBezierPathAdditions.h"

extern CGPathRef CGContextCopyPath(CGContextRef context);

static void CGPathCallback(void *info, const CGPathElement *element)
{
	NSBezierPath *path = (__bridge NSBezierPath *)(info);
	CGPoint *points = element->points;
	
	switch (element->type) {
		case kCGPathElementMoveToPoint:
		{
			[path moveToPoint:NSMakePoint(points[0].x, points[0].y)];
			break;
		}
		case kCGPathElementAddLineToPoint:
		{
			[path lineToPoint:NSMakePoint(points[0].x, points[0].y)];
			break;
		}
		case kCGPathElementAddQuadCurveToPoint:
		{
			// NOTE: This is untested.
			NSPoint currentPoint = [path currentPoint];
			NSPoint interpolatedPoint = NSMakePoint((currentPoint.x + 2*points[0].x) / 3, (currentPoint.y + 2*points[0].y) / 3);
			[path curveToPoint:NSMakePoint(points[1].x, points[1].y) controlPoint1:interpolatedPoint controlPoint2:interpolatedPoint];
			break;
		}
		case kCGPathElementAddCurveToPoint:
		{
			[path curveToPoint:NSMakePoint(points[2].x, points[2].y) controlPoint1:NSMakePoint(points[0].x, points[0].y) controlPoint2:NSMakePoint(points[1].x, points[1].y)];
			break;
		}
		case kCGPathElementCloseSubpath:
		{
			[path closePath];
			break;
		}
	}
}


@implementation NSBezierPath (NSBezierPathAdditions)

+ (NSBezierPath *)bezierPathWithCGPath:(CGPathRef)pathRef
{
	NSBezierPath *path = [NSBezierPath bezierPath];
	CGPathApply(pathRef, (__bridge void *)(path), CGPathCallback);
	
	return path;
}

+(NSBezierPath*)bezierPathWithTriangleInRect:(NSRect)rect direction:(XUDirection)direction{
	NSBezierPath *bezierPath = [NSBezierPath bezierPath];
	if (direction == FCTop){
		[bezierPath moveToPoint:NSMakePoint(rect.origin.x, rect.origin.y)];
		[bezierPath lineToPoint:NSMakePoint(NSMaxX(rect), rect.origin.y)];
		[bezierPath lineToPoint:NSMakePoint(rect.origin.x + (NSMaxX(rect) - rect.origin.x)/2.0, NSMaxY(rect))];
		[bezierPath closePath];
	}else if (direction == FCBottom){
		[bezierPath moveToPoint:NSMakePoint(rect.origin.x, NSMaxY(rect))];
		[bezierPath lineToPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
		[bezierPath lineToPoint:NSMakePoint(rect.origin.x + (NSMaxX(rect) - rect.origin.x)/2.0, NSMinY(rect))];
		[bezierPath closePath];
	}else if (direction == FCRight){
		[bezierPath moveToPoint:NSMakePoint(rect.origin.x, NSMaxY(rect))];
		[bezierPath lineToPoint:NSMakePoint(NSMinX(rect), NSMinY(rect))];
		[bezierPath lineToPoint:NSMakePoint(NSMaxX(rect), rect.origin.y + (NSMaxY(rect) - rect.origin.y)/2.0)];
		[bezierPath closePath];
	}else{
		[bezierPath moveToPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
		[bezierPath lineToPoint:NSMakePoint(NSMaxX(rect), NSMinY(rect))];
		[bezierPath lineToPoint:NSMakePoint(NSMinX(rect), rect.origin.y + (NSMaxY(rect) - rect.origin.y)/2.0)];
		[bezierPath closePath];
	}
	
	
	return bezierPath;
}


// Method borrowed from Google's Cocoa additions
- (CGPathRef)cgPath
{
	CGMutablePathRef thePath = CGPathCreateMutable();
	if (!thePath) return nil;
	
	NSInteger elementCount = [self elementCount];
	
	// The maximum number of points is 3 for a NSCurveToBezierPathElement.
	// (controlPoint1, controlPoint2, and endPoint)
	NSPoint controlPoints[3];
	
	for (unsigned int i = 0; i < elementCount; i++) {
		switch ([self elementAtIndex:i associatedPoints:controlPoints]) {
			case NSMoveToBezierPathElement:
				CGPathMoveToPoint(thePath, &CGAffineTransformIdentity, 
							controlPoints[0].x, controlPoints[0].y);
				break;
			case NSLineToBezierPathElement:
				CGPathAddLineToPoint(thePath, &CGAffineTransformIdentity, 
							   controlPoints[0].x, controlPoints[0].y);
				break;
			case NSCurveToBezierPathElement:
				CGPathAddCurveToPoint(thePath, &CGAffineTransformIdentity, 
							    controlPoints[0].x, controlPoints[0].y,
							    controlPoints[1].x, controlPoints[1].y,
							    controlPoints[2].x, controlPoints[2].y);
				break;
			case NSClosePathBezierPathElement:
				CGPathCloseSubpath(thePath);
				break;
			default:
				NSLog(@"Unknown element at [NSBezierPath (GTMBezierPathCGPathAdditions) cgPath]");
				break;
		};
	}
	return thePath;
}

- (NSBezierPath *)pathWithStrokeWidth:(CGFloat)strokeWidth
{
#ifdef MCBEZIER_USE_PRIVATE_FUNCTION
	NSBezierPath *path = [self copy];
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	CGPathRef pathRef = [path cgPath];
	XU_RELEASE(path);
	
	CGContextSaveGState(context);
	
	CGContextBeginPath(context);
	CGContextAddPath(context, pathRef);
	CGContextSetLineWidth(context, strokeWidth);
	CGContextReplacePathWithStrokedPath(context);
	CGPathRef strokedPathRef = CGContextCopyPath(context);
	CGContextBeginPath(context);
	NSBezierPath *strokedPath = [NSBezierPath bezierPathWithCGPath:strokedPathRef];
	
	CGContextRestoreGState(context);
	
	CFRelease(pathRef);
	CFRelease(strokedPathRef);
	
	return strokedPath;
#else
	return nil;
#endif//MCBEZIER_USE_PRIVATE_FUNCTION
}

- (void)fillWithInnerShadow:(NSShadow *)shadow
{
	[NSGraphicsContext saveGraphicsState];
	
	NSSize offset = shadow.shadowOffset;
	NSSize originalOffset = offset;
	CGFloat radius = shadow.shadowBlurRadius;
	NSRect bounds = NSInsetRect(self.bounds, -(ABS(offset.width) + radius), -(ABS(offset.height) + radius));
	offset.height += bounds.size.height;
	shadow.shadowOffset = offset;
	NSAffineTransform *transform = [NSAffineTransform transform];
	if ([[NSGraphicsContext currentContext] isFlipped])
		[transform translateXBy:0 yBy:bounds.size.height];
	else
		[transform translateXBy:0 yBy:-bounds.size.height];
	
	NSBezierPath *drawingPath = [NSBezierPath bezierPathWithRect:bounds];
	[drawingPath setWindingRule:NSEvenOddWindingRule];
	[drawingPath appendBezierPath:self];
	[drawingPath transformUsingAffineTransform:transform];
	
	[self addClip];
	[shadow set];
	[[NSColor blackColor] set];
	[drawingPath fill];
	
	shadow.shadowOffset = originalOffset;
	
	[NSGraphicsContext restoreGraphicsState];
}

- (void)drawBlurWithColor:(NSColor *)color radius:(CGFloat)radius
{
	NSRect bounds = NSInsetRect(self.bounds, -radius, -radius);
	NSShadow *shadow = [[NSShadow alloc] init];
	shadow.shadowOffset = NSMakeSize(0, bounds.size.height);
	shadow.shadowBlurRadius = radius;
	shadow.shadowColor = color;
	NSBezierPath *path = [self copy];
	NSAffineTransform *transform = [NSAffineTransform transform];
	if ([[NSGraphicsContext currentContext] isFlipped])
		[transform translateXBy:0 yBy:bounds.size.height];
	else
		[transform translateXBy:0 yBy:-bounds.size.height];
	[path transformUsingAffineTransform:transform];
	
	[NSGraphicsContext saveGraphicsState];
	
	[shadow set];
	[[NSColor blackColor] set];
	NSRectClip(bounds);
	[path fill];
	
	[NSGraphicsContext restoreGraphicsState];
}

// Credit for the next two methods goes to Matt Gemmell
- (void)strokeInside
{
	/* Stroke within path using no additional clipping rectangle. */
	[self strokeInsideWithinRect:NSZeroRect];
}

- (void)strokeInsideWithinRect:(NSRect)clipRect
{
	NSGraphicsContext *thisContext = [NSGraphicsContext currentContext];
	float lineWidth = [self lineWidth];
	
	/* Save the current graphics context. */
	[thisContext saveGraphicsState];
	
	/* Double the stroke width, since -stroke centers strokes on paths. */
	[self setLineWidth:(lineWidth * 2.0)];
	
	/* Clip drawing to this path; draw nothing outwith the path. */
	[self setClip];
	
	/* Further clip drawing to clipRect, usually the view's frame. */
	if (clipRect.size.width > 0.0 && clipRect.size.height > 0.0) {
		[NSBezierPath clipRect:clipRect];
	}
	
	/* Stroke the path. */
	[self stroke];
	
	/* Restore the previous graphics context. */
	[thisContext restoreGraphicsState];
	[self setLineWidth:lineWidth];
}

+(NSBezierPath*)bezierPathWithRoundRectAndTriangleInRect:(NSRect)inRect triangleCenteredToRect:(NSRect)centerRect windowFrame:(NSRect)windowFrame cornerRadius:(float)radius{
	float triangleTopX = centerRect.origin.x - windowFrame.origin.x + centerRect.size.width/2.0;
	
	float inRadiusX = radius;
	float inRadiusY = radius;
	const float kEllipseFactor = 0.55228474983079;
	
	float theMaxRadiusX = NSWidth(inRect) / 2.0;
	float theMaxRadiusY = NSHeight(inRect) / 2.0;
	float theRadiusX = (inRadiusX < theMaxRadiusX) ? inRadiusX : theMaxRadiusX;
	float theRadiusY = (inRadiusY < theMaxRadiusY) ? inRadiusY :	theMaxRadiusY;
	float theControlX = theRadiusX * kEllipseFactor;
	float theControlY = theRadiusY * kEllipseFactor;
	
	NSRect theEdges = NSInsetRect(inRect, theRadiusX, theRadiusY);
	NSBezierPath* theResult = [NSBezierPath bezierPath];
	
	//	Lower edge and lower-right corner
	[theResult moveToPoint:NSMakePoint(theEdges.origin.x, inRect.origin.y)];
	[theResult lineToPoint:NSMakePoint(NSMaxX(theEdges), inRect.origin.y)];
	[theResult curveToPoint:NSMakePoint(NSMaxX(inRect), theEdges.origin.y) controlPoint1:NSMakePoint(NSMaxX(theEdges) + theControlX, inRect.origin.y) controlPoint2:NSMakePoint(NSMaxX(inRect), theEdges.origin.y - theControlY)];
	
	//	Right edge and upper-right corner
	[theResult lineToPoint:NSMakePoint(NSMaxX(inRect), NSMaxY(theEdges))];
	[theResult curveToPoint:NSMakePoint(NSMaxX(theEdges), NSMaxY(inRect)) controlPoint1:NSMakePoint(NSMaxX(inRect), NSMaxY(theEdges) + theControlY) controlPoint2:NSMakePoint(NSMaxX(theEdges) + theControlX, NSMaxY(inRect))];
	//triangle:
	//Right edge
	[theResult lineToPoint:NSMakePoint(triangleTopX + 14.0 - inRect.origin.x/2.0, inRect.origin.y + inRect.size.height)];
	//Center
	[theResult lineToPoint:NSMakePoint(triangleTopX, inRect.origin.y/2.0 + inRect.size.height + 14.0)];
	//Left edge
	[theResult lineToPoint:NSMakePoint(triangleTopX - 14.0 + inRect.origin.x/2.0, inRect.origin.y + inRect.size.height)];
	
	
	//	Top edge and upper-left corner
	[theResult lineToPoint:NSMakePoint(theEdges.origin.x, NSMaxY(inRect))];
	[theResult curveToPoint:NSMakePoint(inRect.origin.x, NSMaxY(theEdges)) controlPoint1:NSMakePoint(theEdges.origin.x - theControlX, NSMaxY(inRect)) controlPoint2:NSMakePoint(inRect.origin.x, NSMaxY(theEdges) + theControlY)];
	
	//	Left edge and lower-left corner
	[theResult lineToPoint:NSMakePoint(inRect.origin.x, theEdges.origin.y)];
	[theResult curveToPoint:NSMakePoint(theEdges.origin.x, inRect.origin.y) controlPoint1:NSMakePoint(inRect.origin.x, theEdges.origin.y - theControlY) controlPoint2:NSMakePoint(theEdges.origin.x - theControlX, inRect.origin.y)];
	
	
	//	Finish up and return
	[theResult closePath];
	return theResult;
}

@end

