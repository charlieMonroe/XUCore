//
//  XUSynchronousDataLoader.swift
//  XUCore
//
//  Created by Charlie Monroe on 3/21/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Synchronous data loader. This class will synchronously load data from the
/// request using the session.
public final class XUSynchronousDataLoader {
	
	private var data: Data?
	private let lock = NSConditionLock(condition: 0)
	private var response: URLResponse?
	private var error: Error?

	
	/// Request to be loaded.
	public let request: URLRequest
	
	/// Session to be used for the data load.
	public let session: URLSession
	
	/// Designated initializer. Session defaults to NSURLSession.sharedSession().
	public init(request: URLRequest, session: URLSession = URLSession.shared) {
		self.request = request
		self.session = session
	}
	
	/// Loads data from self.request and either throws, or returns a tuple of
	/// Data and URLResponse?. Note that the response can indeed be nil even
	/// if the data part is nonnil.
	///
	/// IMPORTANT: This method asserts that the current queue != delegateQueue of
	/// self.session, which usually is the main queue. It is important not to
	/// invoke this method in such manner since it would lead to a deadlock.
	public func loadData() throws -> (data: Data, response: URLResponse?) {
		XUAssert(OperationQueue.current != self.session.delegateQueue,
			   "Can't be loading data on the same queue as is the session's delegate queue!")
				
		self.session.dataTask(with: self.request, completionHandler: { [weak self] in
			self?.data = $0
			self?.response = $1
			self?.error = $2
			
			self?.lock.lock(whenCondition: 0)
			self?.lock.unlock(withCondition: 1)
		}).resume()
		
		self.lock.lock(whenCondition: 1)
		self.lock.unlock(withCondition: 0)
		
		if let error = self.error {
			throw error
		}
		
		guard let data = self.data, let response = self.response else {
			throw NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: XULocalizedString("Unknown error.")
			])
		}
		return (data, response)
	}
	
	/// Loads just the data. Useful in case we're not interested in any errors.
	public func loadRawData() -> Data? {
		return (try? self.loadData())?.data
	}
	
}
