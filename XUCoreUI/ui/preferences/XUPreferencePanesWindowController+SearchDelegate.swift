//
//  XUPreferencePanesWindowController+SearchDelegate.swift
//  XUCoreUI
//
//  Created by Charlie Monroe on 1/5/21.
//  Copyright © 2021 Charlie Monroe Software. All rights reserved.
//

import AppKit
import Foundation

extension XUPreferencePanesWindowController: XUSearchFieldWithResultsDelegate {
	
	private class RowView: NSTableRowView {
		
		let result: SearchResult
		
		init(result: SearchResult) {
			self.result = result
			
			super.init(frame: CGRect(x: 0.0, y: 0.0, width: 350.0, height: 24.0))
			
			let attributedString = NSMutableAttributedString(string: result.phrase, attributes: [
				.font: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize),
				.foregroundColor: NSColor.labelColor
			])
			
			attributedString.append(NSAttributedString(string: " – " + result.controller.paneName, attributes: [
				.font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
				.foregroundColor: NSColor.secondaryLabelColor
			]))
			
			let textField = NSTextField(labelWithAttributedString: attributedString)
			textField.translatesAutoresizingMaskIntoConstraints = false
			textField.lineBreakMode = .byTruncatingMiddle
			textField.usesSingleLineMode = true
			textField.setContentCompressionResistancePriority(.init(200.0), for: .horizontal)
			
			let view = self
			view.translatesAutoresizingMaskIntoConstraints = false
			view.addSubview(textField)
			view.addConstraints([
				NSLayoutConstraint(attribute: .height, item: view, constant: 24.0),
				NSLayoutConstraint(equalAttribute: .centerY, between: view, and: textField),
				NSLayoutConstraint(equalAttribute: .leading, between: view, and: textField, offset: -8.0)
			])

		}
		
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		
	}
	
	struct SearchResult {
		let controller: XUPreferencePaneViewController
		let phrase: String
		let priority: Int
	}
	
	public func searchField(didCancelCurrentSearch field: XUSearchFieldWithResults) {
		
	}
	
	public func searchField(_ field: XUSearchFieldWithResults, didChangeQuery query: String, completionHandler: @escaping ([Any]) -> ()) {
		guard query.count >= 3 else {
			completionHandler([])
			return
		}
		
		let controllers = self.sections.map(\.paneControllers).joined()
		var results: [SearchResult] = []
		for controller in controllers {
			let phrases = controller.searchablePhrases().filter({ $0.contains(caseInsensitive: query) })
			results += phrases.map({
				SearchResult(controller: controller, phrase: $0, priority: $0.starts(with: query) ? 0 : 1)
			})
		}
		
		completionHandler(results.sorted(using: \.priority))
	}
	
	public func searchField(_ field: XUSearchFieldWithResults, didSelectResult searchResult: Any) {
		guard let controller = (searchResult as? SearchResult)?.controller else {
			return
		}
		
		self.selectPane(controller)
	}
	
	public func searchField(_ field: XUSearchFieldWithResults, accessibilityValueFor searchResult: Any) -> String? {
		return (searchResult as? SearchResult)?.phrase
	}
	
	public func searchField(_ field: XUSearchFieldWithResults, heightOfRowFor searchResult: Any) -> CGFloat {
		return 24.0
	}
	
	public func searchField(_ field: XUSearchFieldWithResults, tableView: NSTableView, rowViewFor searchResult: Any) -> NSTableRowView {
		let result = searchResult as! SearchResult
		return RowView(result: result)
	}
	
	public func searchField(_ field: XUSearchFieldWithResults, tableView: NSTableView, viewForColumn tableColumn: NSTableColumn?, andResult searchResult: Any) -> NSView? {
		return nil
	}
	
	
}
