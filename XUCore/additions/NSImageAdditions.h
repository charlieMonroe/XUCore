// 
// NSImageAdditions.h
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 

@import Foundation;
#if TARGET_OS_IPHONE
	#import <UIKit/UIKit.h>
	#define NSImage UIImage
	#define NSSize CGSize
	#define NSRect CGRect
	#define NSTIFFCompression NSUInteger
#else
	#import <Cocoa/Cocoa.h>
#endif



@interface NSImage (FCAdditions) 

#if !TARGET_OS_IPHONE
+(nullable instancetype)thumbnailOfFileAtURL:(nonnull NSURL *)url withSize:(CGSize)size;

-(nonnull instancetype)blackAndWhiteImage;

-(void)drawAtPoint:(CGPoint)point fromRect:(CGRect)fromRect operation:(NSCompositingOperation)op fraction:(CGFloat)delta respectFlipped:(BOOL)respectFlipped;
#endif

-(void)drawCenteredInRect:(NSRect)rect; //Uses 1.0 alpha, NSCompositeSourceOver
-(void)drawCenteredInRect:(NSRect)rect fraction:(double)fraction;

-(NSSize)proportinallyScaledSizeForMaxSize:(NSSize)size;

#if !TARGET_OS_IPHONE
-(nullable NSData *)JPEGRepresentation;
-(nullable NSData *)PNGRepresentation;
-(nullable NSData *)JPEG2000Representation;
-(nullable NSData *)GIFRepresentation;
-(nullable NSData *)BMPRepresentation;
-(nullable NSData *)TIFFRepresentationUsingCompression:(NSTIFFCompression)compression;
-(nullable NSData *)JPEGRepresentationUsingCompressionFactor:(int)compressionFactor progressive:(BOOL)progressive;
-(nullable NSData *)GIFRepresentationWithDitheredTransparency:(BOOL)dither;
-(nullable NSData *)PNGRepresentationInterlaced:(BOOL)interlace;

-(nonnull instancetype)initWithCGImage:(nonnull CGImageRef)cgImage asBitmapImageRep:(BOOL)asBitmapImageRep;

-(void)tileInRect:(NSRect)rect;
-(nonnull instancetype)imageWithSingleImageRepOfSize:(CGSize)size;

#else

-(nonnull instancetype)imageResizedToSize:(CGSize)targetSize;
-(nullable NSData *)PNGRepresentation;

#endif

@end

