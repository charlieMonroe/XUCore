//
//  XUSearchFieldWithResults.swift
//  Eon
//
//  Created by Charlie Monroe on 10/6/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Cocoa

/// This provides the search field with results. See the methods for more 
/// information.
///
/// Note: Ideally, the protocol would have associated type, but then it can't be
/// addressed as var. Alternatively, it would be great to have it
public protocol XUSearchFieldWithResultsDelegate: AnyObject {
	
	/// This gets called when the user cancels the search, or if the query changes
	/// before completionHandler from searchField(_:didChangeQuery:completionHandler:)
	/// is called.
	func searchField(didCancelCurrentSearch field: XUSearchFieldWithResults)
	
	/// This gets called when the text is modified and the delegate should
	/// perform a search. The search may be performed both on main thread
	/// and on secondary thread, but in any case, completionHandler must be called.
	func searchField(_ field: XUSearchFieldWithResults, didChangeQuery query: String, completionHandler: @escaping ([Any]) -> ())
	
	/// Called when the user selects the result.
	func searchField(_ field: XUSearchFieldWithResults, didSelectResult searchResult: Any)
	
	/// Return description for the result that is used for voice over.
	func searchField(_ field: XUSearchFieldWithResults, accessibilityValueFor searchResult: Any) -> String?
	
	/// Return height of a row for a search result.
	func searchField(_ field: XUSearchFieldWithResults, heightOfRowFor searchResult: Any) -> CGFloat
	
	/// Return row view for a search result.
	func searchField(_ field: XUSearchFieldWithResults, tableView: NSTableView, rowViewFor searchResult: Any) -> NSTableRowView
	
	/// Return a view for a search result.
	func searchField(_ field: XUSearchFieldWithResults, tableView: NSTableView, viewForColumn tableColumn: NSTableColumn?, andResult searchResult: Any) -> NSView
	
}

/// This is a search field that displays results below itself, allows the user
/// to navigate between the results using arrows and confirm selection using 
/// return. See the resultsDelegate property.
///
/// Note: requires NSApp to be based on XUApplication.
@IBDesignable
public final class XUSearchFieldWithResults: NSSearchField {
	
	/// If true, and the user selects a search result, the search field hides
	/// the search results and clears self.
	@IBInspectable public var clearsOnSelection: Bool = true
	
	/// Maximum number of results to display. 6 by default.
	public var maximumNumberOfResults: Int = 6
	
	/// Delegate that handles the search. See the protocol documentation for more
	/// information.
	public weak var resultsDelegate: XUSearchFieldWithResultsDelegate?
	
	/// Current search results.
	///
	/// Note: When you set them manually, it will automatically open the search 
	/// window.
	public var results: [Any] = [] {
		didSet {
			assert(Thread.isMainThread)
			
			self.searchResultsTableView.reloadData()
			self.searchResultsTableView.scrollRowToVisible(0)
			
			if let mainWindow = self.window {
				let resultText = self.results.isEmpty ? XULocalizedString("No search results", inBundle: XUCoreFramework.bundle) : XULocalizedFormattedString("%li search results", self.results.count, inBundle: XUCoreFramework.bundle)
				NSAccessibilityPostNotificationWithUserInfo(mainWindow, NSAccessibilityAnnouncementRequestedNotification, [
					NSAccessibilityAnnouncementKey: resultText
					])
			}
			
			if self.results.isEmpty {
				self.hideSearchWindow()
				return
			}
			
			self.searchResultsTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
			self.showSearchWindow()
		}
	}
	
	/// Width of the search results. The height is automatically determined based
	/// on the number of results.
	public var searchResultsWidth: CGFloat = 300.0
	
	
	/// Lock that guards results.
	private let _lock = NSRecursiveLock(name: "com.charliemonroe.XUSearchFieldWithResults")
	
	/// Timer that makes sure that we don't fire the search action with each key
	/// stroke.
	private weak var _delayedSearchTimer: Timer?
	
	/// Indicates that the delegate was asked to perform a search, but hasn't
	/// delivered results yet.
	private var _isSearchInProgress: Bool = false
	
	/// Cell for cancelling the search.
	private var _searchFieldCancelCell: NSButtonCell?
	
	/// Current search string.
	private var _searchString: String = ""
	
	private lazy var progressIndicator: NSProgressIndicator = {
		let indicator = NSProgressIndicator()
		indicator.style = .spinningStyle
		indicator.controlSize = .mini
		indicator.isDisplayedWhenStopped = false
		indicator.sizeToFit()
		self.addSubview(indicator)
		return indicator
	}()
	
	private lazy var searchResultsPanel: NSPanel = {
		let panel = NSPanel(contentRect: CGRect(x: 0.0, y: 0.0, width: self.searchResultsWidth, height: 200.0), styleMask: [.borderless], backing: .buffered, defer: true)
		panel.contentView = self.searchResultsScrollView
		panel.hasShadow = true
		panel.hidesOnDeactivate = false
		return panel
	}()

	fileprivate lazy var searchResultsTableView: NSTableView = {
		let tableView = NSTableView()
		tableView.dataSource = self
		tableView.delegate = self
		tableView.target = self
		tableView.doubleAction = #selector(_selectSearchResult(_:))
		tableView.headerView = nil
		tableView.usesAlternatingRowBackgroundColors = true
		tableView.addTableColumn(NSTableColumn(identifier: "com.charliemonroe.XUSearchFieldWithResults"))
		tableView.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
		return tableView
	}()
	
	fileprivate lazy var searchResultsScrollView: NSScrollView = {
		let scrollView = NSScrollView()
		scrollView.contentView.documentView = self.searchResultsTableView
		return scrollView
	}()
	
	@objc private func _repositionSearchWindow() {
		let fieldFrame = self.screenCoordinates
		var windowFrame = self.searchResultsPanel.frame
		var rows = self.results.count
		if rows > self.maximumNumberOfResults {
			rows = self.maximumNumberOfResults
		} else if rows == 0 {
			rows = 1
		}
		
		windowFrame.size.height = CGFloat(rows) * self.searchResultsTableView.intercellSpacing.height + (0 ..< rows).sum({
			self.resultsDelegate?.searchField(self, heightOfRowFor: $0) ?? 0.0
		}) - 1.0
		windowFrame.size.width = self.searchResultsWidth
		windowFrame.origin.x = fieldFrame.maxX - windowFrame.width
		windowFrame.origin.y = fieldFrame.minY - windowFrame.height
		
		self.searchResultsPanel.setFrame(windowFrame, display: true)
		
		self.searchResultsTableView.tableColumns[0].width = windowFrame.width - 3.0
	}
	
	/// Invoked from the _delayedSearchTimer since.
	@objc private func _search() {
		_lock.perform {
			self.progressIndicator.stopAnimation(nil)
			
			_delayedSearchTimer = nil
			
			if _isSearchInProgress {
				self.resultsDelegate?.searchField(didCancelCurrentSearch: self)
			}
			
			let actualSearchString = self.stringValue.trimmingWhitespace
			
			self._repositionSearchWindow()
			
			if _searchString == actualSearchString {
				/// The same string, bail out.
				return
			}
			
			_searchString = actualSearchString
			
			if _searchString.isEmpty {
				self.results.removeAll()
				self.hideSearchWindow()
				return
			}
			
			self.progressIndicator.startAnimation(nil)
			
			self.resultsDelegate?.searchField(self, didChangeQuery: _searchString, completionHandler: { (results) in
				XU_PERFORM_BLOCK_ON_MAIN_THREAD {
					self.progressIndicator.stopAnimation(nil)
					
					if self._searchString != actualSearchString {
						/// The user has already started a different query.
						return
					}
					
					self._lock.perform(locked: {
						self._isSearchInProgress = false
						self._setSearchResult(results)
					})
				}
			})
		}
	}
	
	/// Selects a search result at row.
	private func _selectSearchResult(at row: Int) {
		self.stringValue = ""
		self.resignFirstResponder()
		
		self.hideSearchWindow()
		
		_searchString = ""
		
		self.resultsDelegate?.searchField(self, didSelectResult: self.results[row])
	}
	
	/// Used as doubleAction on the table view.
	@objc private func _selectSearchResult(_ tableView: NSTableView) {
		let clickedRow = tableView.clickedRow
		if clickedRow == -1 {
			return
		}
		
		self._selectSearchResult(at: clickedRow)
	}
	
	/// Sets search results. Asserts that this is called on main thread.
	private func _setSearchResult(_ items: [Any]) {
		assert(Thread.isMainThread)
		
		self.results = items
	}
	
	public override func awakeFromNib() {
		super.awakeFromNib()
		
		self.target = self
		self.action = #selector(search(_:))
		
		_searchFieldCancelCell = (self.cell as? NSSearchFieldCell)?.cancelButtonCell
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	/// Hides search window.
	public func hideSearchWindow() {
		self.window!.removeChildWindow(self.searchResultsPanel)
		self.searchResultsPanel.orderOut(nil)
		
		XUApp.unregisterArrowKeyEventsObserver()
	}
	
	public override func layout() {
		super.layout()
		
		if #available(OSX 10.11, *) {
			self.progressIndicator.frame = self.rectForCancelButton(whenCentered: false)
		} else {
			var frame = self.progressIndicator.frame
			frame = self.frame.centerRect(frame)
			frame.origin.x = self.bounds.width - frame.width - 5.0
			self.progressIndicator.frame = frame
		}
	}
	
	/// This is self.action - this gets called when the search changes the query.
	@objc private func search(_ sender: Any?) {
		_lock.perform { () -> Void in
			_delayedSearchTimer?.invalidate()
			_delayedSearchTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(_search), userInfo: nil, repeats: false)
		}
	}
	
	/// Selects the result that is currently selected.
	fileprivate func select(_ sender: NSEvent) {
		let row = self.searchResultsTableView.selectedRow
		if row < 0 || row >= self.results.count {
			return
		}
		
		self._selectSearchResult(at: row)
	}
	
	/// Force-displays the search window.
	public func showSearchWindow() {
		if XUApp.isRunningInModalMode {
			return
		}
		
		self._repositionSearchWindow()
		self.searchResultsPanel.orderFront(nil)
		
		if self.searchResultsPanel.parent == nil {
			self.window!.addChildWindow(self.searchResultsPanel, ordered: .above)
		}
		
		XUApp.registerArrowKeyEventsObserver(self)
	}
	
	public override func viewDidMoveToWindow() {
		super.viewDidMoveToWindow()
		
		NotificationCenter.default.addObserver(self, selector: #selector(_repositionSearchWindow), name: .NSWindowDidResize, object: self.window)
	}
	
}

extension XUSearchFieldWithResults: NSTableViewDataSource, NSTableViewDelegate {
	
	public func numberOfRows(in tableView: NSTableView) -> Int {
		return self.results.count
	}
	
	public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return self.resultsDelegate?.searchField(self, heightOfRowFor: self.results[row]) ?? 0.0
	}
	
	public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		return self.resultsDelegate?.searchField(self, tableView: tableView, viewForColumn: tableColumn, andResult: self.results[row])
	}
	
	public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
		return self.resultsDelegate?.searchField(self, tableView: tableView, rowViewFor: self.results[row])
	}
	
	public func tableViewSelectionDidChange(_ notification: Notification) {
		let selectedIndex = self.searchResultsTableView.selectedRow
		if selectedIndex == -1 {
			return
		}
		
		let result = self.results[selectedIndex]
		
		guard let resultName = self.resultsDelegate?.searchField(self, accessibilityValueFor: result) else {
			return
		}
		if let mainWindow = self.window {
			NSAccessibilityPostNotificationWithUserInfo(mainWindow, NSAccessibilityAnnouncementRequestedNotification, [NSAccessibilityAnnouncementKey: resultName])
		}
	}
}

extension XUSearchFieldWithResults: XUArrowKeyEventsObserver {
	
	
	public func cancelationKeyWasPressed(_ event: NSEvent) {
		// no-op
	}
	
	public func confirmationKeyWasPressed(_ event: NSEvent) {
		self.select(event)
	}
	
	public func keyDownWasPressed(_ event: NSEvent) {
		var row = self.searchResultsTableView.selectedRow
		if row != self.searchResultsTableView.numberOfRows - 1 {
			row += 1
		}
		
		self.searchResultsTableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
		self.searchResultsTableView.scrollRowToVisible(row)
	}
	
	public func keyUpWasPressed(_ event: NSEvent) {
		var row = self.searchResultsTableView.selectedRow
		if row != 0 {
			row -= 1
		}
		
		self.searchResultsTableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
		self.searchResultsTableView.scrollRowToVisible(row)
	}
	
	public var observeEvenWhenEditing: Bool {
		return true
	}
	
}
