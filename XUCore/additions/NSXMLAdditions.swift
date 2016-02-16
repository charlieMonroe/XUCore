//
//  NSXMLAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/*
public extension NSXMLNode {
	
	/// Error: Ambiguous use of nodesForXPath
	@objc public func nodesForXPath(xpath: String) -> [NSXMLNode] {
		let fun = NSXMLNode.nodesForXPath(self)
		guard let nodes = try? fun(xpath) else {
			return  [ ]
		}
		return nodes
	}
	
}
*/

public extension NSXMLNode {
	
	public var integerValue: Int {
		return self.stringValue?.integerValue ?? 0
	}
	
	public func firstNodeOnXPath(xpath: String) -> NSXMLNode? {
		return self.nodesForXPath(xpath).first
	}
	public func integerValueOfFirstNodeOnXPath(xpath: String) -> Int {
		return self.integerValueOfFirstNodeOnXPaths([ xpath ])
	}
	public func integerValueOfFirstNodeOnXPaths(xpaths: [String]) -> Int {
		return self.stringValueOfFirstNodeOnXPaths(xpaths)?.integerValue ?? 0
	}
	public func lastNodeOnXPath(xpath: String) -> NSXMLNode? {
		return self.nodesForXPath(xpath).last
	}
	public func stringValueOfFirstNodeOnXPath(xpath: String) -> String? {
		return self.firstNodeOnXPath(xpath)?.stringValue
	}
	public func stringValueOfFirstNodeOnXPaths(xpaths: [String]) -> String? {
		for path in xpaths {
			if let result = self.stringValueOfFirstNodeOnXPath(path) {
				if result.characters.count > 0 {
					return result
				}
			}
		}
		return nil
	}
	public func stringValueOfLastNodeOnXPath(xpath: String) -> String? {
		return self.lastNodeOnXPath(xpath)?.stringValue
	}
	public func integerValueOfAttributeNamed(attributeName: String) -> Int {
		return 0
	}
	public func stringValueOfAttributeNamed(attributeName: String) -> String? {
		return nil
	}
	
}

public extension NSXMLElement {
	
	public override func integerValueOfAttributeNamed(attributeName: String) -> Int {
		return self.attributeForName(attributeName)?.integerValue ?? 0
	}
	public override func stringValueOfAttributeNamed(attributeName: String) -> String? {
		return self.attributeForName(attributeName)?.stringValue
	}
	
}

public extension NSXMLDocument {
	
	public convenience init?(string: String, andOptions mask: Int) {
		try? self.init(XMLString: string, options: mask)
	}
	
}

public extension Dictionary where Key: StringLiteralConvertible, Value: AnyObject {
	
	public func XMLElementWithName(elementName: String) -> NSXMLElement {
		let formatter = NSDateFormatter()
		formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
		
		let element = NSXMLElement(name: elementName)
		for (k, value) in self {
			let key = String(k)
			if let val =  value as? String {
				element.addChild(NSXMLElement(name: key, stringValue: val))
			}else if let val = value as? NSDecimalNumber {
				element.addChild(NSXMLElement(name: key, stringValue: String(format: "%0.4f", val)))
			}else if let val = value as? NSNumber {
				element.addChild(NSXMLElement(name: key, stringValue: "\(val.stringValue)"))
			}else if let val = value as? NSDate {
				element.addChild(NSXMLElement(name: key, stringValue: formatter.stringFromDate(val)))
			}else if let val = value as? NSDictionary {
				if val.count == 0 {
					continue
				}
				element.addChild(val.XMLElementWithName(key))
			}else if let val = value as? [Dictionary] {
				if val.count == 0 {
					continue
				}
				
				// We require all objects of the array to contain NSDictionaries
				for obj in val {
					element.addChild(obj.XMLElementWithName(key))
				}
				
			}else{
				NSException(name: NSInternalInconsistencyException, reason: "Dictionary contains a value of unsupported type.", userInfo: nil).raise()
			}
		}
		return element
	}
	
}

