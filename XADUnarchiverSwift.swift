//
//  XADUnarchiverSwift.swift
//  XADMaster
//
//  Created by C.W. Betts on 4/19/17.
//
//

import Foundation

extension XADUnarchiver {
	@nonobjc open func parseAndUnarchive() throws {
		let error = __parseAndUnarchive()
		if error != .none {
			throw XADError(error)
		}
	}
	
	@nonobjc open func extractEntry(with dictionary: [XADArchiveKeys: Any], as path: String? = nil, forceDirectories: Bool = false) throws {
		let err = __extractEntry(with: dictionary, as: path, forceDirectories: forceDirectories)
		if err != .none {
			throw XADError(err)
		}
	}
}
