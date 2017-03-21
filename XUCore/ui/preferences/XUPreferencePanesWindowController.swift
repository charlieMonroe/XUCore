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

open class XUPreferencePanesWindowController: NSWindowController, NSWindowDelegate, XUPreferencePanesViewDelegate {

	private static var _sharedController: XUPreferencePanesWindowController? = nil
	
	/// Factory method. Since the NSWindowController's nib-based initializer
	/// is not designated, this is a workaround.
	open class func controller(withSections sections: [XUPreferencePanesSection]) -> Self {
		let controller = self.init(windowNibName: "XUPreferencePanesWindowController")
		controller.sections = sections
		return controller
	}
	
	/// Creates a shared controller that is accessible via the sharedController
	/// property. This allows you to have an app-wide preferences controller,
	/// which is the typical scenario. If you need e.g. a per-account controller,
	/// use the initializer and create as many controllers as needed.
	open class func createSharedController(withSections sections: [XUPreferencePanesSection]) -> XUPreferencePanesWindowController {
		assert(_sharedController == nil, "Can't be creating the shared controller for the second time.")
		
		_sharedController = self.controller(withSections: sections)
		return self.sharedController
	}
	
	/// Shared controller. Will return nil until createSharedController(withSections:)
	/// is called.
	open class var sharedController: XUPreferencePanesWindowController! {
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
	public final private(set) var currentPaneController: XUPreferencePaneViewController?
	
	/// Sections.
	public final private(set) var sections: [XUPreferencePanesSection]!
	
	
	/// Sets the current view to view and changes the window size. We're forcing
	/// the 660px width here, though.
	private func _setMainWindowContentView(_ view: NSView) {
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
			
			XU_PERFORM_DELAYED_BLOCK(0.5, block: {
				preferencesWindow.recalculateKeyViewLoop()
			})
		}
	}
	
	/// Called when the preference panes window controller did select a pane.
	open func didSelectPane(_ paneController: XUPreferencePaneViewController) {
		
	}
	
	func preferencePaneView(didSelectPane paneController: XUPreferencePaneViewController) {
		self.selectPane(paneController)
	}
	
	/// Selects a pane with identifier. The identifier is taken from 
	/// XUPreferencePaneViewController.paneIdentifier.
	///
	/// This method asserts that a pane with this identifier exists.
	public func selectPane(withIdentifier identifier: String) {
		guard let pane = self.sections.map({ $0.paneControllers }).joined().find(where: { $0.paneIdentifier == identifier }) else {
			fatalError("There is no preference pane with identifier \(identifier)!")
		}
		
		self.selectPane(pane)
	}
	
	/// Selects a pane. This method assets that this pane is contained in 
	/// self.sections. If you need to modify the `paneController` before being
	/// loaded or displayed, override willSelectPane and didSelectPane.
	public func selectPane(_ paneController: XUPreferencePaneViewController) {
		assert(self.sections.map({ $0.paneControllers }).joined().contains(where: { $0 === paneController }))
		
		self.willSelectPane(paneController)
		
		self._setMainWindowContentView(paneController.view)
		_titleViewController._titleLabel.stringValue = paneController.paneName
		
		self.currentPaneController?.savePreferences()
		self.currentPaneController = paneController
		
		self.didSelectPane(paneController)
	}
	
	/// This will cause the controller to display the icon view of all the panes.
	open func showAllPanes() {
		self._setMainWindowContentView(self.allPanesView)
		_titleViewController._titleLabel.stringValue = XULocalizedString("All Preferences", inBundle: XUCoreFramework.bundle)
		
		self.currentPaneController?.savePreferences()
		self.currentPaneController = nil
		
		UserDefaults.standard.synchronize()
	}
	
	open override func showWindow(_ sender: Any?) {
		if !self.isWindowLoaded || !self.window!.isVisible {
			self.window!.center()
		}
		super.showWindow(sender)
	}
	
	/// Called when the preference panes window controller will select a pane.
	open func willSelectPane(_ paneController: XUPreferencePaneViewController) {
		
	}
	
    open override func windowDidLoad() {
        super.windowDidLoad()

		_titleViewController._titleLabel.stringValue = XULocalizedString("All Preferences", inBundle: XUCoreFramework.bundle)
		
		self.window!.delegate = self
		self.window!.titleVisibility = .hidden
        self.window!.addTitlebarAccessoryViewController(_allPanesButtonViewController)
		if #available(OSX 10.11, *) {
			self.window!.addTitlebarAccessoryViewController(_titleViewController)
		}
		
		self.window!.setContentSize(self.allPanesView.frame.size)
		self.window!.contentView!.addSubview(self.allPanesView)
		
		_currentView = self.allPanesView
    }
	
	public final override var windowNibPath: String? {
		return XUCoreFramework.bundle.path(forResource: "XUPreferencePanesWindowController", ofType: "nib")
	}
	
	/// Delegate method of the window. If you decide to override this method, it
	/// is crucial to call super, since the default implementation saves the 
	/// preferences.
	open func windowWillClose(_ notification: Notification) {
		self.currentPaneController?.savePreferences()
	}
    
}

/// Button that after a long press shows a menu instead of sending the action.
internal class XULongPressButton: NSButton {
	
	private var _mouseDownDate: TimeInterval = 0.0
	
	@objc private func _showMenu() {
		self.menu!.autoenablesItems = false
		self.menu!.popUp(positioning: nil, at: CGPoint(x: 0.0, y: self.bounds.height), in: self)
	}
	
	override func mouseDown(with theEvent: NSEvent) {
		if theEvent.modifierFlags.contains(.control) {
			self._showMenu()
			return
		}
		
		_mouseDownDate = Date.timeIntervalSinceReferenceDate
		
		self.isHighlighted = true
		
		let eventMask: NSEventMask = [.leftMouseDown, .leftMouseDragged, .leftMouseUp]
		while let nextEvent = NSApp.nextEvent(matching: NSEventMask(rawValue: UInt64(Int(eventMask.rawValue))), until: Date.distantFuture, inMode: RunLoopMode.eventTrackingRunLoopMode, dequeue: true) , nextEvent.type != .leftMouseUp {
			// No-op
		}
		
		self.isHighlighted = false
		
		let timeDelta = Date.timeIntervalSinceReferenceDate - _mouseDownDate
		if timeDelta > 0.5 {
			XU_PERFORM_DELAYED_BLOCK(0.01) {
				self._showMenu()
			}
			return
		}
		
		self.sendAction(self.action, to: self.target)
	}
	
	override func rightMouseDown(with theEvent: NSEvent) {
		self._showMenu()
	}
	
}

private class _XUAllPanesButtonViewController: NSTitlebarAccessoryViewController {
	
	@IBOutlet private weak var _button: NSButton!
	
	private weak var _prefController: XUPreferencePanesWindowController!
	
	@objc private func _showPane(_ menuItem: NSMenuItem) {
		let pane = menuItem.representedObject as! XUPreferencePaneViewController
		_prefController.preferencePaneView(didSelectPane: pane)
	}
	
	init(preferencePanesWindowController: XUPreferencePanesWindowController) {
		self._prefController = preferencePanesWindowController
		
		super.init(nibName: "_XUAllPanesButtonViewController", bundle: XUCoreFramework.bundle)!
		
		self.fullScreenMinHeight = 48.0
		if #available(OSX 10.11, *) {
			self.layoutAttribute = .left
		} else {
			self.layoutAttribute = .right
		}
		
		self.loadView()
		
		let menu = NSMenu()
		let panes = preferencePanesWindowController.sections.map({ $0.paneControllers }).joined().sorted(by: { $0.paneName < $1.paneName })
		
		let menuItem = { () -> NSMenuItem in
			let item = NSMenuItem(title: XULocalizedString("Show All"), action: #selector(showAll(_:)), keyEquivalent: "")
			item.target = self
			item.image = NSImage(named: NSImageNamePreferencesGeneral)!.imageWithSingleImageRepresentation(ofSize: CGSize(width: 16.0, height: 16.0))
			return item
		}()
		menu.addItems([menuItem, NSMenuItem.separator()])
		
		menu.addItems(panes.map({
			let item = NSMenuItem(title: $0.paneName, action: #selector(_showPane(_:)), keyEquivalent: "")
			item.target = self
			item.image = $0.paneSmallIcon
			item.representedObject = $0
			return item
		}))
		
		_button.menu = menu
		
		_button.setAccessibilityTitle(XULocalizedString("Show All"))
		_button.setAccessibilityLabel(XULocalizedString("Show All"))
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@IBAction @objc func showAll(_ sender: AnyObject) {
		_prefController.showAllPanes()
	}
	
	@objc var worksWhenModal: Bool {
		return true
	}
	
}

private class _XUPreferencePanesWindowTitleViewController: NSTitlebarAccessoryViewController {
	
	@IBOutlet weak var _titleLabel: NSTextField!
	@IBOutlet weak var _iconImageView: NSImageView! // Currently unused.
	private weak var _prefController: XUPreferencePanesWindowController!
	
	init(preferencePanesWindowController: XUPreferencePanesWindowController) {
		self._prefController = preferencePanesWindowController
		
		super.init(nibName: "_XUPreferencePanesWindowTitleViewController", bundle: XUCoreFramework.bundle)!
		
		if #available(OSX 10.11, *) {
			self.layoutAttribute = .left
		} else {
			self.layoutAttribute = .right
		}
		
		self.loadView() // Required so that _titleLabel is available
		
		if #available(OSX 10.11, *) {
		} else {
			_titleLabel.alignment = .right
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}
