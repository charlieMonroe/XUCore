//
//  XUSystemNotification.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/22/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Cocoa

/// This class represents a notification similar to the window that OS X uses
/// for volume/brightness changes, or Xcode uses them as well.
public class XUSystemNotification: NSObject {
	
	public let icon: NSImage
	public let message: String
	
	public init(icon: NSImage, andMessage message: String) {
		self.icon = icon
		self.message = message
	}
	
	/// Uses a checkmark image that is bundled with XUCore.
	public convenience init(confirmationMessage: String) {
		self.init(icon: XUCoreBundle.imageForResource("Checkmark")!, andMessage: confirmationMessage)
	}
	
}

/// This class is used for dispatching the XUSystemNotification objects. Note:
/// all methods must be called from the main thread.
public class XUSystemNotificationCenter: NSObject {
	
	public static var sharedNotificationCenter: XUSystemNotificationCenter = XUSystemNotificationCenter()
	
	private var _currentController: NSWindowController!
	private var _currentNotification: XUSystemNotification!
	private var _queue: [XUSystemNotification] = []
	
	@objc private func _hideNotification() {
		_currentController.window?.close()
		_currentController = nil
		_currentNotification = nil
		
		_queue = Array(_queue.dropFirst())
		
		if _queue.count > 0 {
			self._show()
		}
	}
	
	private func _show() {
		_currentNotification = _queue.first!
		
		_currentController = XUSystemNotificationWindowController(window: nil)
		_currentController.loadWindow()
		
		let window = _currentController.window as! XUSystemNotificationWindow
		window.messageField.stringValue = _currentNotification.message
		window.iconView.image = _currentNotification.icon
				
		NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(XUSystemNotificationCenter._hideNotification), userInfo: nil, repeats: false)
	}
	
	
	/// Displays the notification. If another notification is already being 
	/// displayed, this notification gets queued.
	public func showNotification(notification: XUSystemNotification) {
		_queue.append(notification)
		
		if _queue.count == 1 {
			self._show()
		}
	}
	
}

private class XUSystemNotificationWindowController: NSWindowController {
	
	private override func loadWindow() {
		NSNib(nibNamed: "SystemNotification", bundle: XUCoreBundle)!.instantiateWithOwner(self, topLevelObjects: nil)
	}
	override var owner: AnyObject {
		return self
	}
	override var windowNibPath: String? {
		return XUCoreBundle.pathForResource("SystemNotification", ofType: "nib")
	}
	
	
}

// Ideally, this class would be private - unfortunately, that causes the name to
// be slightly randomized, causing issues with Interface Builder.
internal class XUSystemNotificationWindow: NSWindow {
	
	@IBOutlet private weak var iconView: NSImageView!
	@IBOutlet private weak var messageField: NSTextField!
	@IBOutlet private weak var visualEffectView: NSVisualEffectView!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		let image = NSImage(size: self.frame.size)
		image.lockFocus()
		
		NSColor.blackColor().set()
		NSBezierPath(roundedRect: CGRect(origin: CGPoint(), size: self.frame.size), xRadius: 15.0, yRadius: 15.0).fill()
		
		image.unlockFocus()
		self.visualEffectView.maskImage = image
		
		if XUAppSetup.isDarkModeEnabled {
			self.visualEffectView.material = .Dark
			
			self.messageField.textColor = NSColor.whiteColor()
		}else{
			if #available(OSX 10.11, *) {
			    self.visualEffectView.material = .MediumLight
			} else {
			    self.visualEffectView.material = .Light
			}
			
			self.messageField.textColor = NSColor.blackColor()
		}
		
		self.level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))
		
		self.backgroundColor = NSColor.clearColor()
		
		var windowFrame = self.frame
		let screenFrame = NSScreen.mainScreen()!.frame
		
		windowFrame.origin.x = (screenFrame.width / 2.0) - (windowFrame.width / 2.0)
		windowFrame.origin.y = screenFrame.height / 4.0
		
		self.setFrameOrigin(windowFrame.origin)
		
		self.ignoresMouseEvents = true
		
		self.makeKeyAndOrderFront(nil)
	}
	
}
