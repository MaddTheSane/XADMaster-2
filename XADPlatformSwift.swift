//
//  XADPlatformSwift.swift
//  XADMaster
//
//  Created by C.W. Betts on 4/19/17.
//
//

import Foundation

public extension XADPlatform {
	@nonobjc class func extractResourceForkEntry(with dict: [XADArchiveParser.Key : Any], unarchiver: XADUnarchiver, toPath destpath: String) throws {
		let err = __extractResourceForkEntry(with: dict, unarchiver: unarchiver, toPath: destpath)
		guard err == .none else {
			throw XADError(err)
		}
	}
	
	@nonobjc class func updateFileAttributes(atPath path: String, forEntryWith dict: [XADArchiveParser.Key : Any], parser: XADArchiveParser, preservePermissions preservepermissions: Bool) throws {
		let err = __updateFileAttributes(atPath: path, forEntryWith: dict, parser: parser, preservePermissions: preservepermissions)
		guard err == .none else {
			throw XADError(err)
		}
	}
	
	@nonobjc class func createLink(atPath path: String, withDestinationPath link: String) throws {
		let err = __createLink(atPath: path, withDestinationPath: link)
		guard err == .none else {
			throw XADError(err)
		}
	}
}
