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

public extension XMLNode {
	
	public var integerValue: Int {
		return self.stringValue?.integerValue ?? 0
	}
	
	
	public func firstNode(onXPath xpath: String) -> XMLNode? {
		return self.nodes(forXPath: xpath).first
	}
	public func integerValue(ofFirstNodeOnXPath xpath: String) -> Int {
		return self.integerValue(ofFirstNodeOnXPaths: [ xpath ])
	}
	public func integerValue(ofFirstNodeOnXPaths xpaths: [String]) -> Int {
		return self.stringValue(ofFirstNodeOnXPaths: xpaths)?.integerValue ?? 0
	}
	public func lastNode(onXPath xpath: String) -> XMLNode? {
		return self.nodes(forXPath: xpath).last
	}
	public func stringValue(ofFirstNodeOnXPath xpath: String) -> String? {
		return self.firstNode(onXPath: xpath)?.stringValue
	}
	public func stringValue(ofFirstNodeOnXPaths xpaths: [String]) -> String? {
		for path in xpaths {
			if let result = self.stringValue(ofFirstNodeOnXPath: path) {
				if result.characters.count > 0 {
					return result
				}
			}
		}
		return nil
	}
	public func stringValue(ofLastNodeOnXPath xpath: String) -> String? {
		return self.lastNode(onXPath: xpath)?.stringValue
	}
	public func integerValue(ofAttributeNamed attributeName: String) -> Int {
		return 0
	}
	public func stringValue(ofAttributeNamed attributeName: String) -> String? {
		return nil
	}
	
}

public extension XMLElement {
	
	public override func integerValue(ofAttributeNamed attributeName: String) -> Int {
		return self.attribute(forName: attributeName)?.integerValue ?? 0
	}
	public override func stringValue(ofAttributeNamed attributeName: String) -> String? {
		return self.attribute(forName: attributeName)?.stringValue
	}
	
}

public extension XMLDocument {
	
	public convenience init?(string: String, andOptions mask: Int) {
		try? self.init(xmlString: string, options: mask)
	}
	
}

public extension Dictionary where Key: ExpressibleByStringLiteral, Value: AnyObject {
	
	public func xmlElement(withName elementName: String) -> XMLElement {
		let formatter = DateFormatter()
		formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
		
		let element = XMLElement(name: elementName)
		for (k, value) in self {
			let key = String(describing: k)
			if let val =  value as? String {
				element.addChild(XMLElement(name: key, stringValue: val))
			}else if let val = value as? NSDecimalNumber {
				element.addChild(XMLElement(name: key, stringValue: String(format: "%0.4f", val)))
			}else if let val = value as? NSNumber {
				element.addChild(XMLElement(name: key, stringValue: "\(val.stringValue)"))
			}else if let val = value as? Date {
				element.addChild(XMLElement(name: key, stringValue: formatter.string(from: val)))
			}else if let val = value as? NSDictionary {
				if val.count == 0 {
					continue
				}
				element.addChild(val.xmlElement(withName: key))
			}else if let val = value as? [Dictionary] {
				if val.count == 0 {
					continue
				}
				
				// We require all objects of the array to contain NSDictionaries
				for obj in val {
					element.addChild(obj.xmlElement(withName: key))
				}
				
			}else{
				fatalError("Dictionary contains a value of unsupported type.")
			}
		}
		return element
	}
	
}

