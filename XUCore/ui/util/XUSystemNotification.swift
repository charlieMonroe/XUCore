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
public struct XUSystemNotification {
	
	public let icon: NSImage
	public let message: String
	public let subtitle: String?
	
	public init(icon: NSImage, message: String, subtitle: String? = nil) {
		self.icon = icon
		self.message = message
		self.subtitle = subtitle
	}
	
	/// Uses a checkmark image that is bundled with XUCore.
	public init(confirmationMessage: String, subtitle: String? = nil) {
		self.init(icon: XUCoreFramework.bundle.image(forResource: NSImage.Name(rawValue: "Checkmark"))!, message: confirmationMessage, subtitle: subtitle)
	}
	
}

/// This class is used for dispatching the XUSystemNotification objects. Note:
/// all methods must be called from the main thread.
public final class XUSystemNotificationCenter {
	
	public static let shared: XUSystemNotificationCenter = XUSystemNotificationCenter()
	
	/// Notification in the queue.
	fileprivate enum Notification {
		/// Icon + title system notification.
		case system(XUSystemNotification)
		
		/// Custom notification with a view.
		case custom(NSView)
	}
	
	private var _currentController: NSWindowController!
	private var _currentNotification: Notification!
	private var _queue: [Notification] = []
	
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
		
		_currentController = XUSystemNotificationWindowController(notification: _currentNotification)
		_currentController.loadWindow()
		
		Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(XUSystemNotificationCenter._hideNotification), userInfo: nil, repeats: false)
	}
	
	/// /// Displays a notification showing a custom view. The size of the notification
	/// window is determined by the view frame. If another notification is already being
	/// displayed, this notification gets queued.
	public func showCustomNotification(with view: NSView) {
		_queue.append(.custom(view))
		
		if _queue.count == 1 {
			self._show()
		}
	}
	/// Displays the notification. If another notification is already being 
	/// displayed, this notification gets queued.
	public func showNotification(_ notification: XUSystemNotification) {
		_queue.append(.system(notification))
		
		if _queue.count == 1 {
			self._show()
		}
	}
	
}

private class XUSystemNotificationWindowController: NSWindowController {
	
	/// Notification this was initialized with.
	var notification: XUSystemNotificationCenter.Notification!
	
	convenience init(notification: XUSystemNotificationCenter.Notification) {
		self.init(windowNibName: NSNib.Name(rawValue: "SystemNotification"))
		
		self.notification = notification
	}
	
	fileprivate override func loadWindow() {
		super.loadWindow()
		
		self.windowDidLoad()
	}
	
	override var windowNibPath: String? {
		return XUCoreFramework.bundle.path(forResource: "SystemNotification", ofType: "nib")
	}
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		let window = self.window as! XUSystemNotificationWindow
		switch self.notification! {
		case .system(let notification):
			window.messageField.stringValue = notification.message
			window.iconView.image = notification.icon
			window.subtitleField.stringValue = notification.subtitle ?? ""
			
			if notification.subtitle == nil {
				window.bottomLayoutConstraint.constant = 0.0
			}
		case .custom(let view):
			let contentSize = view.frame.insetBy(dx: -15.0, dy: -15.0).size
			window.setContentSize(contentSize)
			
			view.frame = CGRect(origin: CGPoint(), size: contentSize).centeringRectInSelf(view.frame)
			
			window.visualEffectView.subviews = [view]
			window._updateVisualEffectViewMask()
			window._updateWindowFrame()
		}
	}
	
}

// Ideally, this class would be private - unfortunately, that causes the name to
// be slightly randomized, causing issues with Interface Builder.
internal class XUSystemNotificationWindow: NSWindow {
	
	@IBOutlet fileprivate weak var bottomLayoutConstraint: NSLayoutConstraint!
	@IBOutlet fileprivate weak var iconView: NSImageView!
	@IBOutlet fileprivate weak var messageField: NSTextField!
	@IBOutlet fileprivate weak var subtitleField: NSTextField!
	@IBOutlet fileprivate weak var visualEffectView: NSVisualEffectView!
	
	fileprivate func _updateVisualEffectViewMask() {
		let image = NSImage(size: self.frame.size)
		image.lockFocus()
		
		NSColor.black.set()
		NSBezierPath(roundedRect: CGRect(origin: CGPoint(), size: self.frame.size), xRadius: 15.0, yRadius: 15.0).fill()
		
		image.unlockFocus()
		self.visualEffectView.maskImage = image
	}
	
	fileprivate func _updateWindowFrame() {
		var windowFrame = self.frame
		let screenFrame = NSScreen.main!.frame
		
		windowFrame.origin.x = (screenFrame.width / 2.0) - (windowFrame.width / 2.0)
		windowFrame.origin.y = screenFrame.height / 4.0
		
		self.setFrameOrigin(windowFrame.origin)
		
		self.ignoresMouseEvents = true
		
		self.makeKeyAndOrderFront(nil)
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		self._updateVisualEffectViewMask()
		
		if XUAppSetup.isDarkModeEnabled {
			self.visualEffectView.material = .dark
			
			self.messageField.textColor = NSColor.white
		} else {
			if #available(OSX 10.11, *) {
			    self.visualEffectView.material = .mediumLight
			} else {
			    self.visualEffectView.material = .light
			}
			
			self.messageField.textColor = NSColor.black
		}
		
		self.level = NSWindow.Level.screenSaver
		
		self.backgroundColor = NSColor.clear
		
		self._updateWindowFrame()
	}
	
}
