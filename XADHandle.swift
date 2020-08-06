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
}
