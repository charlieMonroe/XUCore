//
//  XUView+Crawler.swift
//  XUCore
//
//  Created by Charlie Monroe on 7/13/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Crawler for view hierarchy. You start with a view and craw through the entire
/// view hierarchy. This is useful for finding some particular view in the hierarchy,
/// or just for debugging purposes. Note that during iteration over the view hierarchy
/// you shouldn't modify it. If it's modified, some views may be iterated over
/// multiple times or may be skipped.
public struct XUViewCrawler: Sequence {
	
	public typealias Iterator = XUViewCrawlerGenerator
	
	/// View that this was initialized with.
	public let view: __XUBridgedView
	
	public init(view: __XUBridgedView) {
		self.view = view
	}
	
	public func makeIterator() -> XUViewCrawlerGenerator {
		return XUViewCrawlerGenerator(view: self.view)
	}
	
}

/// Generator for XUViewCrawler.
public class XUViewCrawlerGenerator: IteratorProtocol {
	
	public typealias Element = __XUBridgedView
	
	/// Current view.
	public var currentView: __XUBridgedView?
	
	/// The view we're crawling.
	public let view: __XUBridgedView
	
	private func _leaf(for view: __XUBridgedView) -> __XUBridgedView {
		if view.subviews.isEmpty {
			return view
		}
		
		return self._leaf(for: view.subviews[0])
	}
	
	/// Returns next element.
	public func next() -> __XUBridgedView? {
		guard let currentView = self.currentView else {
			self.currentView = self._leaf(for: self.view)
			if self.currentView == self.view {
				return nil // It was empty.
			}
			
			// If the view was empty, nil is returned, otherwise, the first view
			// is returned.
			return self.currentView
		}
		
		// We go back:
		guard let superview = currentView.superview else {
			// Detached view?
			return nil
		}
		
		guard let index = superview.subviews.firstIndex(of: currentView) else {
			// This shouldn't really happen.
			return nil
		}
		
		guard index < superview.subviews.count - 1 else {
			// This is the last subview of the superview. We return the superview (crawling up).
			if superview == self.view {
				// End.
				return nil
			} else {
				self.currentView = superview
				return superview
			}
		}
		
		// The next subview.
		let nextSubview = superview.subviews[index + 1]
		
		// We need to get the leaf.
		let leaf = self._leaf(for: nextSubview)
		self.currentView = leaf
		return leaf
	}
	
	/// Initializes with a string.
	public init(view: __XUBridgedView) {
		self.view = view
	}
	
}


