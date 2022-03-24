//
//  XUSystemNotification.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/22/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Cocoa
import XUCore

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
		self.init(icon: Bundle.coreUI.image(forResource: "Checkmark")!, message: confirmationMessage, subtitle: subtitle)
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
		
		/// Progress indicator with a message.
		case progress(message: String?)
	}
	
	private var _currentController: XUSystemNotificationWindowController!
	private var _currentNotification: Notification!
	private var _progressController: XUSystemNotificationWindowController?
	private var _queue: [Notification] = []
	
	@objc private func _hideNotification() {
		self._hideController(_currentController)
		
		_currentController = nil
		_currentNotification = nil
		
		_queue.remove(at: 0)
		
		if !_queue.isEmpty {
			self._show()
		}
	}
	
	private func _hideController(_ controller: XUSystemNotificationWindowController) {
		guard let window = controller.window else {
			return
		}
		
		window.animator().alphaValue = 0.0
		DispatchQueue.main.asyncAfter(deadline: .seconds(CATransaction.animationDuration())) {
			controller.window?.close()
		}
	}
	
	private func _show() {
		_currentNotification = _queue.first!
		
		_currentController = XUSystemNotificationWindowController(notification: _currentNotification)
		_currentController.loadWindow()
		
		if case .system(let notification) = _currentNotification! {
			NSAccessibility.post(element: _currentController!, notification: NSAccessibility.Notification.announcementRequested, userInfo: [NSAccessibility.NotificationUserInfoKey.announcement : notification.message])
		}
		
		Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(XUSystemNotificationCenter._hideNotification), userInfo: nil, repeats: false)
	}
	
	/// Hides currently displayed progress indicator. See showProgressIndicator(with:).
	public func hideProgressIndicator() {
		_progressController.flatMap(self._hideController(_:))
		_progressController = nil
	}
	
	/// Displays a notification showing a custom view. The size of the notification
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
	
	/// Shows a HUD with an indeterminate progress indicator and it is shown until
	/// you call hideProgressIndicator(_:).
	///
	/// Note that only one progress indicator may be shown at a time. Also, it is
	/// not queued like other notifications, but it is displayed right away.
	///
	/// - Parameter message: Optional message to be displayed.
	public func showProgressIndicator(with message: String? = nil) {
		if let progressController = _progressController {
			let window = progressController.window as! XUSystemNotificationWindow
			window.messageField.stringValue = message ?? ""
		} else {
			let controller = XUSystemNotificationWindowController(notification: .progress(message: message))
			controller.loadWindow()
			_progressController = controller
			
			if let message = message {
				NSAccessibility.post(element: controller, notification: NSAccessibility.Notification.announcementRequested, userInfo: [NSAccessibility.NotificationUserInfoKey.announcement : message])
			}
		}
	}
	
}

private class XUSystemNotificationWindowController: NSWindowController, NSWindowDelegate {
	
	private class ProgressIndicator: NSView {
		
		private var _animationValue: Double = 0.0
		private var _timer: Timer?
		
		deinit {
			_timer?.invalidate()
		}
		
		override func draw(_ dirtyRect: NSRect) {
			let context = NSGraphicsContext.current!.cgContext
			let numberOfRays = 12
			let offset = Int((_animationValue * Double(numberOfRays - 1)).rounded())
			
			let bounds = self.bounds
			let center = CGPoint(x: bounds.midX, y: bounds.midY)
			let angle: CGFloat = 0.0
			let arc: CGFloat = CGFloat.pi * 2.0 / CGFloat(numberOfRays)
			let minAxis: CGFloat = min(bounds.width, bounds.height)
			
			var lineWidth: CGFloat = minAxis / CGFloat(numberOfRays) / 2.0
			lineWidth += lineWidth * 0.75
			
			context.setLineWidth(lineWidth)
			context.setLineCap(.round)
			
			for i in 0 ..< numberOfRays {
				let startGray: CGFloat = 0.0
				let endGray: CGFloat = 0.4
				
				let place = (i - offset < 0) ? numberOfRays + (i - offset) : i - offset
				let gray = 1.0 - (startGray + ((endGray - startGray) / CGFloat(numberOfRays)) * CGFloat(place))
				
				let rotate = CGAffineTransform(rotationAngle: angle + arc * CGFloat(i))
				let move = CGAffineTransform(translationX: center.x, y: center.y)
				let transform = rotate.concatenating(move)
				
				let point1 = CGPoint(x: 0.0, y: minAxis / 2.0 - lineWidth).applying(transform)
				let point2 = CGPoint(x: 0.0, y: minAxis / 4.0).applying(transform)
				
				context.setStrokeColor(gray: gray, alpha: 1.0)
				context.move(to: point1)
				context.addLine(to: point2)
				
				context.strokePath()
			}
		}
		
		override init(frame frameRect: NSRect) {
			super.init(frame: frameRect)
			
			_timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true, block: { [weak self] (_) in
				guard let strongSelf = self else {
					return
				}
				
				strongSelf._animationValue -= 0.05
				if strongSelf._animationValue < 0.0 {
					strongSelf._animationValue = 1.0
				}
				
				strongSelf.setNeedsDisplay(strongSelf.bounds)
			})
		}
		
		required init?(coder decoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		
	}
	
	/// Notification this was initialized with.
	var notification: XUSystemNotificationCenter.Notification!
	
	convenience init(notification: XUSystemNotificationCenter.Notification) {
		self.init(windowNibName: "SystemNotification")
		
		self.notification = notification
	}
	
	fileprivate override func loadWindow() {
		super.loadWindow()
		
		self.windowDidLoad()
	}
	
	override var windowNibPath: String? {
		return Bundle.coreUI.path(forResource: "SystemNotification", ofType: "nib")
	}
	
	func windowDidResize(_ notification: Notification) {
		let window = self.window as! XUSystemNotificationWindow
		window._updateVisualEffectViewMask()
	}
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		let window = self.window as! XUSystemNotificationWindow
		window.delegate = self
		
		switch self.notification! {
		case .system(let notification):
			window.messageField.stringValue = notification.message
			
			if #available(macOS 10.13, *) {
				window.iconView.image = notification.icon
			} else {
				window.iconView.image = notification.icon.applying(tint: .black)
			}
				
			window.subtitleField.stringValue = notification.subtitle ?? ""
			
			if notification.subtitle == nil {
				window.bottomLayoutConstraint.constant = 0.0
			}
		case .custom(let view):
			window.iconView.removeFromSuperview()
			window.messageField.removeFromSuperview()
			window.subtitleField.removeFromSuperview()
			
			let contentSize = view.frame.insetBy(dx: -15.0, dy: -15.0).size
			window.setContentSize(contentSize)
			
			view.frame = CGRect(origin: CGPoint(), size: contentSize).centeringRectInSelf(view.frame)
			
			window.visualEffectView.subviews = [view]
			window._updateVisualEffectViewMask()
			window._updateWindowFrame()
		case .progress(message: let message):
			window.messageField.stringValue = message ?? ""
			window.iconView.image = nil
			window.subtitleField.stringValue = ""
			window.bottomLayoutConstraint.constant = 0.0

			let size: CGFloat = 96.0
			let progressIndicatorWrapper = NSView(frame: CGRect(x: 0.0, y: 0.0, width: size, height: size))
			progressIndicatorWrapper.translatesAutoresizingMaskIntoConstraints = false

			window.visualEffectView.addSubview(progressIndicatorWrapper)
			window.visualEffectView.addConstraints(centeringView: progressIndicatorWrapper, verticalOffset: -10.0)
			progressIndicatorWrapper.addConstraints(forWidth: size, height: size)
			
			let progressIndicator = ProgressIndicator(frame: CGRect(x: 0.0, y: 0.0, width: size, height: size))
			progressIndicator.translatesAutoresizingMaskIntoConstraints = false
			
			progressIndicatorWrapper.addSubview(progressIndicator)
			progressIndicatorWrapper.addConstraints(pinningViewOnAllSides: progressIndicator)
			
			progressIndicator.appearance = NSAppearance(named: .vibrantDark)
		}
		
		window.alphaValue = 0.0
		window.animator().alphaValue = 1.0
	}
	
	func windowWillClose(_ notification: Notification) {
		self.window = nil
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
		NSBezierPath(roundedRect: CGRect(origin: .zero, size: self.frame.size), xRadius: 15.0, yRadius: 15.0).fill()
		
		image.unlockFocus()
		self.visualEffectView.maskImage = image
	}
	
	fileprivate func _updateWindowFrame() {
		var windowFrame = self.frame
		
		let screen = NSApp.keyWindow?.screen ?? NSScreen.screens[0]
		let screenFrame = screen.frame

		windowFrame.origin.x = screenFrame.minX + (screenFrame.width / 2.0) - (windowFrame.width / 2.0)
		windowFrame.origin.y = screenFrame.minY + screenFrame.height / 4.0
		
		self.setFrameOrigin(windowFrame.origin)
		
		self.ignoresMouseEvents = true
		
		self.makeKeyAndOrderFront(nil)
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		self._updateVisualEffectViewMask()
		
		if #available(macOS 10.14, *) {
			self.visualEffectView.material = .hudWindow
			self.messageField.textColor = .textColor
		} else if XUAppSetup.isDarkModeEnabled {
			self.visualEffectView.material = .dark
			self.messageField.textColor = .white
		} else {
			self.visualEffectView.material = .mediumLight
			
			self.messageField.textColor = .black
		}
		
		self.level = NSWindow.Level.screenSaver
		self.backgroundColor = NSColor.clear
		self.isReleasedWhenClosed = true
		
		self._updateWindowFrame()
	}
	
}
