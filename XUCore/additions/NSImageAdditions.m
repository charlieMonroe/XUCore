// 
// NSImageAdditions.m
// 
// Created by Charlie Monroe
// 
// Copyright (c) 2010-13 Fuel Collective, LLC. All rights reserved.
// 


#import "NSImageAdditions.h"

#import "FCLog.h"

#if TARGET_OS_IPHONE
	#define NSZeroRect CGRectZero
	#define NSZeroSize CGSizeZero
#endif

#if !TARGET_OS_IPHONE
@interface NSImage (Private)
-(NSImage*)_imageWithSingleImageRepOfSize:(NSSize)size;
@end

@implementation NSImage (Private)

-(NSImage*)_imageWithSingleImageRepOfSize:(NSSize)size{
	if (NSEqualSizes(NSZeroSize, size)){
		return nil;
	}
	
	//size.width /= [[NSGraphicsContext currentContext] sca]
	
	NSImage *icon;
	NSSize s = [self size];
	
	if (s.width <= size.width && s.height <= size.height){
		return self;
	}
	
	CGFloat scale = [[[[NSApp windows] firstObject] screen] backingScaleFactor];
	if (scale == 0.0){
		scale = 1.0;
	}
	size.width /= scale;
	size.height /= scale;
	
	icon = [[NSImage alloc] initWithSize:size];
	[icon lockFocus];
	
	float height = (s.height>s.width)?size.height:(size.width/s.width)*s.height;
	float width = (s.width>=s.height)?size.width:(size.height/s.height)*s.width;
	
	[self drawInRect:NSMakeRect((size.width - width)/2, (size.height - height)/2, width, height) fromRect:NSMakeRect(0, 0, s.width, s.height) operation:NSCompositeCopy fraction:1.0];
	
	[icon unlockFocus];
	
	if ([[icon representations] count] > 1 || [[icon representations] count] == 0){
		FCLog(@"image scaled with more than one rep or with none: %li", [[icon representations] count]);
	}
	
	NSBitmapImageRep *imageRep = (NSBitmapImageRep *)[[icon representations] firstObject];
	[imageRep setPixelsWide:size.width];
	[imageRep setPixelsHigh:size.height];
	
	return icon;
}

@end
#endif

@implementation NSImage (FCAdditions)

#if !TARGET_OS_IPHONE
+(NSImage*)thumbnailOfFileAtURL:(NSURL*)url withSize:(NSSize)size{
	NSNumber *number = @(size.height);
	NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:(id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageIfAbsent, number, (id)kCGImageSourceThumbnailMaxPixelSize, nil];
	
	CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
	
	if (!source){
		return nil;
	}
	
	CGImageRef image = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)dic);
	
	
	if (!image){
		CFRelease(source);
		return nil;
	}
	
	NSImage *i = [[NSImage alloc] initWithCGImage:image asBitmapImageRep:YES];
	
	CFRelease(image);
	CFRelease(source);
	
	return i;
}

-(NSImage *)blackAndWhiteImage{
	NSImageRep *rep = [(NSBitmapImageRep *)[[self representations] lastObject] bitmapImageRepByConvertingToColorSpace:[NSColorSpace deviceGrayColorSpace] renderingIntent:NSColorRenderingIntentDefault];
	NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize([rep size].width, [rep size].height)];
	[image addRepresentation:rep];
	return image;
}

-(void)drawAtPoint:(CGPoint)point fromRect:(CGRect)fromRect operation:(NSCompositingOperation)op fraction:(CGFloat)delta respectFlipped:(BOOL)respectFlipped{
	NSRect rect = (NSRect){ point, [self size] };
	[self drawInRect:rect fromRect:fromRect operation:op fraction:delta respectFlipped:respectFlipped hints:nil];
}
#endif
-(void)drawCenteredInRect:(NSRect)rect{
	[self drawCenteredInRect:rect fraction:1.0];
}
-(void)drawCenteredInRect:(NSRect)rect fraction:(double)fraction{
	NSImage *image = self;
	NSSize mySize = [image size];
	
	NSRect targetRect = rect;
	
	if (mySize.width/mySize.height > rect.size.width / rect.size.height){
		// Wider
		targetRect.size.width = rect.size.width;
		targetRect.size.height = mySize.height * (rect.size.width / mySize.width);
		
		targetRect.origin.y = rect.origin.y + (rect.size.height - targetRect.size.height) / 2.0;
	}else{
		// Taller
		targetRect.size.height = rect.size.height;
		targetRect.size.width = mySize.width * (rect.size.height / mySize.height);
		
		targetRect.origin.x = rect.origin.x + (rect.size.width - targetRect.size.width) / 2.0;
	}
	
#if TARGET_OS_IPHONE
	[image drawInRect:targetRect blendMode:kCGBlendModeNormal alpha:fraction];
#else
	[image drawInRect:targetRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:fraction respectFlipped:YES hints:nil];
#endif
	
}

#if !TARGET_OS_IPHONE
-(void)_preview:(NSMutableDictionary*)sender{
	
	NSImage *i = [self _imageWithSingleImageRepOfSize:NSMakeSize([[sender objectForKey:@"width"] floatValue], [[sender objectForKey:@"height"] floatValue])];
	if (i==nil){
		return;
	}
	
	[sender setObject:i forKey:@"result"];
	
}
-(NSImage*) initWithCGImage:(CGImageRef)cgImage asBitmapImageRep:(BOOL)asBitmapImageRep {
	if (cgImage) {
		size_t width = CGImageGetWidth(cgImage);
		size_t height = CGImageGetHeight(cgImage);
		self = [self initWithSize:NSMakeSize(width, height)];
		if (asBitmapImageRep) {
			BOOL hasAlpha = CGImageGetAlphaInfo(cgImage) == kCGImageAlphaNone ? NO : YES;
			size_t bps = 8; // hardwiring to 8 bits per sample is fine for this app's purposes
			size_t spp = hasAlpha ? 4 : 3;
			NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:bps samplesPerPixel:spp hasAlpha:hasAlpha isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:0 bytesPerRow:0 bitsPerPixel:0];
			
			NSGraphicsContext *bitmapContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmapImageRep];
			[NSGraphicsContext saveGraphicsState];
			[NSGraphicsContext setCurrentContext:bitmapContext];
			CGContextDrawImage((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort], CGRectMake(0.0, 0.0, width, height), cgImage);
			[NSGraphicsContext restoreGraphicsState];
			
			[self addRepresentation:bitmapImageRep];
		} else {
			[self lockFocus];
			CGContextDrawImage((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort], CGRectMake(0.0, 0.0, width, height), cgImage);
			[self unlockFocus];
		}
	} else {
		self = [self init];
	}
	return self;
}

-(NSImage*)imageWithSingleImageRepOfSize:(NSSize)size{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	[dic setObject:@(size.width) forKey:@"width"];
	[dic setObject:@(size.height) forKey:@"height"];
	[self performSelectorOnMainThread:@selector(_preview:) withObject:dic waitUntilDone:YES];
	return [dic objectForKey:@"result"];
}
#endif

-(NSSize)proportinallyScaledSizeForMaxSize:(NSSize)size{
	NSImage *image = self;
	NSSize mySize = [image size];
	if (mySize.width < size.width && mySize.height < size.height){
		return mySize;
	}
	
	NSSize resultSize = NSZeroSize;
	
	if (mySize.width / mySize.height > size.width / size.height){
		//Wider
		resultSize.width = size.width;
		resultSize.height = mySize.height * (size.width / mySize.width);
	}else{
		//Taller
		resultSize.height = size.height;
		resultSize.width = mySize.width * (size.height / mySize.height);
	}
	return resultSize;
}

#if !TARGET_OS_IPHONE
- (NSData* )representationForFileType: (NSBitmapImageFileType) fileType {
	NSData *temp = [self TIFFRepresentation];
	NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:temp];
	NSData *imgData = [bitmap representationUsingType:fileType properties:@{ }];
	return imgData;
}

- (NSData *)JPEGRepresentation{
	return [self representationForFileType: NSJPEGFileType];
}

- (NSData *)PNGRepresentation{
	return [self representationForFileType: NSPNGFileType];
}

- (NSData *)JPEG2000Representation{
	return [self representationForFileType: NSJPEG2000FileType];  
}

- (NSData *)GIFRepresentation{
	return [self representationForFileType: NSGIFFileType];  
}

- (NSData *)BMPRepresentation{
	return [self representationForFileType: NSBMPFileType];    
}

- (NSData *)TIFFRepresentationUsingCompression:(NSTIFFCompression)compression{
	NSData *temp = [self TIFFRepresentation];
	NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:temp];
	NSData *imgData = [bitmap representationUsingType:NSTIFFFileType properties:[NSDictionary dictionaryWithObject:@(compression) forKey:NSImageCompressionMethod]];
	return imgData;
}

- (NSData *)JPEGRepresentationUsingCompressionFactor:(int)compressionFactor progressive:(BOOL)progressive{
	NSData *temp = [self TIFFRepresentation];
	NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:temp];
	NSData *imgData = [bitmap representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:compressionFactor],[NSNumber numberWithBool:progressive],nil] forKeys:[NSArray arrayWithObjects:NSImageCompressionFactor,NSImageProgressive,nil]]];
	return imgData;
}

- (NSData *)GIFRepresentationWithDitheredTransparency:(BOOL)dither{
	NSData *temp = [self TIFFRepresentation];
	NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:temp];
	NSData *imgData = [bitmap representationUsingType:NSGIFFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:dither] forKey:NSImageDitherTransparency]];
	return imgData;
}

- (NSData *)PNGRepresentationInterlaced:(BOOL)interlace{
	NSData *temp = [self TIFFRepresentation];
	NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:temp];
	NSData *imgData = [bitmap representationUsingType:NSPNGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:interlace] forKey:NSImageInterlaced]];
	return imgData;
	
}

- (void) tileInRect:(NSRect) rect {
	NSSize size = [self size];
	NSRect destRect = NSMakeRect( rect.origin.x, rect.origin.y, size.width, size.height );
	double top = rect.origin.y + rect.size.height;
	double right = rect.origin.x + rect.size.width;
	
	// Tile vertically
	while( destRect.origin.y < top ) {
		// Tile horizontally
		while( destRect.origin.x < right ) {
			NSRect sourceRect = NSMakeRect( 0, 0, size.width, size.height );
			
			// Crop as necessary
			if( ( destRect.origin.x + destRect.size.width ) > right )
				sourceRect.size.width -= ( destRect.origin.x + destRect.size.width ) - right;
			
			if( ( destRect.origin.y + destRect.size.height ) > top )
				sourceRect.size.height -= ( destRect.origin.y + destRect.size.height ) - top;
			
			// Draw and shift
			[self drawAtPoint:destRect.origin fromRect:sourceRect operation:NSCompositeSourceOver fraction:1.0];
			destRect.origin.x += destRect.size.width;
		}
		
		destRect.origin.y += destRect.size.height;
	}
	
}

#else

-(UIImage *)imageResizedToSize:(CGSize)targetSize{
	CGSize size = [self size];
	if (size.width <= targetSize.width && size.height <= targetSize.height){
		return self;
	}
	
	CGSize newSize = CGSizeZero;
	if (size.width > size.height){
		CGFloat width = targetSize.width;
		CGFloat height = size.height * (targetSize.width / size.width);
		if (height > targetSize.height){
			height = targetSize.height;
			width = size.width * (targetSize.height / size.height);
		}
		
		newSize.width = width;
		newSize.height = height;
	}else{
		CGFloat width = size.width * (targetSize.height / size.height);
		CGFloat height = targetSize.height;
		if (width > targetSize.width){
			width = targetSize.width;
			height = size.height * (targetSize.width / size.width);
		}
		
		newSize.width = width;
		newSize.height = height;
	}
	
	UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
	[self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}
-(NSData*)PNGRepresentation{
	return UIImagePNGRepresentation(self);
}

#endif

@end

