//
//  XUDownloadCenter+Async.swift
//  XUCore
//
//  Created by Charlie Monroe on 2/16/22.
//  Copyright © 2022 Charlie Monroe Software. All rights reserved.
//

import Foundation

extension XUDownloadCenter {

	public func downloadData(at url: URL, referringFunction: String = #function, acceptType: URLRequest.ContentType? = .defaultBrowser, requestModifier: URLRequestModifier = { _ in }) async throws -> Data {
		let request = try self._prepareRequest(for: url, referringFunction: referringFunction, acceptType: acceptType, requestModifier: requestModifier)
		do {
			let (data, response) = try await self.session.data(for: request)
			self.lastHTTPURLResponse = response as? HTTPURLResponse

			if self.logTraffic {
				XULog("[\(self.identifier)] - downloaded web site source from \(url), response: \(self.lastHTTPURLResponse.descriptionWithDefaultValue())")
			}

			self.observer?.downloadCenter(self, didDownloadContentFrom: url, response: response as? HTTPURLResponse, data: data)

			return data
		} catch {
			if self.logTraffic {
				XULog("[\(self.identifier)] - Failed to load URL \(url) - \(error)")
			}

			self.lastHTTPURLResponse = nil
			self.lastError = error

			self.observer?.downloadCenter(self, didFailToDownloadContentFrom: url, error: error)
			throw error
		}
	}

	/// Downloads the JSON and attempts to cast it to dictionary.
	public func downloadJSONDictionary(at url: URL, requestModifier: URLRequestModifier = { _ in }) async throws -> XUJSONDictionary {
		return try await self.downloadJSON(ofType: XUJSONDictionary.self, at: url, requestModifier: requestModifier)
	}

	/// Downloads a website source, parses it as JSON and returns it.
	public func downloadJSON<T>(ofType type: T.Type, at url: URL, requestModifier: URLRequestModifier = { _ in }) async throws -> T {
		let data = try await self.downloadData(at: url, requestModifier: { request in
			request.acceptType = .json

			requestModifier(&request)
		})

		guard let obj: T = XUJSONHelper.object(from: data) else {
			throw Error.invalidJSONResponse
		}

		return obj
	}

	/// Downloads a pure website source. The download center will try to interpret
	/// the data with preferredEncoding. If that fails, it will fall back to any
	/// other encoding.
	public func downloadWebPage(at url: URL, preferredEncoding: String.Encoding? = nil, requestModifier: URLRequestModifier = { _ in }) async throws -> String {
		let data = try await self.downloadData(at: url, requestModifier: requestModifier)

		if let responseString = String(data: data, encoding: preferredEncoding ?? self.defaultStringEncoding) {
			return responseString
		}

		/* Fallback */
		guard let string = String(data: data) else {
			throw Error.stringDecodingError
		}

		return string
	}


	#if os(macOS)

	/// Attempts to download content at `URL` and parse it as XML.
	public func downloadXMLDocument(at url: URL, requestModifier: URLRequestModifier = { _ in }) async throws -> XMLDocument {
		let source = try await self.downloadWebPage(at: url, requestModifier: requestModifier)

		do {
			return try XMLDocument(xmlString: source, options: .documentTidyXML)
		} catch {
			if self.logTraffic {
				XULog("[\(self.identifier)] - failed to parse XML document \(source)")
			}

			self.errorHandler?(.invalidXMLResponse)
			throw error
		}
	}

	#endif

	/// Sends a HEAD request to `URL`.
	public func sendHeadRequest(to url: URL, requestModifier: URLRequestModifier = { _ in }) async throws -> HTTPURLResponse? {
		if self.isInvalidated {
			return nil
		}

		var request = URLRequest(url: url)
		request.httpMethod = "HEAD"

		self._setupCookieField(forRequest: &request)
		self._applyAutomaticHeaderFields(to: &request)

		requestModifier(&request)

		do {
			let (_, response) = try await self.session.data(for: request)

			guard let httpResponse = response as? HTTPURLResponse else {
				if self.logTraffic {
					XULog("-[\(self)[\(self.identifier)] \(#function)] - invalid response (non-HTTP): \(response)")
				}
				return nil
			}

			if self.logTraffic {
				XULog("-[\(self)[\(self.identifier)] \(#function)] - 'HEAD'ing \(url), response: \(httpResponse) \(httpResponse.allHeaderFields)")
			}

			self._importCookies(from: httpResponse)

			self.lastHTTPURLResponse = httpResponse
			return httpResponse
		} catch let error {
			if self.logTraffic {
				XULog("-[\(self)[\(self.identifier)] \(#function)] - Failed to send HEAD to URL \(url) - \(error)")
			}
			throw error
		}
	}

}
