//
//  XADStringSwift.swift
//  XADMaster
//
//  Created by C.W. Betts on 4/19/17.
//
//

import Foundation

public extension XADStringProtocol {
	func canDecode(with encoding: String.Encoding) -> Bool {
		return canDecode(withEncoding: encoding.rawValue)
	}
	
	func string(with encoding: String.Encoding) -> String? {
		return string(withEncoding: encoding.rawValue)
	}
	
	var encoding: String.Encoding? {
		let enc = __encoding
		guard enc != 0 else {
			return nil
		}
		return String.Encoding(rawValue: enc)
	}
	
	@available(*, deprecated, renamed: "canDecode(with:)")
	func canDecode(withEncoding encoding: String.Encoding) -> Bool {
		return canDecode(with: encoding)
	}
	
	@available(*, deprecated, renamed: "string(with:)")
	func string(withEncoding encoding: String.Encoding) -> String? {
		return string(with: encoding)
	}
}

extension XADString {
	@nonobjc open class func encodingName(for encoding: String.Encoding) -> XADStringEncodingName {
		return encodingName(forEncoding: encoding.rawValue)
	}
	
	@nonobjc open class func encoding(for encoding: XADStringEncodingName) -> String.Encoding {
		return String.Encoding(rawValue: self.encoding(forEncodingName: encoding))
	}
	
	@available(*, deprecated, renamed: "encodingName(for:)")
	@nonobjc open class func encodingName(forEncoding encoding: String.Encoding) -> XADStringEncodingName {
		return encodingName(for: encoding)
	}
	
	@available(*, deprecated, renamed: "encoding(for:)")
	@nonobjc open class func encoding(forEncodingName encoding: XADStringEncodingName) -> String.Encoding {
		return self.encoding(for: encoding)
	}
}

public extension XADStringEncodingName {
	@inlinable init(forEncoding encoding: String.Encoding) {
		self = XADString.encodingName(for: encoding)
	}
	
	@inlinable var encoding: String.Encoding {
		return XADString.encoding(for: self)
	}
}

// We can't have this conform to ExpressibleByStringLiteral because 
// 1. It can't be placed in the defining block because the defining block is Objective-C
// 2. The class can't be marked as final because it is an Objective-C class.
extension XADString /*: ExpressibleByStringLiteral*/ {
	@nonobjc public convenience init(stringLiteral value: String) {
		self.init(string: value)
	}
	
	@nonobjc public convenience init(extendedGraphemeClusterLiteral value: String) {
		self.init(stringLiteral: String(extendedGraphemeClusterLiteral: value))
	}
	
	@nonobjc public convenience init(unicodeScalarLiteral value: String) {
		self.init(stringLiteral: String(unicodeScalarLiteral: value))
	}
}

extension XADStringSource {
	@nonobjc open var encoding: String.Encoding? {
		let enc = __encoding
		guard enc != 0 else {
			return nil
		}
		return String.Encoding(rawValue: enc)
	}
	
	@nonobjc open var fixedEncoding: String.Encoding? {
		get {
			let encVal = __fixedEncoding
			guard encVal != 0 else {
				return nil
			}
			return String.Encoding(rawValue: encVal)
		}
		set {
			__fixedEncoding = newValue?.rawValue ?? 0
		}
	}
}
