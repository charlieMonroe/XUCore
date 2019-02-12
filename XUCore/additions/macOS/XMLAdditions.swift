//
//  NSXMLAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation


public extension XMLNode {
	
	/// Returns integer value of the node. This is equivalent to calling integerValue
	/// on stringValue of the node.
	var integerValue: Int {
		return self.stringValue?.integerValue ?? 0
	}
	
	
	/// Returns first node on XPath.
	func firstNode(onXPath xpath: String) -> XMLNode? {
		return self.nodes(forXPath: xpath).first
	}
	
	func integerValue(ofFirstNodeOnXPath xpath: String) -> Int {
		return self.integerValue(ofFirstNodeOnXPaths: [xpath])
	}
	func integerValue(ofFirstNodeOnXPaths xpaths: [String]) -> Int {
		return self.stringValue(ofFirstNodeOnXPaths: xpaths)?.integerValue ?? 0
	}
	func lastNode(onXPath xpath: String) -> XMLNode? {
		return self.nodes(forXPath: xpath).last
	}
	func stringValue(ofFirstNodeOnXPath xpath: String) -> String? {
		return self.firstNode(onXPath: xpath)?.stringValue
	}
	func stringValue(ofFirstNodeOnXPaths xpaths: [String]) -> String? {
		for path in xpaths {
			if let result = self.stringValue(ofFirstNodeOnXPath: path), !result.isEmpty {
				return result
			}
		}
		return nil
	}
	func stringValue(ofLastNodeOnXPath xpath: String) -> String? {
		return self.lastNode(onXPath: xpath)?.stringValue
	}
	@objc func integerValue(ofAttributeNamed attributeName: String) -> Int {
		return 0
	}
	@objc func stringValue(ofAttributeNamed attributeName: String) -> String? {
		return nil
	}
	
}

public extension XMLElement {
	
	@discardableResult
	func addAttribute(named name: String, withStringValue value: String) -> XMLNode {
		let node = XMLNode(kind: XMLNode.Kind.attribute)
		node.name = name
		node.stringValue = value
		self.addAttribute(node)
		return node
	}
	
	override func integerValue(ofAttributeNamed attributeName: String) -> Int {
		return self.attribute(forName: attributeName)?.integerValue ?? 0
	}
	override func stringValue(ofAttributeNamed attributeName: String) -> String? {
		return self.attribute(forName: attributeName)?.stringValue
	}
	
	/// Initializes self with `name` and sets attributes on self.
	convenience init(name: String, attributes: [String : String]) {
		self.init(name: name)
		
		self.setAttributesWith(attributes)
	}
	
}

public extension XMLDocument {
	
	convenience init?(string: String, andOptions mask: XMLNode.Options) {
		try? self.init(xmlString: string, options: mask)
	}
	
}

public extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
	
	/// Converts a dictionary into an XMLElement. It uses the key as the element
	/// name. Supports all values that property list does, the only other limitation
	/// is that arrays need to contain dictionaries only. Will call fatalError
	/// if a value that doesn't meet these requirements is included.
	func xmlElement(withName elementName: String) -> XMLElement {
		let formatter = DateFormatter()
		formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
		
		let element = XMLElement(name: elementName)
		for (k, value) in self {
			let key = String(describing: k)
			if let val =  value as? String {
				element.addChild(XMLElement(name: key, stringValue: val))
			} else if let val = value as? NSDecimalNumber {
				element.addChild(XMLElement(name: key, stringValue: String(format: "%0.4f", val)))
			} else if let val = value as? NSNumber {
				element.addChild(XMLElement(name: key, stringValue: "\(val.stringValue)"))
			} else if let val = value as? Date {
				element.addChild(XMLElement(name: key, stringValue: formatter.string(from: val)))
			} else if let val = value as? XUJSONDictionary {
				if val.isEmpty {
					continue
				}
				element.addChild(val.xmlElement(withName: key))
			} else if let val = value as? [Dictionary] {
				if val.isEmpty {
					continue
				}
				
				// We require all objects of the array to contain NSDictionaries
				for obj in val {
					element.addChild(obj.xmlElement(withName: key))
				}
			} else {
				fatalError("Dictionary contains a value of unsupported type.")
			}
		}
		return element
	}
	
}

