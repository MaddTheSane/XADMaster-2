//
//  XADUnarchiverSwift.swift
//  XADMaster
//
//  Created by C.W. Betts on 4/19/17.
//
//

import Foundation

extension XADUnarchiver {
	@nonobjc open func extractEntry(with dictionary: [XADArchiveKeys: Any], as path: String? = nil, forceDirectories: Bool = false) throws {
		try extractEntry(with: dictionary, as: path, forceDirectories: forceDirectories, error: ())
	}
}
