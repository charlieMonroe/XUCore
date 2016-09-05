//
//  XUPreferencePanesWindowController.swift
//  XUCore
//
//  Created by Charlie Monroe on 9/5/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Cocoa

/// This class will encapsulate the pane controllers into a section. The section
/// name is optional and currently unused.
public struct XUPreferencePanesSection {
	
	/// Optionally, name of the section. This is reserved for future use as it's
	/// not displayed anywhere in the UI at this time. The name should be localized
	/// nonetheless.
	public let name: String?
	
	/// Pane controllers in the section.
	public let paneControllers: [XUPreferencePaneViewController]
	
	/// Initializer.
	public init(paneControllers: [XUPreferencePaneViewController], andName name: String? = nil) {
		self.name = name
		self.paneControllers = paneControllers
	}
	
}

public class XUPreferencePanesWindowController: NSWindowController, XUPreferencePanesViewDelegate {

	private static var _sharedController: XUPreferencePanesWindowController? = nil
	
	/// Factory method. Since the NSWindowController's nib-based initializer
	/// is not designated, this is a workaround.
	public class func controller(withSections sections: [XUPreferencePanesSection]) -> XUPreferencePanesWindowController {
		let controller = XUPreferencePanesWindowController(windowNibName: "XUPreferencePanesWindowController")
		controller.sections = sections
		return controller
	}
	
	/// Creates a shared controller that is accessible via the sharedController
	/// property. This allows you to have an app-wide preferences controller,
	/// which is the typical scenario. If you need e.g. a per-account controller,
	/// use the initializer and create as many controllers as needed.
	public class func createSharedController(withSections sections: [XUPreferencePanesSection]) -> XUPreferencePanesWindowController {
		assert(_sharedController == nil, "Can't be creating the shared controller for the second time.")
		
		_sharedController = XUPreferencePanesWindowController.controller(withSections: sections)
		return self.sharedController
	}
	
	/// Shared controller. Will return nil until createSharedController(withSections:)
	/// is called.
	public class var sharedController: XUPreferencePanesWindowController! {
		return _sharedController
	}
	
	
	/// Controller that shows the button for accessing all panes.
	private lazy var _allPanesButtonViewController: _XUAllPanesButtonViewController = _XUAllPanesButtonViewController(preferencePanesWindowController: self)
	
	/// Current view being displayed.
	private var _currentView: NSView!
	
	/// Controller that shows the title.
	private lazy var _titleViewController: _XUPreferencePanesWindowTitleViewController = _XUPreferencePanesWindowTitleViewController(preferencePanesWindowController: self)
	
	/// View that displays all the panes. It's currently private, but it may be
	/// exposed in the future to allow customizations.
	private lazy var allPanesView: XUPreferencePanesView = XUPreferencePanesView(sections: self.sections, andDelegate: self)
	
	/// Current pane.
	public private(set) var currentPaneController: XUPreferencePaneViewController?
	
	/// Sections.
	public private(set) var sections: [XUPreferencePanesSection]!
	
	
	/// Sets the current view to view and changes the window size. We're forcing
	/// the 660px width here, though.
	private func _setMainWindowContentView(view: NSView) {
		let preferencesWindow = self.window!
		if _currentView != view {
			var winFrame = preferencesWindow.frame
			let contSize = preferencesWindow.contentView!.bounds.size
			
			winFrame.size.width = XUPreferencePanesView.viewWidth
			
			let yDelta = contSize.height - view.bounds.size.height
			winFrame.origin.y += yDelta
			winFrame.size.height -= yDelta
			
			NSAnimationContext.beginGrouping()
			preferencesWindow.animator().contentView = view
			preferencesWindow.animator().setFrame(winFrame, display: false)
			NSAnimationContext.endGrouping()
			
			_currentView = view
		}
	}
	
	func preferencePaneView(didSelectPane paneController: XUPreferencePaneViewController) {
		self._setMainWindowContentView(paneController.view)
		_titleViewController._titleLabel.stringValue = paneController.paneName
		
		self.currentPaneController?.savePreferences()
		self.currentPaneController = paneController
	}
	
	/// This will cause the controller to display the icon view of all the panes.
	public func showAllPanes() {
		self._setMainWindowContentView(self.allPanesView)
		_titleViewController._titleLabel.stringValue = XULocalizedString("All Preferences", inBundle: XUCoreBundle)
		
		self.currentPaneController?.savePreferences()
		self.currentPaneController = nil
	}
	
	public override func showWindow(sender: AnyObject?) {
		if !self.windowLoaded || !self.window!.visible {
			self.window!.center()
		}
		super.showWindow(sender)
	}
	
    public override func windowDidLoad() {
        super.windowDidLoad()

		_titleViewController._titleLabel.stringValue = XULocalizedString("All Preferences", inBundle: XUCoreBundle)
		
		self.window!.titleVisibility = .Hidden
        self.window!.addTitlebarAccessoryViewController(_allPanesButtonViewController)
		self.window!.addTitlebarAccessoryViewController(_titleViewController)
		
		self.window!.setContentSize(self.allPanesView.frame.size)
		self.window!.contentView!.addSubview(self.allPanesView)
		
		_currentView = self.allPanesView
    }
    
}

/// Button that after a long press shows a menu instead of sending the action.
internal class XULongPressButton: NSButton {
	
	private var _mouseDownDate: NSTimeInterval = 0.0
	
	@objc private func _showMenu() {
		self.menu!.popUpMenuPositioningItem(nil, atLocation: CGPoint(x: 0.0, y: self.bounds.height), inView: self)
	}
	
	override func mouseDown(theEvent: NSEvent) {
		_mouseDownDate = NSDate.timeIntervalSinceReferenceDate()
		
		self.highlighted = true
		
		let eventMask: NSEventMask = [.LeftMouseDownMask, .LeftMouseDraggedMask, .LeftMouseUpMask]
		while let nextEvent = NSApp.nextEventMatchingMask(Int(eventMask.rawValue), untilDate: NSDate.distantFuture(), inMode: NSEventTrackingRunLoopMode, dequeue: true) where nextEvent.type != .LeftMouseUp {
			// No-op
		}
		
		self.highlighted = false
		
		let timeDelta = NSDate.timeIntervalSinceReferenceDate() - _mouseDownDate
		if timeDelta > 0.5 {
			XU_PERFORM_DELAYED_BLOCK(0.01) {
				self._showMenu()
			}
			return
		}
		
		self.sendAction(self.action, to: self.target)
	}
	
	override func rightMouseDown(theEvent: NSEvent) {
		self._showMenu()
	}
	
}

private class _XUAllPanesButtonViewController: NSTitlebarAccessoryViewController {
	
	@IBOutlet private weak var _button: NSButton!
	
	private weak var _prefController: XUPreferencePanesWindowController!
	
	@objc private func _showPane(menuItem: NSMenuItem) {
		let pane = menuItem.representedObject as! XUPreferencePaneViewController
		_prefController.preferencePaneView(didSelectPane: pane)
	}
	
	init(preferencePanesWindowController: XUPreferencePanesWindowController) {
		self._prefController = preferencePanesWindowController
		
		super.init(nibName: "_XUAllPanesButtonViewController", bundle: XUCoreBundle)!
		
		self.fullScreenMinHeight = 48.0
		self.layoutAttribute = .Left
		
		self.loadView()
		
		let menu = NSMenu()
		let panes = preferencePanesWindowController.sections.map({ $0.paneControllers }).flatten().sort({ $0.paneName < $1.paneName })
		
		let menuItem = { () -> NSMenuItem in
			let item = NSMenuItem(title: XULocalizedString("Show All"), action: #selector(showAll(_:)), keyEquivalent: "")
			item.target = self
			item.image = NSImage(named: NSImageNamePreferencesGeneral)!.imageWithSingleImageRepOfSize(CGSize(width: 16.0, height: 16.0))
			return item
		}()
		menu.addItems([menuItem, NSMenuItem.separatorItem()])
		
		menu.addItems(panes.map({
			let item = NSMenuItem(title: $0.paneName, action: #selector(_showPane(_:)), keyEquivalent: "")
			item.target = self
			item.image = $0.paneSmallIcon
			item.representedObject = $0
			return item
		}))
		_button.menu = menu
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@IBAction @objc func showAll(sender: AnyObject) {
		_prefController.showAllPanes()
	}
	
}

private class _XUPreferencePanesWindowTitleViewController: NSTitlebarAccessoryViewController {
	
	@IBOutlet weak var _titleLabel: NSTextField!
	private weak var _prefController: XUPreferencePanesWindowController!
	
	init(preferencePanesWindowController: XUPreferencePanesWindowController) {
		self._prefController = preferencePanesWindowController
		
		super.init(nibName: "_XUPreferencePanesWindowTitleViewController", bundle: XUCoreBundle)!
		
		self.layoutAttribute = .Left
		self.loadView() // Required so that _titleLabel is available
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}
