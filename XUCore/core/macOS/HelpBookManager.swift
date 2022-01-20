//
//  HelpBookManager.swift
//  XUCore
//
//  Created by Charlie Monroe on 8/18/21.
//  Copyright © 2021 Charlie Monroe Software. All rights reserved.
//

import AppKit
import Carbon.Help // Required for AHGotoPage
import Foundation

/// Help book manager - it automatically registers help books in the main bundle
/// and provides Swift UI for some additional methods that are provided via Carbon.
///
/// Additionally, if you specify XUHelpAnchorScheme in Info.plist of the main app
/// and define this scheme, the manager can handle these links - see canHandleURL(_:)
/// and handleURL(_:) methods.
public final class HelpBookManager {
	
	/// Shared manager.
	public static let shared: HelpBookManager = HelpBookManager()
	
	/// Defines constant for XUHelpAnchorScheme. See class documentation
	/// and canHandleURL(_:) and handleURL(_:) methods.
	public static let anchorHandlingURLSchemeKey: String = "XUHelpAnchorScheme"
	
	/// The required anchor handling URL scheme.
	public let anchorHandlingURLScheme: String?
	
	/// Default book identifier. Loads CFBundleHelpBookName value from app's Info.plist.
	public private(set) lazy var defaultBookIdentifier: String? = {
		return Bundle.main.infoDictionary?["CFBundleHelpBookName"] as? String
	}()
	
	/// Default book bundle name. Loads CFBundleHelpBookFolder value from app's Info.plist.
	public private(set) lazy var defaultBookBundleName: String? = {
		return Bundle.main.infoDictionary?["CFBundleHelpBookFolder"] as? String
	}()
	
	/// Returns a bundle of the help book.
	public private(set) lazy var defaultBookBundle: Bundle? = {
		guard let bundleName = self.defaultBookBundleName else {
			return nil
		}
		return Bundle.main.url(forResource: bundleName, withExtension: nil).flatMap(Bundle.init(url:))
	}()
	
	
	/// Returns whether it can handle a particular URL. This URL needs to have the scheme specified
	/// by XUHelpAnchorScheme in Info.plist (see anchorHandlingURLScheme)
	public func canHandleURL(_ url: URL) -> Bool {
		guard
			url.scheme == self.anchorHandlingURLScheme,
			let domain = url.host, !domain.isEmpty
		else {
			return false
		}
		
		return true
	}
	
	/// Handles help anchor URL, if possible. Returns false if the URL was not valid. It invokes
	/// openPage(named:) with default parameters.
	@discardableResult
	public func handleURL(_ url: URL) -> Bool {
		guard self.canHandleURL(url), let host = url.host else {
			return false
		}
		
		return self.openPage(named: host)
	}
	
	
	/// Opens help root.
	public func openHelp() {
		self.openPage(named: "index")
	}
	
	/// Opens a page with a name in a particular help book. The book identifiier is by default taken
	/// from main bundle's help book name. The page name should not include the extension, `.html`
	/// is used automatically. If you need to specify a different extension, override the pathExtension
	/// parameter.
	///
	/// Example: openPage(named: "custom_integrations")
	@discardableResult
	public func openPage(named pageName: String, pathExtension: String = "html", in bookIdentifier: String? = nil) -> Bool {
		guard let identifier = bookIdentifier ?? self.defaultBookIdentifier else {
			return false
		}
		
		// Prefer directly opening the file with Help Viewer. It bypasses potential
		// help cache issues that have been encountered.
		
		if
			let bundle = self.defaultBookBundle,
			let url = bundle.url(forResource: pageName, withExtension: pathExtension)
		{
			HelpBookViewerWindowController.shared.openHTML(at: url)
			return true
		}
		
		
		return AHGotoPage(identifier as CFString, (pageName + ".html") as CFString, nil) == 0
	}
	
	private init() {
		self.anchorHandlingURLScheme = Bundle.main.infoDictionary?[HelpBookManager.anchorHandlingURLSchemeKey] as? String
		
		if Bundle.main.infoDictionary?["CFBundleHelpBookName"] == nil {
			// Do not register help books if there are none.
			return
		}
		
		if !NSHelpManager.shared.registerBooks(in: .main) {
			XULog("Failed to register books in main bundle.")
		}
	}
	
}
