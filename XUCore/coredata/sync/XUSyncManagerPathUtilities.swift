//
//  XUSyncManagerPathUtilities.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/23/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

#if os(macOS)
	import IOKit
	private let _cachedID: String = {
		let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
		assert(platformExpert != 0, "Failed to obtain computer UUID.")
		
		var serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, "IOPlatformSerialNumber" as CFString, kCFAllocatorDefault, 0).takeRetainedValue()
		
		IOObjectRelease(platformExpert)
		
		guard let uuidString = serialNumberAsCFString as? String else {
			fatalError("Can't get computer UUID.")
		}
		
		// Put in the user salt as well - we may have two users on the same computer
		let deviceID = uuidString + NSUserName()
		return deviceID.md5Digest.uppercased()
	}()
#endif

internal struct XUSyncManagerPathUtilities {
	
	static var currentDeviceIdentifier: String = {
		#if os(iOS)
			#if targetEnvironment(simulator)
				/// Simulator changes vendor ID each run.
				return Bundle.main.bundleURL.path.components(separatedBy: "data/Containers/Bundle")[0].md5Digest.uppercased()
			#else
				return UIDevice.current.identifierForVendor!.uuidString.uppercased()
			#endif
		#else
			return _cachedID
		#endif
	}()
	
	/// Returns the device specific folder for the document -
	/// SYNC_ROOT/DOC_UUID/DEV_UUID.
	static func deviceSpecificFolderURL(for syncManager: XUApplicationSyncManager, deviceID: String, documentID: String) -> URL! {
		return self.documentFolderURL(for: syncManager, documentUUID: documentID)?.appendingPathComponent(deviceID)
	}
	
	/// Returns the document folder - SYNC_ROOT/DOC_UUID. */
	static func documentFolderURL(for syncManager: XUApplicationSyncManager, documentUUID UUID: String) -> URL! {
		return syncManager.syncRootFolderURL?.appendingPathComponent(UUID)
	}
	
	/// Returns the Info.plist for particular document's whole store - 
	/// SYNC_ROOT/DOC_UUID/DEV_UUID/whole_store/Info.plist.
	static func entireDocumentInfoFileURL(for syncManager: XUApplicationSyncManager, deviceID: String, documentID: String) -> URL! {
		return self.entireDocumentFolderURL(for: syncManager, deviceID: deviceID, documentID: documentID)?.appendingPathComponent("Info.plist")
	}
	
	/// Returns the store for the dev's doc whole-upload store folder - 
	/// SYNC_ROOT/DOC_UUID/DEV_UUID/whole_store.
	static func entireDocumentFolderURL(for syncManager: XUApplicationSyncManager, deviceID: String, documentID: String) -> URL! {
		return self.deviceSpecificFolderURL(for: syncManager, deviceID: deviceID, documentID: documentID)?.appendingPathComponent("whole_store")
	}
		
}
