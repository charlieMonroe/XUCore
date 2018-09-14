//
//  XUOneShotPopoverManager.swift
//  XUCore
//
//  Created by Charlie Monroe on 9/11/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import AppKit

/// A manager for one-shot popovers. Automatically manages lifetime of the popovers.
/// You must not set a delegate on the popover object as it relies on it being
/// the popover's delegate.
public final class XUOneShotPopoverManager: NSObject, NSPopoverDelegate {
	
	/// Shared manager.
	public static let shared: XUOneShotPopoverManager = XUOneShotPopoverManager()
	
	
	/// Popovers.
	private var _popovers: [NSPopover] = []

	
	public func popoverWillClose(_ notification: Notification) {
		guard let popover = notification.object as? NSPopover, let index = _popovers.firstIndex(of: popover) else {
			return
		}
		
		_popovers.remove(at: index)
	}
	
	/// Registers a popover. It creates a strong reference to it and once the popover
	/// is closed, the manager removes the reference.
	public func registerPopover(_ popover: NSPopover) {
		popover.delegate = self
		_popovers.append(popover)
	}
	
	
}
