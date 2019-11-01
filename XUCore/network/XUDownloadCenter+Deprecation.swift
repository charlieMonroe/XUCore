//
//  XUDownloadCenter+Deprecation.swift
//  XUCore
//
//  Created by Charlie Monroe on 7/29/19.
//  Copyright © 2019 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// We are slowly deprecating calls with the option URL.
extension XUDownloadCenter {
	
	@available(*, deprecated)
	public func downloadData(at url: URL?, referingFunction: String = #function, acceptType: URLRequest.ContentType? = .defaultBrowser, withRequestModifier modifier: URLRequestModifier? = nil) -> Data? {
		guard let url = url else {
			XULogStacktrace("Trying to download from nil URL, returning nil.")
			return nil
		}
		
		return self.downloadData(at: url, referingFunction: referingFunction, acceptType: acceptType, withRequestModifier: modifier)
	}

	@available(*, deprecated)
	public func downloadJSON<T>(at url: URL!, withRequestModifier modifier: URLRequestModifier? = nil) -> T? {
		guard let url = url else {
			XULogStacktrace("Trying to download from nil URL, returning nil.")
			return nil
		}
		
		return self.downloadJSON(ofType: T.self, at: url, withRequestModifier: modifier)
	}
	
	@available(*, deprecated)
	public func downloadJSONDictionary(at url: URL!, withRequestModifier modifier: URLRequestModifier? = nil) -> XUJSONDictionary? {
		guard let url = url else {
			XULogStacktrace("Trying to download from nil URL, returning nil.")
			return nil
		}
		
		return self.downloadJSONDictionary(at: url, withRequestModifier: modifier)
	}
	
	@available(*, deprecated)
	public func downloadWebPage(at url: URL?, preferredEncoding: String.Encoding? = nil, withRequestModifier modifier: URLRequestModifier? = nil) -> String? {
		guard let url = url else {
			XULogStacktrace("Trying to download from nil URL, returning nil.")
			return nil
		}
		
		return self.downloadWebPage(at: url, withRequestModifier: modifier)
	}
	
	@available(*, deprecated)
	public func downloadWebPage(postingFormIn source: String, toURL url: URL?, withAdditionalValues fields: [String : String], withRequestModifier requestModifier: URLRequestModifier? = nil) -> String? {
		guard let url = url else {
			return nil
		}
		
		return self.downloadWebPage(postingFormIn: source, toURL: url, withAdditionalValues: fields, withRequestModifier: requestModifier)
	}
	
	@available(*, deprecated)
	public func downloadWebPage(postingFormIn source: String, toURL url: URL?, withFieldsModifier modifier: POSTFieldsModifier? = nil, withRequestModifier requestModifier: URLRequestModifier? = nil) -> String? {
		guard let url = url else {
			return nil
		}
		
		return self.downloadWebPage(postingFormIn: source, toURL: url, withRequestModifier: requestModifier)
	}
	
	@available(*, deprecated)
	public func downloadWebPage(postingFormWithValues values: [String : String], toURL url: URL?, withRequestModifier requestModifier: URLRequestModifier? = nil) -> String? {
		guard let url = url else {
			return nil
		}
		
		return self.downloadWebPage(postingFormWithValues: values, toURL: url, withRequestModifier: requestModifier)
	}
	
	#if os(macOS)
	@available(*, deprecated)
	public func downloadXMLDocument(at url: URL?, withRequestModifier modifier: URLRequestModifier? = nil) -> XMLDocument? {
		guard let url = url else {
			XULogStacktrace("Trying to download from nil URL, returning nil.")
			return nil
		}
		
		return self.downloadXMLDocument(at: url, withRequestModifier: modifier)

	}
	#endif

	
	@available(*, deprecated)
	public func statusCode(for url: URL!) -> Int {
		guard let url = url else {
			return 0
		}
		
		return self.statusCode(for: url)
	}
	
	@available(*, deprecated)
	public func sendHeadRequest(to url: URL?, withRequestModifier modifier: URLRequestModifier? = nil) -> HTTPURLResponse? {
		guard let url = url else {
			return nil
		}
		
		return self.sendHeadRequest(to: url, withRequestModifier: modifier)
	}
}
