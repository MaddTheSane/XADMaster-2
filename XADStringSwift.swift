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

public extension XADString {
	@nonobjc @inlinable class func encodingName(for encoding: String.Encoding) -> XADString.EncodingName {
		return encodingName(forEncoding: encoding.rawValue)
	}
	
	@nonobjc class func encoding(for encoding: XADString.EncodingName) -> String.Encoding {
		return String.Encoding(rawValue: self.encoding(forEncodingName: encoding))
	}
}

public extension XADString.EncodingName {
	@inlinable init(forEncoding encoding: String.Encoding) {
		self = XADString.encodingName(forEncoding: encoding.rawValue)
	}
	
	@inlinable var encoding: String.Encoding {
		return String.Encoding(rawValue: XADString.encoding(forEncodingName: self))
	}
}

public extension XADStringSource {
    @nonobjc var encoding: String.Encoding? {
		let enc = __encoding
		guard enc != 0 else {
			return nil
		}
		return String.Encoding(rawValue: enc)
	}
	
    @nonobjc var fixedEncoding: String.Encoding? {
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
