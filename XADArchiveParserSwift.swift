//
//  XADArchiveSwift.swift
//  XADMaster
//
//  Created by C.W. Betts on 4/19/17.
//
//

import Foundation

extension XADPath {
	public func sanitizedPathString(with encoding: String.Encoding) -> String {
		return sanitizedPathString(withEncoding: encoding.rawValue)
	}
}

extension XADError: CustomStringConvertible {
	public var description: String {
		if let errDesc = XADException.describe(code) {
			return errDesc
		} else if self.code == .none {
			return "No Error"
		}
		return "Unknown error \(code.rawValue)"
	}
}

extension XADArchiveParser {
	/// Tests the checksum of the archive.
	/// - returns: `true` if the checksum is valid, `false` otherwise.
	/// - throws: If the checksum couldn't be checked for whatever reason.
	@nonobjc public func testChecksum() throws -> Bool {
		do {
			try __testChecksum()
			return true
		} catch XADError.checksum {
			return false
		}
	}
}
