//
//  XUCloudKitSynchronization+Error.swift
//  XUCore
//
//  Created by Charlie Monroe on 3/9/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import Foundation

@available(iOSApplicationExtension, unavailable)
extension XUCloudKitSynchronization {
	
	/// Error domain used.
	static let errorDomain: String = "XUCloudKitSynchronizationErrorDomain"
	
	/// Struct gathering error codes.
	enum ErrorCode: Int {
		
		/// Failed to list sync devices.
		case failedToListDevices = 1
		
		/// Failed to download sync changes.
		case failedToDownloadChanges = 2
		
		/// Fails to apply a change. This is a soft error.
		case failedToApplyChange = 3
		
		/// Fails to upload a change.
		case failedToUploadChange = 4
		
		
		/// Localized description of the error. TODO: Currently unlocalized.
		var localizedDescription: String {
			switch self {
			case .failedToListDevices:
				return "Failed to list devices with which to synchronize."
			case .failedToDownloadChanges:
				return "Failed to download synchronization changes."
			case .failedToApplyChange:
				return "Failed to apply a change."
			case .failedToUploadChange:
				return "Failed to upload a change."
			}
		}
		
	}
	
	/// Synchronization error.
	class SynchronizationError: NSError {
		
		/// Designated initializer. Automatically adds localized error failure
		/// reason, etc.
		init(errorCode: ErrorCode, failureReason: String? = nil, underlyingError: Error? = nil) {
			var info: [String : Any] = [
				NSLocalizedDescriptionKey: errorCode.localizedDescription
			]
			info[NSUnderlyingErrorKey] = underlyingError
			info[NSLocalizedFailureReasonErrorKey] = failureReason
			super.init(domain: XUCloudKitSynchronization.errorDomain, code: errorCode.rawValue, userInfo: info)
		}
		
		required init?(coder aDecoder: NSCoder) {
			super.init(coder: aDecoder)
		}
		
	}
	
}
