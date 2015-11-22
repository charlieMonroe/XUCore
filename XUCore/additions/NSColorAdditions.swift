//
//  NSColorAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/20/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

private let kXUColorSampleItemWidth: CGFloat = 24.0
private let kXUColorSampleItemHeight: CGFloat = 24.0

private class _XU_NSColorDraggingSource: NSObject, NSDraggingSource {
	
	@objc private func draggingSession(session: NSDraggingSession, sourceOperationMaskForDraggingContext context: NSDraggingContext) -> NSDragOperation {
		return .Copy
	}
	
}

private let _source = _XU_NSColorDraggingSource()


public extension NSColor {
	
	private var _imagePreview: NSImage {
		let image = NSImage(size: CGSizeMake(kXUColorSampleItemWidth, kXUColorSampleItemHeight))
		image.backgroundColor = NSColor.clearColor()
		image.lockFocus()
		
		self.set()
		
		let paintRect = CGRectMake(0.0, 0.0, kXUColorSampleItemWidth, kXUColorSampleItemHeight)
		
		NSBezierPath(rect: paintRect).fill()
		
		image.unlockFocus()
		return image
	}
	
	/// Creates a new dragging session with the color. The view is used as the
	/// source of the drag.
	public func dragWithEvent(event: NSEvent, sourceView view: NSView) {
		let image = NSImage(size: CGSizeMake(12.0, 12.0))
		image.lockFocus()
		
		// Draw color swatch
		self.drawSwatchInRect(CGRectMake(0.0, 0.0, 12.0, 12.0))
		
		// Draw border
		NSColor.blackColor().set()
		NSBezierPath(rect: CGRectMake(0.0, 0.0, 12.0, 12.0)).stroke()
		
		image.unlockFocus()
		
		// Write to PBoard
		let dP = NSPasteboard(name: NSDragPboard)
		dP.declareTypes([ NSColorPboardType ], owner: self)
		
		let imagePreview = self._imagePreview
		if let TIFFData = imagePreview.TIFFRepresentation {
			if let bmapImage = NSImage(data: TIFFData) {
				dP.writeObjects([ bmapImage ])
			}
		}
		
		var p = view.convertPoint(event.locationInWindow, fromView: nil)
		p.x -= 6.0
		p.y -= 6.0
		
		let item = NSDraggingItem(pasteboardWriter: self)
		item.imageComponentsProvider = {
			let component = NSDraggingImageComponent(key: "Color")
			component.contents = image
			return [ component ]
		}
		
		item.draggingFrame = CGRectMake(p.x, p.y, 12.0, 12.0)
		view.beginDraggingSessionWithItems([ item ], event: event, source: _source)
	}
	
}


