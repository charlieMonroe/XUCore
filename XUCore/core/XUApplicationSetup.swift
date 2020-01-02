//
//  XUApplicationSetup.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#if os(macOS)
	import AppKit
#endif
import Foundation

private func _createURL(forKey key: String, inInfoDictionary infoDictionary: [String : Any]) -> URL? {
	if let urlString = infoDictionary[key] as? String {
		let url = URL(string: urlString)
		if url == nil {
			// URL creation failed, report this to the user
			// Don't use XULog here, since this is called from XUAppSetup.init
			// and XULog accesses XUAppSetup when it initializes.
			print("\(key) contains a nonnull value, but it doesn't seem to be a proper URL '\(urlString)'")
		}
		return url
	} else {
		return nil
	}
}

/// Shorthand for XUAppSetup
public var XUAppSetup: XUApplicationSetup {
	return XUApplicationSetup.shared
}


/// This class contains several variables containing some of the information in
/// the main bundle's Info.plist. You can go through the variables and see what
/// information needs to be entered under which key to modify the app's behavior.
///
/// If you need your own:
///		- subclass the setup
///		- override init()
///		- enter the class name into Info.plist under the key XUApplicationSetupClass
///		- provide your own static var that casts sharedSetup to your own. Example:
///
/// class XUMyAppSetup: XUApplicationSetup {
///
///		class var myAppSetup: XUMyAppSetup { 
///			return XUAppSetup as! XUMyAppSetup
///		}
///
/// }
///
open class XUApplicationSetup {
	
	/// Returns the shared setup.
	public static let shared: XUApplicationSetup = {
		let infoDictionary = Bundle.main.infoDictionary ?? [:]
		let setupClass: XUApplicationSetup.Type
		if let className = infoDictionary["XUApplicationSetupClass"] as? String {
			guard let genericClass = NSClassFromString(className) else {
				fatalError("Cannot find class named \(className) for XUApplicationSetup subclass.")
			}
			
			guard let specializedClass = genericClass as? XUApplicationSetup.Type else {
				fatalError("Class \(genericClass) is not a subclass of XUApplicationSetup.")
			}
			
			setupClass = specializedClass
		} else {
			setupClass = XUApplicationSetup.self
		}
		
		return setupClass.init(infoDictionary: infoDictionary)
	}()
	
	
	/// This is a struct that represents a build type, used for XUAppSetup.buildType.
	/// There are several reserved values that are used by XUCore:
	///
	/// - Trial - implies isAppStoreBuild == false
	/// - AppStore - implies isAppStoreBuild == true
	public struct BuildType: RawRepresentable {
		
		/// AppStore build type.
		public static let appStore: BuildType = BuildType(rawValue: "AppStore")
		
		/// Trial build type.
		public static let trial: BuildType = BuildType(rawValue: "Trial")
		
		
		public var rawValue: String
		
		public init(rawValue: String) {
			self.rawValue = rawValue
		}
		
		/// Returns whether self == .appStore
		public var isAppStore: Bool {
			return self == .appStore
		}
		
		/// Returns whether self == .trial
		public var isTrial: Bool {
			return self == .trial
		}
		
	}
	
	
	
	/// Returns the application build number - found under CFBundleVersion 
	/// in Info.plist. "0" by default.
	public let applicationBuildNumber: String
	
	/// This is an identifier of the app. By default, it is main bundle's bundle
	/// identifier and if it is null, process name is used.
	public let applicationIdentifier: String
	
	/// Application state provider. Note that there is a strong reference kept
	/// to the object. By default, this contains XUBasicApplicationStateProvider.
	/// In case you don't want it, you can set it to nil.
	public var applicationStateProvider: XUApplicationStateProvider? = XUBasicApplicationStateProvider()
	
	/// Returns the application version number - found under CFBundleShortVersionString
	/// in Info.plist. "1.0" by default.
	public let applicationVersionNumber: String
	
	/// If isBetaBuild, this is the time interval after which the beta expires.
	/// By default, this is 7 days, but can be customized using XUBetaExpiration
	/// key. If you enter 0, the betas never expires.
	///
	/// @discussion - Only available on OS X.
	public let betaExpirationTimeInterval: TimeInterval
	
	/// Build date - this is optional. You can add custom build phase to add
	/// XUBuildDate key to the Info.plist.
	public let buildDate: Date?
	
	/// Build type. See BuildType. When you use the buildType, you should ignore
	/// isAppStoreBuild on XUApplicationSetup.
	///
	/// The value in Info.plist should be a string under the key XUBuildType.
	public let buildType: BuildType
	
	/// Returns a URL object that contains a URL where exception report is sent
	/// by XUExceptionReporter. To turn on the XUExceptionCatcher, fill the URL
	/// under the key XUExceptionReporterURL in Info.plist. See XUExceptionReporter
	/// for more information.
	public let exceptionHandlerReportURL: URL?
	
	/// Returns an identifier that's used by XUDocumentSyncManager as CloudKit
	/// container. See XUDocumentSyncManager for more information. The value
	/// must be stored under the key XUCloudKitSynchronizationContainerIdentifier.
	public let iCloudSynchronizationContainerIdentifier: String?
	
	/// Returns true, if the current build is made for AppStore submission. To
	/// allow this, enter a boolean into Info.plist under key XUAppStoreBuild.
	/// True by default.
	///
	/// @see also buildType.
	///
	/// @discussion - Probably one of the alternatives would be to make an enum
	///				  of build types. Unfortunately, we can think of all of the
	///				  combinations of AppStore-Beta builds, which would not be
	///				  a nice solution. Hence these options are separated.
	public let isAppStoreBuild: Bool
	
	/// Returns true if the Info.plist contains a true boolean under the key
	/// XUBetaBuild. When true, the XUCore framework automatically handles
	/// beta expiration. False by default. See betaExpirationTimeInterval.
	public let isBetaBuild: Bool
	
	#if os(macOS)
	/// Returns true if the Dark Mode for menu bar and Dock is enabled. Will always
	/// return false on iOS.
	@available(iOS, unavailable)
	@available(macCatalyst, unavailable)
	public var isDarkModeEnabled: Bool {
		if #available(macOS 10.14, *) {
			let bestMatch = NSAppearance.current.bestMatch(from: [.darkAqua, .vibrantDark])
			return bestMatch != nil
 		}
		return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
	}
	#endif

	/// Returns true, if the app is debugging in-app purchases. When true, the
	/// XUInAppPurchasesManager will return all available IAPs as purchased. To
	/// enabled this mode, edit the scheme of your project and add "--iap-debug" 
	/// to the arguments list to enable it.
	public let isDebuggingInAppPurchases: Bool
	
	#if os(iOS)
	/// Marked as true if we're running from TestFlight installation.
	public let isInstalledFromTestFlight: Bool
	#endif
	
	/// Returns true, if the app is being run in debug mode. Unlike Objective-C,
	/// where #if DEBUG macro can be applied, in Swift, this is a bit more
	/// complicated - edit the scheme of your project and add "--debug" to the
	/// arguments list to enable it.
	public let isRunningInDebugMode: Bool
	
	#if os(macOS)
	/// Returns true if we're running Mojave or later and dark mode is enabled.
	@available(iOS, unavailable)
	@available(macCatalyst, unavailable)
	public var isRunningMojaveWithDarkMode: Bool {
		if #available(macOS 10.14, *) {
			return self.isDarkModeEnabled
		} else {
			return false
		}
	}
	#endif
	
	/// An identifier of the app for message center. By default, 
	/// self.applicationIdentifier is used, but can be customized by defining
	/// XUMessageCenterAppIdentifier in Info.plist.
	public let messageCenterAppIdentifier: String
	
	/// Returns a URL object that contains a URL to the message feed handled
	/// by XUMessageCenter. To turn on the XUMessageCenter, fill the URL under
	/// the key XUMessageCenterFeedURL in Info.plist.
	public let messageCenterFeedURL: URL?
	
	/// Returns a URL object that contains a URL to your support page. Required
	/// by XUTrial. Fill the URL under the key XUSupportURL in Info.plist.
	public let supportURL: URL?
	
	/// The initializer gets the main bundle's infoDictionary.
	public required init(infoDictionary: XUJSONDictionary) {
		
		if let buildType = infoDictionary["XUBuildType"] as? String {
			if buildType == BuildType.appStore.rawValue {
				self.buildType = BuildType.appStore
				self.isAppStoreBuild = true
			} else if buildType == BuildType.trial.rawValue {
				self.buildType = BuildType.trial
				self.isAppStoreBuild = false
			} else {
				self.buildType = BuildType(rawValue: buildType)
				self.isAppStoreBuild = infoDictionary.boolean(forKey: "XUAppStoreBuild")
			}
		} else if let appStoreBuild = infoDictionary["XUAppStoreBuild"] as? NSNumber {
			self.isAppStoreBuild = appStoreBuild.boolValue
			self.buildType = self.isAppStoreBuild ? BuildType.appStore : BuildType.trial
		} else {
			self.isAppStoreBuild = true
			self.buildType = BuildType.appStore
		}
		
		if let betaBuild = infoDictionary["XUBetaBuild"] as? NSNumber {
			self.isBetaBuild = betaBuild.boolValue
		} else {
			self.isBetaBuild = false
		}
		
		if let betaExpirationTimeInterval = infoDictionary["XUBetaExpiration"] as? NSNumber, betaExpirationTimeInterval.doubleValue > 0.0 {
			self.betaExpirationTimeInterval = betaExpirationTimeInterval.doubleValue
		} else {
			self.betaExpirationTimeInterval = 7.0 * XUTimeInterval.day
		}
		
		
		self.applicationBuildNumber = infoDictionary["CFBundleVersion"] as? String ?? "0"
		self.applicationVersionNumber = infoDictionary["CFBundleShortVersionString"] as? String ?? "1.0"
		
		self.buildDate = infoDictionary["XUBuildDate"] as? Date
		
		self.exceptionHandlerReportURL = _createURL(forKey: "XUExceptionReporterURL", inInfoDictionary: infoDictionary)
		self.messageCenterFeedURL = _createURL(forKey: "XUMessageCenterFeedURL", inInfoDictionary: infoDictionary)
		self.supportURL = _createURL(forKey: "XUSupportURL", inInfoDictionary: infoDictionary)
		
		
		let appIdentifier = Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName
		self.applicationIdentifier = appIdentifier
		self.messageCenterAppIdentifier = (infoDictionary["XUMessageCenterAppIdentifier"] as? String) ?? appIdentifier
		
		self.iCloudSynchronizationContainerIdentifier = infoDictionary["XUCloudKitSynchronizationContainerIdentifier"] as? String
		
		self.isRunningInDebugMode = ProcessInfo.processInfo.arguments.contains("--debug")
		self.isDebuggingInAppPurchases = ProcessInfo.processInfo.arguments.contains("--iap-debug")
		
		#if os(iOS)
			if let receiptURL = Bundle.main.appStoreReceiptURL, receiptURL.path.contains("sandboxReceipt") {
				self.isInstalledFromTestFlight = true
			} else {
				self.isInstalledFromTestFlight = false
			}
		#endif
	}
	
}

