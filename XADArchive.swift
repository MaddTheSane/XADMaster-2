//
//  XADArchive.swift
//  XADMaster
//
//  Created by C.W. Betts on 4/19/17.
//
//

import Foundation

extension XADArchive {
	@nonobjc open var nameEncoding: String.Encoding? {
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
	
	@nonobjc open func resourceHandle(forEntry n: Int) throws -> XADHandle? {
		do {
			return try __resourceHandle(forEntry: n)
		} catch XADError.empty {
			return nil
		}
	}
}
