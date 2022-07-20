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
}

extension XADString {
	@nonobjc public class func encodingName(for encoding: String.Encoding) -> XADStringEncodingName {
		return encodingName(forEncoding: encoding.rawValue)
	}
	
	@nonobjc public class func encoding(for encoding: XADStringEncodingName) -> String.Encoding {
		return String.Encoding(rawValue: self.encoding(forEncodingName: encoding))
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

extension XADStringSource {
    @nonobjc public var encoding: String.Encoding? {
		let enc = __encoding
		guard enc != 0 else {
			return nil
		}
		return String.Encoding(rawValue: enc)
	}
	
    @nonobjc public var fixedEncoding: String.Encoding? {
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
