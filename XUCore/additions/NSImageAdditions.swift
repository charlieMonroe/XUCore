//
//  NSImageAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/30/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

public extension NSImage {
	
	/// Returns an image with just a single image representation of size.
	private func _imageWithSingleImageRepOfSize(_ size: CGSize) -> XUImage? {
		if size.isEmpty {
			return nil
		}
		
		let newSize = size
		let s = self.size
		if s.width <= newSize.width && s.height <= newSize.height {
			return self
		}
		
		let icon = NSImage(size: newSize)
		icon.lockFocus()
		
		let height = (s.height > s.width) ? newSize.height : (newSize.width / s.width) * s.height
		let width = (s.width >= s.height) ? newSize.width : (newSize.height / s.height) * s.width
		
		
		let fromRect = CGRect(x: (newSize.width - width) / 2.0, y: (newSize.height - height) / 2.0, width: width, height: height)
		self.draw(in: fromRect, from: CGRect(x: 0.0, y: 0.0, width: s.width, height: s.height), operation: .copy, fraction: 1.0)
		
		icon.unlockFocus()
		
		if icon.representations.count > 1 || icon.representations.count == 0 {
			XULog("image scaled with more than one rep or with none: \(icon.representations.count)")
		}
		
		let imageRep = icon.representations.first!
		imageRep.pixelsWide = Int(newSize.width)
		imageRep.pixelsHigh = Int(newSize.height)
		
		return icon
	}
	
	/// Returns a black & white copy of the image. May return nil, if the image
	/// contains no bitmap image representations, or if the conversion fails.
	public var blackAndWhiteImage: XUImage? {
		guard let rep = self.representations.first as? NSBitmapImageRep else {
			return nil
		}
		
		guard let bwRep = rep.converting(to: NSColorSpace.deviceGray, renderingIntent: .default) else {
			return nil
		}
		
		let image = NSImage(size: CGSize(width: rep.size.width, height: rep.size.height))
		image.addRepresentation(bwRep)
		return image
	}
	
	/// Draws the image at point from rect. If respectFlipped is true, the current
	/// context's flip is respected.
	public func draw(at point: CGPoint, fromRect: CGRect, operation op: NSCompositingOperation, fraction delta: CGFloat, respectFlipped: Bool) {
		var rect: CGRect = CGRect()
		rect.origin = point
		rect.size = self.size
		
		self.draw(in: rect, from: fromRect, operation: op, fraction: delta, respectFlipped: respectFlipped, hints: nil)
	}

	/// Inits with GCImageRef.
	public convenience init?(cgImage: CGImage, asBitmapImageRep: Bool) {
		let width = cgImage.width;
		let height = cgImage.height;
		
		self.init(size: CGSize(width: CGFloat(width), height: CGFloat(height)))
		
		if asBitmapImageRep {
			let hasAlpha = cgImage.alphaInfo == .none ? false : true
			let bps = 8; // hardwiring to 8 bits per sample is fine for general purposes
			let spp = hasAlpha ? 4 : 3;
			
			guard let bitmapImageRep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: bps, samplesPerPixel: spp, hasAlpha: hasAlpha, isPlanar: false, colorSpaceName: NSDeviceRGBColorSpace, bitmapFormat: .alphaFirst, bytesPerRow: 0, bitsPerPixel: 0) else {
				return nil
			}
			
			guard let bitmapContext = NSGraphicsContext(bitmapImageRep: bitmapImageRep) else {
				return nil
			}
			
			NSGraphicsContext.saveGraphicsState()
			NSGraphicsContext.setCurrent(bitmapContext)
			
			NSGraphicsContext.current()!.cgContext.draw(cgImage, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))
			
			NSGraphicsContext.restoreGraphicsState()
			
			self.addRepresentation(bitmapImageRep)
		}else{
			self.lockFocus()
			NSGraphicsContext.current()!.cgContext.draw(cgImage, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))
			self.unlockFocus()
		}
	}
		
	/// Scales down the image and if it contains multiple image representations,
	/// removes those. May fail if the image is of zero size, has no image reps,
	/// or if some of the underlying calls fails.
	public func imageWithSingleImageRepresentation(ofSize size: CGSize) -> XUImage? {
		var result: XUImage? = nil
		XU_PERFORM_BLOCK_ON_MAIN_THREAD { () -> Void in
			result = self._imageWithSingleImageRepOfSize(size)
		}
		return result
	}
	
	/// Returns NSData with a bitmap image file type representation.
	public func representation(forFileType fileType: NSBitmapImageFileType, properties: [String : AnyObject] = [:]) -> Data? {
		guard let temp = self.tiffRepresentation else {
			return nil
		}
		
		let bitmap = NSBitmapImageRep(data: temp)
		let imgData = bitmap?.representation(using: fileType, properties: [:])
		return imgData
	}
	
	/// Returns a basic BMP image representation.
	public var bmpRepresentation: Data? {
		return self.representation(forFileType: .BMP)
	}
	
	/// Returns a basic GIF image representation.
	public var gifRepresentation: Data? {
		return self.representation(forFileType: .GIF)
	}
	
	/// Returns a GIF image representation
	public func gifRepresentation(withDitheredTransparency dither: Bool) -> Data? {
		return self.representation(forFileType: .GIF, properties: [NSImageDitherTransparency: dither as AnyObject])
	}
	
	/// Returns a basic JPEG image representation.
	public var jpegRepresentation: Data? {
		return self.representation(forFileType: .JPEG)
	}
	
	/// Returns a JPEG image representation with specified quality.
	public func jpegRepresentation(usingCompressionFactor compressionFactor: Int, progressive: Bool) -> Data? {
		let properties: [String : AnyObject] = [
			NSImageCompressionFactor: compressionFactor as AnyObject,
			NSImageProgressive: progressive as AnyObject
		]
		return self.representation(forFileType: .JPEG, properties: properties)
	}
	
	/// Returns a basic JPEG 2000 image representation.
	public var jpeg2000Representation: Data? {
		return self.representation(forFileType: .JPEG)
	}
	
	/// Returns a basic PNG image representation.
	public var pngRepresentation: Data? {
		return self.representation(forFileType: .PNG)
	}
	
	/// Returns a PNG image representation with interlace as defined.
	public func pngRepresentation(interlaced interlace: Bool) -> Data? {
		return self.representation(forFileType: .PNG, properties: [NSImageInterlaced : interlace as AnyObject])
	}
	
	/// Returns a TIFF image representation with defined compression.
	public func tiffRepresentation(usingCompression compression: NSTIFFCompression) -> Data? {
		return self.representation(forFileType: .TIFF, properties: [NSImageCompressionMethod: compression.rawValue as AnyObject])
	}
	
	/// Draws the image as tile in specified rect.
	public func tile(inRect rect: CGRect) {
		let size = self.size
		var destRect = CGRect(x: rect.minX, y: rect.minY, width: size.width, height: size.height)
		let top = rect.minY + rect.height
		let right = rect.minX + rect.width
		
		// Tile vertically
		while destRect.minY < top {
			// Tile horizontally
			while destRect.minX < right {
				var sourceRect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
				
				// Crop as necessary
				if destRect.maxX > right {
					sourceRect.size.width -= destRect.maxX - right
				}
				
				if destRect.maxY > top {
					sourceRect.size.height -= destRect.maxY - top
				}
				
				// Draw and shift
				self.draw(at: destRect.origin, from: sourceRect, operation: .sourceOver, fraction: 1.0)
				destRect.origin.x += destRect.width
			}
			
			destRect.origin.y += destRect.height
		}
	}
	
}
