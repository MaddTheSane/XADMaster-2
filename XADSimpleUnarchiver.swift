//
//  XADSimpleUnarchiver.swift
//  XADMaster
//
//  Created by C.W. Betts on 4/20/17.
//
//

import Foundation

public extension XADSimpleUnarchiver {
	@nonobjc func unarchive() throws {
		let err = __unarchive()
		guard err == .none else {
			throw XADError(err)
		}
	}
}
