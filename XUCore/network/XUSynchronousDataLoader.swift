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
	
	/// Response that contains data and a response.
	public struct Response {
		public let data: Data
		public let response: URLResponse
	}
	
	private var _task: URLSessionDataTask!
	
	private var _data: Data?
	private let _lock: NSConditionLock = NSConditionLock(condition: 0)
	private var _response: URLResponse?
	private var _error: Error?

	
	/// Request to be loaded.
	public let request: URLRequest
	
	/// Session to be used for the data load.
	public let session: URLSession
	
	private func _processResponse(_ data: Data?, response: URLResponse?, error: Error?) {
		_data = data
		_response = response
		_error = error
		
		_lock.lock(whenCondition: 0)
		_lock.unlock(withCondition: 1)
	}
	
	/// Designated initializer. Session defaults to NSURLSession.sharedSession().
	public init(request: URLRequest, session: URLSession = URLSession.shared) {
		self.request = request
		self.session = session
		
		_task = self.session.dataTask(with: request, completionHandler: { [weak self] in
			self?._processResponse($0, response: $1, error: $2)
		})
	}
	
	/// Loads data from self.request and either throws, or returns a tuple of
	/// Data and URLResponse?. Note that the response can indeed be nil even
	/// if the data part is nonnil.
	///
	/// IMPORTANT: This method asserts that the current queue != delegateQueue of
	/// self.session, which usually is the main queue. It is important not to
	/// invoke this method in such manner since it would lead to a deadlock.
	public func loadData() throws -> Response {
		XUAssert(OperationQueue.current != self.session.delegateQueue,
			   "Can't be loading data on the same queue as is the session's delegate queue!")
				
		_task.resume()
		
		_lock.lock(whenCondition: 1)
		_lock.unlock(withCondition: 0)
		
		if let error = _error {
			throw error
		}
		
		guard let data = _data, let response = _response else {
			throw NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [
				NSLocalizedFailureReasonErrorKey: Localized("Unknown error.")
			])
		}
		
		return Response(data: data, response: response)
	}
	
	/// Loads just the data. Useful in case we're not interested in any errors.
	public func loadRawData() -> Data? {
		return (try? self.loadData())?.data
	}
	
}
