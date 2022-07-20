//
//  XADArchive.swift
//  XADMaster
//
//  Created by C.W. Betts on 4/19/17.
//
//

import Foundation

extension XADArchive {
	@nonobjc public var nameEncoding: String.Encoding? {
		get {
			let enc = __nameEncoding
			guard enc != 0 else {
				return nil
			}
			return String.Encoding(rawValue: enc)
		}
		set {
			__nameEncoding = newValue?.rawValue ?? 0
		}
	}
	
	/// Gets the resource fork handle for the specified entry.
	/// - returns: The data handle, or `nil` if there's no resource fork data.
	/// - throws: On failure.
	/// - parameter n: The entry number.
	@nonobjc public func resourceHandle(forEntry n: Int) throws -> XADHandle? {
		do {
			return try __resourceHandle(forEntry: n)
		} catch XADError.empty {
			return nil
		}
	}
}
