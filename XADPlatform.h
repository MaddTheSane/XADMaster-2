/*
 * XADPlatform.h
 *
 * Copyright (c) 2017-present, MacPaw Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */
#import <Foundation/Foundation.h>
#import "XADTypes.h"
#import "XADUnarchiver.h"
#import "CSHandle.h"

NS_ASSUME_NONNULL_BEGIN

XADEXPORT
@interface XADPlatform:NSObject

// Archive entry extraction.
+(XADError)extractResourceForkEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict
unarchiver:(XADUnarchiver *)unarchiver toPath:(NSString *)destpath NS_REFINED_FOR_SWIFT;
+(XADError)updateFileAttributesAtPath:(NSString *)path
forEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict parser:(XADArchiveParser *)parser
preservePermissions:(BOOL)preservepermissions NS_REFINED_FOR_SWIFT;
+(XADError)createLinkAtPath:(NSString *)path withDestinationPath:(NSString *)link NS_REFINED_FOR_SWIFT;

/*
+(BOOL)extractResourceForkEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict
									   unarchiver:(XADUnarchiver *)unarchiver toPath:(NSString *)destpath error:(NSError**)error;
+(BOOL)updateFileAttributesAtPath:(NSString *)path
			   forEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict parser:(XADArchiveParser *)parser
				  preservePermissions:(BOOL)preservepermissions error:(NSError**)error;
+(BOOL)createLinkAtPath:(NSString *)path withDestinationPath:(NSString *)link error:(NSError**)error;
 */

// Archive post-processing.
+(nullable id)readCloneableMetadataFromPath:(NSString *)path;
+(void)writeCloneableMetadata:(id)metadata toPath:(NSString *)path;
+(BOOL)copyDateFromPath:(NSString *)src toPath:(NSString *)dest;
+(BOOL)resetDateAtPath:(NSString *)path;

// Path functions.
+(BOOL)fileExistsAtPath:(NSString *)path;
+(BOOL)fileExistsAtPath:(NSString *)path isDirectory:(nullable BOOL *)isdirptr;
+(NSString *)uniqueDirectoryPathWithParentDirectory:(NSString *)parent;
+(NSString *)sanitizedPathComponent:(NSString *)component;
+(NSArray<NSString*> *)contentsOfDirectoryAtPath:(NSString *)path;
+(BOOL)moveItemAtPath:(NSString *)src toPath:(NSString *)dest;
+(BOOL)removeItemAtPath:(NSString *)path;

// Resource forks
+(nullable CSHandle *)handleForReadingResourceForkAtPath:(NSString *)path;
+(nullable CSHandle *)handleForReadingResourceForkAtFileURL:(NSURL *)path;

// Time functions.
#if __has_feature(objc_class_property)
@property (class, readonly) double currentTimeInSeconds;
#else
+(double)currentTimeInSeconds;
#endif

@end

NS_ASSUME_NONNULL_END
