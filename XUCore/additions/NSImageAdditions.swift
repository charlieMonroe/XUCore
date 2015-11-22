//
//  NSImageAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/20/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

#if os(iOS)
	import UIKit
	
	public typealias XUImage = UIImage
#else
	import Cocoa
	
	public typealias XUImage = NSImage
#endif

/// Public extension of NSImage or UIImage. You can use XUImage in your code,
/// to make it universal.
public extension XUImage {
	
	#if !os(iOS)
	
	/// Returns an image with just a single image representation of size.
	private func _imageWithSingleImageRepOfSize(var size: CGSize) -> XUImage? {
		if CGSizeEqualToSize(CGSizeZero, size) {
			return nil
		}
		
		let s = self.size
		if s.width <= size.width && s.height <= size.height {
			return self
		}
		
		var scale = NSScreen.mainScreen()?.backingScaleFactor ?? 0.0
		if scale == 0.0 {
			scale = 1.0
		}
		
		size.width /= scale
		size.height /= scale
		
		let icon = NSImage(size: size)
		icon.lockFocus()
		
		let height = (s.height > s.width) ? size.height : (size.width / s.width) * s.height
		let width = (s.width >= s.height) ? size.width : (size.height / s.height) * s.width
		
		
		let fromRect = CGRectMake((size.width - width) / 2.0, (size.height - height) / 2.0, width, height)
		self.drawInRect(fromRect, fromRect: CGRectMake(0.0, 0.0, s.width, s.height), operation: .CompositeCopy, fraction: 1.0)
		
		icon.unlockFocus()
		
		if icon.representations.count > 1 || icon.representations.count == 0 {
			XULog("image scaled with more than one rep or with none: \(icon.representations.count)")
		}
		
		let imageRep = icon.representations.first!
		imageRep.pixelsWide = Int(size.width)
		imageRep.pixelsHigh = Int(size.height)
		
		return icon
	}
	
	/// Returns a black & white copy of the image. May return nil, if the image
	/// contains no bitmap image representations, or if the conversion fails.
	public var blackAndWhiteImage: XUImage? {
		guard let rep = self.representations.first as? NSBitmapImageRep else {
			return nil
		}
		
		guard let bwRep = rep.bitmapImageRepByConvertingToColorSpace(NSColorSpace.deviceGrayColorSpace(), renderingIntent: .Default) else {
			return nil
		}
		
		let image = NSImage(size: CGSizeMake(rep.size.width, rep.size.height))
		image.addRepresentation(bwRep)
		return image
	}
	
	/// Draws the image at point from rect. If respectFlipped is true, the current
	/// context's flip is respected.
	public func drawAtPoint(point: CGPoint, fromRect: CGRect, operation op: NSCompositingOperation, fraction delta: CGFloat, respectFlipped: Bool) {
		var rect: CGRect = CGRectZero
		rect.origin = point
		rect.size = self.size
		
		self.drawInRect(rect, fromRect: fromRect, operation: op, fraction: delta, respectFlipped: respectFlipped, hints: nil)
	}
	
	#endif
	
	/// Draws the rect centered within rect with fraction 1.0.
	public func drawCenteredInRect(rect: CGRect) {
		self.drawCenteredInRect(rect, fraction: 1.0)
	}
	
	/// Draws the rect centered within rect. The image is scaled, if necessary.
	public func drawCenteredInRect(rect: CGRect, fraction: CGFloat) {
		let image = self
		let mySize = image.size
		var targetRect = rect
		if mySize.width / mySize.height > rect.width / rect.height {
			// Wider
			targetRect.size.width = rect.width
			targetRect.size.height = mySize.height * (rect.width / mySize.width)
			targetRect.origin.y = rect.origin.y + (rect.height - targetRect.height) / 2.0
		} else {
			// Taller
			targetRect.size.height = rect.height
			targetRect.size.width = mySize.width * (rect.height / mySize.height)
			targetRect.origin.x = rect.origin.x + (rect.width - targetRect.width) / 2.0
		}
		
		#if os(iOS)
			image.drawInRect(targetRect, blendMode: .Normal, alpha: fraction)
		#else
			image.drawInRect(targetRect, fromRect: CGRectZero, operation: .CompositeSourceOver, fraction: fraction, respectFlipped: true, hints: nil)
		#endif
	}
	
	#if !os(iOS)
	
	@available(OSX 10.10, *)
	public convenience init?(CGImage: CGImageRef, asBitmapImageRep: Bool) {
		let width = CGImageGetWidth(CGImage);
		let height = CGImageGetHeight(CGImage);
		
		self.init(size: CGSizeMake(CGFloat(width), CGFloat(height)))
		
		if asBitmapImageRep {
			let hasAlpha = CGImageGetAlphaInfo(CGImage) == .None ? false : true
			let bps = 8; // hardwiring to 8 bits per sample is fine for general purposes
			let spp = hasAlpha ? 4 : 3;
			
			guard let bitmapImageRep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: bps, samplesPerPixel: spp, hasAlpha: hasAlpha, isPlanar: false, colorSpaceName: NSDeviceRGBColorSpace, bitmapFormat: .NSAlphaFirstBitmapFormat, bytesPerRow: 0, bitsPerPixel: 0) else {
				return nil
			}
			
			let bitmapContext = NSGraphicsContext(bitmapImageRep: bitmapImageRep)
			
			NSGraphicsContext.saveGraphicsState()
			NSGraphicsContext.setCurrentContext(bitmapContext)
			
			CGContextDrawImage(NSGraphicsContext.currentContext()!.CGContext, CGRectMake(0.0, 0.0, CGFloat(width), CGFloat(height)), CGImage)
			
			NSGraphicsContext.restoreGraphicsState()
			
			self.addRepresentation(bitmapImageRep)
		}else{
			self.lockFocus()
			CGContextDrawImage(NSGraphicsContext.currentContext()!.CGContext, CGRectMake(0.0, 0.0, CGFloat(width), CGFloat(height)), CGImage)
			self.unlockFocus()
		}
	}

	/// Scales down the image and if it contains multiple image representations,
	/// removes those. May fail if the image is of zero size, has no image reps,
	/// or if some of the underlying calls fails.
	public func imageWithSingleImageRepOfSize(size: CGSize) -> XUImage? {
		var result: XUImage? = nil
		XU_PERFORM_BLOCK_ON_MAIN_THREAD { () -> Void in
			result = self._imageWithSingleImageRepOfSize(size)
		}
		return result
	}
	
	#endif
	
	/// Proportionally scales the image to maximum size.
	public func proportinallyScaledSizeForMaxSize(size: CGSize) -> CGSize {
		let image = self
		let mySize = image.size
		if mySize.width < size.width && mySize.height < size.height {
			return mySize
		}
		
		var resultSize = CGSizeZero
		if mySize.width / mySize.height > size.width / size.height {
			// Wider
			resultSize.width = size.width
			resultSize.height = mySize.height * (size.width / mySize.width)
		}else{
			// Taller
			resultSize.height = size.height
			resultSize.width = mySize.width * (size.height / mySize.height)
		}
		return resultSize
	}
	
	#if os(OSX)
	
	/// Returns NSData with a bitmap image file type representation.
	public func representationForFileType(fileType: NSBitmapImageFileType, properties: [String : AnyObject] = [ : ]) -> NSData? {
		guard let temp = self.TIFFRepresentation else {
			return nil
		}
		
		let bitmap = NSBitmapImageRep(data: temp)
		let imgData = bitmap?.representationUsingType(fileType, properties: [ : ])
		return imgData
	}
	
	/// Returns a basic BMP image representation.
	public var BMPRepresentation: NSData? {
		return self.representationForFileType(.NSBMPFileType)
	}
	
	/// Returns a basic GIF image representation.
	public var GIFRepresentation: NSData? {
		return self.representationForFileType(.NSGIFFileType)
	}
	
	/// Returns a GIF image representation
	public func GIFRepresentationWithDitheredTransparency(dither: Bool) -> NSData? {
		return self.representationForFileType(.NSGIFFileType, properties: [ NSImageDitherTransparency: dither ])
	}
	
	/// Returns a basic JPEG image representation.
	public var JPEGRepresentation: NSData? {
		return self.representationForFileType(.NSJPEGFileType)
	}
	
	/// Returns a JPEG image representation with specified quality.
	public func JPEGRepresentationUsingCompressionFactor(compressionFactor: Int, progressive: Bool) -> NSData? {
		let properties: [String : AnyObject] = [
			NSImageCompressionFactor: compressionFactor,
			NSImageProgressive: progressive
		]
		return self.representationForFileType(.NSJPEGFileType, properties: properties)
	}
	
	/// Returns a basic JPEG 2000 image representation.
	public var JPEG2000Representation: NSData? {
		return self.representationForFileType(.NSJPEG2000FileType)
	}
	
	/// Returns a basic PNG image representation.
	public var PNGRepresentation: NSData? {
		return self.representationForFileType(.NSPNGFileType)
	}
	
	/// Returns a PNG image representation with interlace as defined.
	public func PNGRepresentationInterlaced(interlace: Bool) -> NSData? {
		return self.representationForFileType(.NSPNGFileType, properties: [ NSImageInterlaced : interlace ])
	}

	/// Returns a TIFF image representation with defined compression.
	public func TIFFRepresentationUsingCompression(compression: NSTIFFCompression) -> NSData? {
		return self.representationForFileType(.NSTIFFFileType, properties: [ NSImageCompressionMethod: compression.rawValue ])
	}
	
	/// Draws the image as tile in specified rect.
	public func tileInRect(rect: CGRect) {
		let size = self.size
		var destRect = CGRectMake(rect.origin.x, rect.origin.y, size.width, size.height)
		let top = rect.origin.y + rect.size.height
		let right = rect.origin.x + rect.size.width
		
		// Tile vertically
		while destRect.origin.y < top {
			// Tile horizontally
			while destRect.origin.x < right {
				var sourceRect = CGRectMake(0.0, 0.0, size.width, size.height)
				
				// Crop as necessary
				if destRect.maxX > right {
					sourceRect.size.width -= destRect.maxX - right
				}
				
				if destRect.maxY > top {
					sourceRect.size.height -= destRect.maxY - top
				}
				
				// Draw and shift
				self.drawAtPoint(destRect.origin, fromRect: sourceRect, operation: .CompositeSourceOver, fraction: 1.0)
				destRect.origin.x += destRect.size.width
			}
			
			destRect.origin.y += destRect.size.height
		}
	}
	
	#else
	
	/// Returns a proportionally resized image to targetSize.
	public func imageResizedToSize(targetSize: CGSize) -> UIImage {
		let size = self.size
		if size.width <= targetSize.width && size.height <= targetSize.height {
			return self
		}
		
		var newSize = CGSizeZero
		if size.width > size.height {
			var width = targetSize.width
			var height = size.height * (targetSize.width / size.width)
			if height > targetSize.height {
				height = targetSize.height
				width = size.width * (targetSize.height / size.height)
			}
			newSize.width = width
			newSize.height = height
		}else{
			var width = size.width * (targetSize.height / size.height)
			var height = targetSize.height
			if width > targetSize.width {
				width = targetSize.width
				height = size.height * (targetSize.width / size.width)
			}
			newSize.width = width
			newSize.height = height
		}
		
		UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
		self.drawInRect(CGRectMake(0.0, 0.0, newSize.width, newSize.height))
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return newImage
	}

	/// Returns PNG representation of the image.
	public var PNGRepresentation: NSData? {
		return UIImagePNGRepresentation(self)
	}
	
	#endif
}
