//
//  XADHandle.swift
//  XADMaster
//
//  Created by C.W. Betts on 8/1/18.
//

import Foundation

public extension XADHandle {
	@inlinable func readLine(with encoding: String.Encoding) -> String? {
		return readLine(withEncoding: encoding.rawValue)
	}
	
	func readAndDiscard(atMost num: off_t) throws -> off_t {
		var err: NSError? = nil
		let val = __readAndDiscard(atMost: num, error: &err)
		if val == -1, let err {
			throw err
		}
		return val
	}
}
