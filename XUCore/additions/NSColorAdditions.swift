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
	
	@objc fileprivate func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
		return .copy
	}
	@objc fileprivate func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: CGPoint, operation: NSDragOperation) {
		
	}
	
}

private let _source = _XU_NSColorDraggingSource()
private var _draggingSession: NSDraggingSession?

extension NSColor: NSPasteboardItemDataProvider {
	
	fileprivate var _imagePreview: NSImage {
		let image = NSImage(size: CGSize(width: kXUColorSampleItemWidth, height: kXUColorSampleItemHeight))
		image.backgroundColor = NSColor.clear
		image.lockFocus()
		
		self.set()
		
		let paintRect = CGRect(x: 0.0, y: 0.0, width: kXUColorSampleItemWidth, height: kXUColorSampleItemHeight)
		
		NSBezierPath(rect: paintRect).fill()
		
		image.unlockFocus()
		return image
	}
	
	/// Creates a new dragging session with the color. The view is used as the
	/// source of the drag.
	public func drag(withEvent event: NSEvent, from view: NSView) {
		let image = NSImage(size: CGSize(width: 12.0, height: 12.0))
		image.lockFocus()
		
		// Draw color swatch
		self.drawSwatch(in: CGRect(x: 0.0, y: 0.0, width: 12.0, height: 12.0))
		
		// Draw border
		NSColor.black.set()
		NSBezierPath(rect: CGRect(x: 0.0, y: 0.0, width: 12.0, height: 12.0)).stroke()
		
		image.unlockFocus()
		
		var p = view.convert(event.locationInWindow, from: nil)
		p.x -= 6.0
		p.y -= 6.0
		
		let pbItem = NSPasteboardItem()
		pbItem.setDataProvider(self, forTypes: [ NSColorPboardType, NSPasteboardTypeColor, NSPasteboardTypeTIFF, NSPasteboardTypePNG ])
		
		let item = NSDraggingItem(pasteboardWriter: pbItem)
		item.imageComponentsProvider = {
			let component = NSDraggingImageComponent(key: "Color")
			component.contents = image
			return [ component ]
		}
		
		let colorItem = NSDraggingItem(pasteboardWriter: self)
		
		colorItem.setDraggingFrame(CGRect(x: p.x, y: p.y, width: 12.0, height: 12.0), contents: image)
		_draggingSession = view.beginDraggingSession(with: [ colorItem ], event: event, source: _source)
		
		let pasteboard = _draggingSession!.draggingPasteboard
		let data = NSKeyedArchiver.archivedData(withRootObject: self)
		pasteboard.setData(data, forType: NSColorPboardType)
		pasteboard.setData(data, forType: NSPasteboardTypeColor)
		pasteboard.writeObjects([self])
		
		XULog("\(_draggingSession!)")
	}
	
	@available(*, deprecated)
	public func pasteboard(_ pasteboard: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: String) {
		switch type {
		case NSPasteboardTypeTIFF:
			pasteboard?.setData(self._imagePreview.tiffRepresentation, forType: type)
			break
		case NSPasteboardTypePNG:
			pasteboard?.setData(self._imagePreview.pngRepresentation as Data?, forType: type)
			break
		case NSPasteboardTypeColor: fallthrough
		case NSColorPboardType:
			let data = NSKeyedArchiver.archivedData(withRootObject: self)
			pasteboard?.setData(data, forType: NSColorPboardType)
			pasteboard?.setData(data, forType: NSPasteboardTypeColor)
			pasteboard?.writeObjects([self])
			break
		default:
			break
		}
	}
	
}


