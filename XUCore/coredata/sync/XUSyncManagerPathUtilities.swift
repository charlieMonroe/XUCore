//
//  XUSyncManagerPathUtilities.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/23/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Convenience function that returns XUSyncManagerPathUtilities.currentDeviceIdentifier
internal func XU_SYNC_DEVICE_ID() -> String {
	return XUSyncManagerPathUtilities.currentDeviceIdentifier
}

#if os(OSX)
	import IOKit
	private let _cachedID: String = {
		let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
		assert(platformExpert != 0, "Failed to obtain computer UUID.")
		
		var serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, "IOPlatformSerialNumber", kCFAllocatorDefault, 0).takeRetainedValue()
		
		IOObjectRelease(platformExpert)
		
		guard let UUIDString = serialNumberAsCFString as? String else {
			fatalError("Can't get computer UUID.")
		}
		
		// Put in the user salt as well - we may have two users on the same computer
		let computerID = UUIDString + NSUserName()
		return computerID.MD5Digest.uppercaseString
	}()
#endif

internal class XUSyncManagerPathUtilities {
	
	static var currentDeviceIdentifier: String = {
		#if os(iOS)
			#if (arch(i386) || arch(x86_64)) && os(iOS)
				/// Simulator changes vender ID each run.
				return NSBundle.mainBundle().bundleURL.path!.componentsSeparatedByString("data/Containers/Bundle")[0].MD5Digest.uppercaseString
			#else
				return UIDevice.currentDevice().identifierForVendor!.UUIDString.uppercaseString
			#endif
		#else
			return _cachedID
		#endif
	}()
	
	/// Returns the device specific folder for the document -
	/// SYNC_ROOT/DOC_UUID/DEV_UUID.
	class func deviceSpecificFolderURLForSyncManager(syncManager: XUApplicationSyncManager, computerID: String, andDocumentUUID UUID: String) -> NSURL! {
		return self.documentFolderURLForSyncManager(syncManager, andDocumentUUID: UUID)?.URLByAppendingPathComponent(computerID)
	}
	
	/// Returns the document folder - SYNC_ROOT/DOC_UUID. */
	class func documentFolderURLForSyncManager(syncManager: XUApplicationSyncManager, andDocumentUUID UUID: String) -> NSURL! {
		return syncManager.syncRootFolderURL?.URLByAppendingPathComponent(UUID)
	}
	
	/// Returns the Info.plist for particular document's whole store - 
	/// SYNC_ROOT/DOC_UUID/DEV_UUID/whole_store/Info.plist.
	class func entireDocumentInfoFileURLForSyncManager(syncManager: XUApplicationSyncManager, computerID: String, andDocumentUUID UUID: String) -> NSURL! {
		return self.entireDocumentFolderURLForSyncManager(syncManager, computerID: computerID, andDocumentUUID: UUID)?.URLByAppendingPathComponent("Info.plist")
	}
	
	/// Returns the store for the dev's doc whole-upload store folder - 
	/// SYNC_ROOT/DOC_UUID/DEV_UUID/whole_store.
	class func entireDocumentFolderURLForSyncManager(syncManager: XUApplicationSyncManager, computerID: String, andDocumentUUID UUID: String) -> NSURL! {
		return self.deviceSpecificFolderURLForSyncManager(syncManager, computerID: computerID, andDocumentUUID: UUID)?.URLByAppendingPathComponent("whole_store")
	}
	
	/// Returns the URL of the Info.plist that contains information about last 
	/// timestamp read by this computer. - 
	/// SYNC_ROOT/DOC_UUID/DEV_UUID/sync_store/stamps/THIS_DEV_UUID.plist.
	class func persistentSyncStorageInfoURLForSyncManager(syncManager: XUApplicationSyncManager, computerID: String, andDocumentUUID UUID: String) -> NSURL! {
		return self.timestampsDirectoryURLForSyncManager(syncManager, computerID: computerID, andDocumentUUID: UUID)?.URLByAppendingPathComponent("\(self.currentDeviceIdentifier).plist")
	}
	
	/// Returns the URL of folder where the document sync manager keeps its sync 
	/// data. - SYNC_ROOT/DOC_UUID/DEV_UUID/sync_store.
	class func persistentSyncStorageFolderURLForSyncManager(syncManager: XUApplicationSyncManager, computerID: String, andDocumentUUID UUID: String) -> NSURL! {
		return self.deviceSpecificFolderURLForSyncManager(syncManager, computerID: computerID, andDocumentUUID: UUID)?.URLByAppendingPathComponent("sync_store")
	}
	
	/// Returns the URL of the actual SQL databse where sync manager keeps its
	/// sync data. - SYNC_ROOT/DOC_UUID/DEV_UUID/sync_store/persistent_store.sql.
	class func persistentSyncStorageURLForSyncManager(syncManager: XUApplicationSyncManager, computerID: String, andDocumentUUID UUID: String) -> NSURL! {
		return self.persistentSyncStorageFolderURLForSyncManager(syncManager, computerID: computerID, andDocumentUUID: UUID)?.URLByAppendingPathComponent("persistent_store.sql")
	}
	
	/// Returns the URL of the folder that contains information about last timestamp
	/// read by computers. - SYNC_ROOT/DOC_UUID/DEV_UUID/sync_store/stamps.
	class func timestampsDirectoryURLForSyncManager(syncManager: XUApplicationSyncManager, computerID: String, andDocumentUUID UUID: String) -> NSURL! {
		return self.persistentSyncStorageFolderURLForSyncManager(syncManager, computerID: computerID, andDocumentUUID: UUID)?.URLByAppendingPathComponent("stamps")
	}
	
}
