//
//  XUPreferencePanesWindowController.swift
//  XUCore
//
//  Created by Charlie Monroe on 9/5/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Cocoa
import XUCore

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
	@discardableResult
	open class func createSharedController(withSections sections: [XUPreferencePanesSection]) -> XUPreferencePanesWindowController {
		XUAssert(_sharedController == nil, "Can't be creating the shared controller for the second time.")
		
		_sharedController = self.controller(withSections: sections)
		return self.shared
	}
	
	/// Shared controller. Will return nil until createSharedController(withSections:)
	/// is called.
	open class var shared: XUPreferencePanesWindowController! {
		return _sharedController
	}
	
	
	/// Controller that shows the button for accessing all panes.
	private lazy var _allPanesButtonViewController: _XUAllPanesButtonViewController = _XUAllPanesButtonViewController(preferencePanesWindowController: self)
	
	/// Current view being displayed.
	private var _currentView: NSView!
	
	/// Search field.
	private weak var _searchField: XUSearchFieldWithResults!
	
	/// Controller that shows the title.
	private lazy var _titleViewController: _XUPreferencePanesWindowTitleViewController = _XUPreferencePanesWindowTitleViewController(preferencePanesWindowController: self)
	
	/// View that displays all the panes. It's currently private, but it may be
	/// exposed in the future to allow customizations.
	private lazy var allPanesView: XUPreferencePanesView = XUPreferencePanesView(sections: self.sections, andDelegate: self)
	
	/// Current pane.
	public final private(set) var currentPaneController: XUPreferencePaneViewController?
	
	/// Sections.
	public final private(set) var sections: [XUPreferencePanesSection] = []
	
	
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
			
			DispatchQueue.main.asyncAfter(deadline: .seconds(0.5), execute: {
				preferencesWindow.recalculateKeyViewLoop()
			})
		}
	}
	
	/// Called when the preference panes window controller did select a pane.
	open func didSelectPane(_ paneController: XUPreferencePaneViewController) {
		
	}
	
	open override func keyDown(with event: NSEvent) {
		guard let characters = event.charactersIgnoringModifiers, event.modifierFlags == .command else {
			super.keyDown(with: event)
			return
		}
		
		switch characters {
		case "l":
			self.showAllPanes()
		case "f":
			self.search(nil)
		default:
			super.keyDown(with: event)
		}
	}
	
	func preferencePaneView(didSelectPane paneController: XUPreferencePaneViewController) {
		self.selectPane(paneController)
	}
	
	/// An action that selects the search field.
	@objc open func search(_ sender: Any?) {
		self.window!.makeFirstResponder(_searchField)
	}
	
	/// Selects a pane with identifier. The identifier is taken from 
	/// XUPreferencePaneViewController.paneIdentifier.
	///
	/// This method asserts that a pane with this identifier exists.
	@discardableResult
	public func selectPane(withIdentifier identifier: String) -> XUPreferencePaneViewController? {
		guard let pane = self.sections.map({ $0.paneControllers }).joined().first(where: { $0.paneIdentifier == identifier }) else {
			fatalError("There is no preference pane with identifier \(identifier)!")
		}
		
		self.window?.makeKeyAndOrderFront(nil)
		self.selectPane(pane)
		return pane
	}
	
	/// Selects a pane. This method assets that this pane is contained in 
	/// self.sections. If you need to modify the `paneController` before being
	/// loaded or displayed, override willSelectPane and didSelectPane.
	public func selectPane(_ paneController: XUPreferencePaneViewController) {
		XUAssert(self.sections.map({ $0.paneControllers }).joined().contains(where: { $0 === paneController }))
		
		self.window!.endEditing(for: nil)
		
		self.willSelectPane(paneController)
		
		self._setMainWindowContentView(paneController.view)
		_titleViewController.title = paneController.paneName
		
		self.currentPaneController?.savePreferences()
		self.currentPaneController = paneController
		
		self.didSelectPane(paneController)
	}
	
	/// This will cause the controller to display the icon view of all the panes.
	open func showAllPanes() {
		self._setMainWindowContentView(self.allPanesView)
		_titleViewController.title = XULocalizedString("All Preferences", inBundle: .core)
		
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
		
		if let searchField = self.window!.toolbar?.items.last?.view as? XUSearchFieldWithResults {
			_searchField = searchField
			searchField.resultsDelegate = self
			searchField.searchResultsWidth = 350.0
		}

		_titleViewController.title = XULocalizedString("All Preferences", inBundle: .core)
		
		self.window!.delegate = self
		self.window!.title = XULocalizedString("Preferences", inBundle: .core)
		self.window!.titleVisibility = .hidden
        self.window!.addTitlebarAccessoryViewController(_allPanesButtonViewController)
		self.window!.addTitlebarAccessoryViewController(_titleViewController)
		
		self.window!.setContentSize(self.allPanesView.frame.size)
		self.window!.contentView!.addSubview(self.allPanesView)
		
		_currentView = self.allPanesView
    }
	
	public final override var windowNibPath: String? {
		return Bundle.coreUI.path(forResource: "XUPreferencePanesWindowController", ofType: "nib")
	}
	
	public func windowShouldClose(_ sender: NSWindow) -> Bool {
		if let currentController = self.currentPaneController, !currentController.validateEditing() {
			return false
		}
		
		return true
	}
	
	/// Delegate method of the window. If you decide to override this method, it
	/// is crucial to call super, since the default implementation saves the 
	/// preferences.
	open func windowWillClose(_ notification: Notification) {
		self.window!.endEditing(for: nil)
		
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
		
		let eventMask: NSEvent.EventTypeMask = [.leftMouseDown, .leftMouseDragged, .leftMouseUp]
		while let nextEvent = NSApp.nextEvent(matching: eventMask, until: Date.distantFuture, inMode: RunLoop.Mode.eventTracking, dequeue: true) , nextEvent.type != .leftMouseUp {
			// No-op
		}
		
		self.isHighlighted = false
		
		let timeDelta = Date.timeIntervalSinceReferenceDate - _mouseDownDate
		if timeDelta > 0.5 {
			DispatchQueue.main.asyncAfter(deadline: .seconds(0.01)) {
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
		if let currentController = _prefController.currentPaneController, !currentController.validateEditing() {
			return
		}
		
		let pane = menuItem.representedObject as! XUPreferencePaneViewController
		_prefController.preferencePaneView(didSelectPane: pane)
	}
	
	init(preferencePanesWindowController: XUPreferencePanesWindowController) {
		self._prefController = preferencePanesWindowController
		
		super.init(nibName: "_XUAllPanesButtonViewController", bundle: .coreUI)
		
		self.fullScreenMinHeight = 48.0
		self.layoutAttribute = .left
		
		self.loadView()
		
		let menu = NSMenu()
		let panes = preferencePanesWindowController.sections.map({ $0.paneControllers }).joined().sorted(by: { $0.paneName < $1.paneName })
		
		let menuItem = { () -> NSMenuItem in
			let item = NSMenuItem(title: XULocalizedString("Show All", inBundle: .core), action: #selector(_XUAllPanesButtonViewController.showAll(_:)), keyEquivalent: "")
			item.target = self
			item.image = NSImage(named: NSImage.preferencesGeneralName)!.imageWithSingleImageRepresentation(ofSize: CGSize(width: 16.0, height: 16.0))
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
		
		_button.setAccessibilityTitle(XULocalizedString("Show All", inBundle: .core))
		_button.setAccessibilityLabel(XULocalizedString("Show All", inBundle: .core))
		
		if #available(macOS 11.0, *) {
			_button.showsBorderOnlyWhileMouseInside = true
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@IBAction @objc func showAll(_ sender: AnyObject) {
		if let currentController = _prefController.currentPaneController, !currentController.validateEditing() {
			return
		}
		
		_prefController.showAllPanes()
	}
	
	@objc var worksWhenModal: Bool {
		return true
	}
	
}

private class _XUPreferencePanesWindowTitleViewController: NSTitlebarAccessoryViewController {
	
	@IBOutlet private weak var _titleLabel: NSTextField!
	@IBOutlet weak var _iconImageView: NSImageView! // Currently unused.
	private weak var _prefController: XUPreferencePanesWindowController!
	
	init(preferencePanesWindowController: XUPreferencePanesWindowController) {
		self._prefController = preferencePanesWindowController
		
		super.init(nibName: "_XUPreferencePanesWindowTitleViewController", bundle: .coreUI)
		
		self.layoutAttribute = .left
		
		self.loadView() // Required so that _titleLabel is available
		
		if #available(macOS 11.0, *) {
			_titleLabel.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override var title: String? {
		didSet {
			if oldValue == nil {
				_titleLabel?.stringValue = self.title ?? ""
				return
			}
			
			guard let label = _titleLabel else {
				return
			}
			
			XUViewAnimation(view: label).setStringValueAnimated(self.title ?? "", duration: 0.25)
		}
	}
	
}
