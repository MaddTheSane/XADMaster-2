/*
 * XADArchiveParser.h
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wquoted-include-in-framework-header"
#import "XADTypes.h"
#import "XADException.h"
#import "XADString.h"
#import "XADPath.h"
#import "XADRegex.h"
#import "CSHandle.h"
#import "XADSkipHandle.h"
#import "XADResourceFork.h"
#import "Checksums.h"
#pragma clang diagnostic pop

NS_ASSUME_NONNULL_BEGIN

@class UTType;

typedef NSString *XADArchiveKeys NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(XADArchiveParser.Keys);

XADEXTERN XADArchiveKeys const XADFileNameKey NS_SWIFT_NAME(fileName);
XADEXTERN XADArchiveKeys const XADCommentKey NS_SWIFT_NAME(comment);
XADEXTERN XADArchiveKeys const XADFileSizeKey NS_SWIFT_NAME(fileSize);
XADEXTERN XADArchiveKeys const XADCompressedSizeKey NS_SWIFT_NAME(compressedSize);
XADEXTERN XADArchiveKeys const XADCompressionNameKey NS_SWIFT_NAME(compressionName);

XADEXTERN XADArchiveKeys const XADLastModificationDateKey NS_SWIFT_NAME(lastModificationDate);
XADEXTERN XADArchiveKeys const XADLastAccessDateKey NS_SWIFT_NAME(lastAccessDate);
XADEXTERN XADArchiveKeys const XADLastAttributeChangeDateKey NS_SWIFT_NAME(lastAttributeChangeDate);
XADEXTERN XADArchiveKeys const XADLastBackupDateKey NS_SWIFT_NAME(lastBackupDate);
XADEXTERN XADArchiveKeys const XADCreationDateKey NS_SWIFT_NAME(creationDate);

XADEXTERN XADArchiveKeys const XADIsDirectoryKey NS_SWIFT_NAME(isDirectory);
XADEXTERN XADArchiveKeys const XADIsResourceForkKey NS_SWIFT_NAME(isResourceFork);
XADEXTERN XADArchiveKeys const XADIsArchiveKey NS_SWIFT_NAME(isArchive);
XADEXTERN XADArchiveKeys const XADIsHiddenKey NS_SWIFT_NAME(isHidden);
XADEXTERN XADArchiveKeys const XADIsLinkKey NS_SWIFT_NAME(isLink);
XADEXTERN XADArchiveKeys const XADIsHardLinkKey NS_SWIFT_NAME(isHardLink);
XADEXTERN XADArchiveKeys const XADLinkDestinationKey NS_SWIFT_NAME(linkDestination);
XADEXTERN XADArchiveKeys const XADIsCharacterDeviceKey NS_SWIFT_NAME(isCharacterDevice);
XADEXTERN XADArchiveKeys const XADIsBlockDeviceKey NS_SWIFT_NAME(isBlockDevice);
XADEXTERN XADArchiveKeys const XADDeviceMajorKey NS_SWIFT_NAME(deviceMajor);
XADEXTERN XADArchiveKeys const XADDeviceMinorKey NS_SWIFT_NAME(deviceMinor);
XADEXTERN XADArchiveKeys const XADIsFIFOKey NS_SWIFT_NAME(isFIFO);
XADEXTERN XADArchiveKeys const XADIsEncryptedKey NS_SWIFT_NAME(isEncrypted);
XADEXTERN XADArchiveKeys const XADIsCorruptedKey NS_SWIFT_NAME(isCorrupted);

XADEXTERN XADArchiveKeys const XADExtendedAttributesKey NS_SWIFT_NAME(extendedAttributes);
XADEXTERN XADArchiveKeys const XADFileTypeKey NS_SWIFT_NAME(fileType);
XADEXTERN XADArchiveKeys const XADFileCreatorKey NS_SWIFT_NAME(fileCreator);
XADEXTERN XADArchiveKeys const XADFinderFlagsKey NS_SWIFT_NAME(finderFlags);
XADEXTERN XADArchiveKeys const XADFinderInfoKey NS_SWIFT_NAME(finderInfo);
XADEXTERN XADArchiveKeys const XADPosixPermissionsKey NS_SWIFT_NAME(posixPermissions);
XADEXTERN XADArchiveKeys const XADPosixUserKey NS_SWIFT_NAME(posixUser);
XADEXTERN XADArchiveKeys const XADPosixGroupKey NS_SWIFT_NAME(posixGroup);
XADEXTERN XADArchiveKeys const XADPosixUserNameKey NS_SWIFT_NAME(posixUserName);
XADEXTERN XADArchiveKeys const XADPosixGroupNameKey NS_SWIFT_NAME(posixGroupName);
XADEXTERN XADArchiveKeys const XADDOSFileAttributesKey NS_SWIFT_NAME(dosFileAttributes);
XADEXTERN XADArchiveKeys const XADWindowsFileAttributesKey NS_SWIFT_NAME(windowsFileAttributes);
XADEXTERN XADArchiveKeys const XADAmigaProtectionBitsKey NS_SWIFT_NAME(amigaProtectionBits);

XADEXTERN XADArchiveKeys const XADIndexKey NS_SWIFT_NAME(index);
XADEXTERN XADArchiveKeys const XADDataOffsetKey NS_SWIFT_NAME(dataOffset);
XADEXTERN XADArchiveKeys const XADDataLengthKey NS_SWIFT_NAME(dataLength);
XADEXTERN XADArchiveKeys const XADSkipOffsetKey NS_SWIFT_NAME(skipOffset);
XADEXTERN XADArchiveKeys const XADSkipLengthKey NS_SWIFT_NAME(skipLength);

XADEXTERN XADArchiveKeys const XADIsSolidKey NS_SWIFT_NAME(isSolid);
XADEXTERN XADArchiveKeys const XADFirstSolidIndexKey NS_SWIFT_NAME(firstSolidIndex);
XADEXTERN XADArchiveKeys const XADFirstSolidEntryKey NS_SWIFT_NAME(firstSolidEntry);
XADEXTERN XADArchiveKeys const XADNextSolidIndexKey NS_SWIFT_NAME(nextSolidIndex);
XADEXTERN XADArchiveKeys const XADNextSolidEntryKey NS_SWIFT_NAME(nextSolidEntry);
XADEXTERN XADArchiveKeys const XADSolidObjectKey NS_SWIFT_NAME(solidObject);
XADEXTERN XADArchiveKeys const XADSolidOffsetKey NS_SWIFT_NAME(solidOffset);
XADEXTERN XADArchiveKeys const XADSolidLengthKey NS_SWIFT_NAME(solidLength);

// Archive properties only
XADEXTERN XADArchiveKeys const XADArchiveNameKey NS_SWIFT_NAME(archiveName);
XADEXTERN XADArchiveKeys const XADVolumesKey NS_SWIFT_NAME(volumes);
XADEXTERN XADArchiveKeys const XADVolumeScanningFailedKey NS_SWIFT_NAME(volumeScanningFailed);
XADEXTERN XADArchiveKeys const XADDiskLabelKey NS_SWIFT_NAME(diskLabel);

XADEXTERN XADArchiveKeys const XADSignatureOffset;
XADEXTERN XADArchiveKeys const XADParserClass;

@protocol XADArchiveParserDelegate;

XADEXPORT
@interface XADArchiveParser:NSObject
{
	CSHandle *sourcehandle;
	XADSkipHandle *skiphandle;
	XADResourceFork *resourcefork;

	NSString *password;
	XADStringEncodingName passwordencodingname;
	BOOL caresaboutpasswordencoding;

	NSMutableDictionary<XADArchiveKeys,id> *properties;
	XADStringSource *stringsource;

	int currindex;

	id parsersolidobj;
	NSMutableDictionary *firstsoliddict,*prevsoliddict;
	id currsolidobj;
	CSHandle *currsolidhandle;
	BOOL forcesolid;

	BOOL shouldstop;
}

+(nullable Class)archiveParserClassForHandle:(CSHandle *)handle firstBytes:(NSData *)header
resourceFork:(nullable XADResourceFork *)fork name:(NSString *)name
propertiesToAdd:(NSMutableDictionary<XADArchiveKeys,id> *)props;
+ (nullable Class)archiveParserFromParsersWithFloatingSignature:(NSArray<Class> *)parsers forHandle:(CSHandle *)handle firstBytes:(NSData *)header name:(NSString *)name propertiesToAdd:(NSMutableDictionary<XADArchiveKeys,id> *)props;
+ (BOOL)isValidParserClass:(Class)parserClass forHandle:(CSHandle *)handle firstBytes:(NSData *)header name:(NSString *)name propertiesToAdd:(NSMutableDictionary<XADArchiveKeys,id> *)props;

+(nullable __kindof XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle name:(NSString *)name NS_SWIFT_UNAVAILABLE("Throws uncaught exception!");
+(nullable __kindof XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle name:(NSString *)name error:(nullable XADError *)errorptr NS_REFINED_FOR_SWIFT;
+(nullable __kindof XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle resourceFork:(nullable XADResourceFork *)fork name:(NSString *)name NS_SWIFT_UNAVAILABLE("Throws uncaught exception!");
+(nullable __kindof XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle resourceFork:(nullable XADResourceFork *)fork name:(NSString *)name error:(nullable XADError *)errorptr NS_REFINED_FOR_SWIFT;
+(nullable __kindof XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header name:(NSString *)name NS_SWIFT_UNAVAILABLE("Uncaught exception!");
+(nullable __kindof XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header name:(NSString *)name error:(nullable XADError *)errorptr NS_REFINED_FOR_SWIFT;
+(nullable __kindof XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header resourceFork:(nullable XADResourceFork *)fork name:(NSString *)name NS_SWIFT_UNAVAILABLE("Throws uncaught exception!");
+(nullable __kindof XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header resourceFork:(nullable XADResourceFork *)fork name:(NSString *)name error:(nullable XADError *)errorptr NS_REFINED_FOR_SWIFT;
+(nullable __kindof XADArchiveParser *)archiveParserForPath:(NSString *)filename NS_SWIFT_UNAVAILABLE("Throws uncaught exception!");
+(nullable __kindof XADArchiveParser *)archiveParserForPath:(NSString *)filename error:(nullable XADError *)errorptr NS_REFINED_FOR_SWIFT;
+(nullable __kindof XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)entry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum NS_SWIFT_UNAVAILABLE("Throws uncaught exception!");
+(nullable __kindof XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)entry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum error:(nullable XADError *)errorptr NS_REFINED_FOR_SWIFT;
+(nullable __kindof XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)entry resourceForkDictionary:(nullable NSDictionary *)forkentry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum NS_SWIFT_UNAVAILABLE("Throws uncaught exception!");
+(nullable __kindof XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)entry resourceForkDictionary:(nullable NSDictionary<XADArchiveKeys,id> *)forkentry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum error:(nullable XADError *)errorptr NS_REFINED_FOR_SWIFT;

+(nullable __kindof XADArchiveParser *)archiveParserForFileURL:(NSURL *)filename NS_SWIFT_UNAVAILABLE("Throws uncaught exception!");

#pragma mark NSError functions
+(nullable __kindof XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle name:(NSString *)name nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr NS_SWIFT_NAME(archiveParser(for:name:));
+(nullable __kindof XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)entry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr NS_SWIFT_NAME(archiveParser(with:archiveParser:wantChecksum:));
+(nullable __kindof XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)entry resourceForkDictionary:(nullable NSDictionary<XADArchiveKeys,id> *)forkentry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr NS_SWIFT_NAME(archiveParser(with:resourceForkDictionary:archiveParser:wantChecksum:));
+(nullable __kindof XADArchiveParser *)archiveParserForPath:(NSString *)filename nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr NS_SWIFT_NAME(archiveParser(forPath:));
+(nullable __kindof XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header resourceFork:(nullable XADResourceFork *)fork name:(NSString *)name nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr NS_SWIFT_NAME(archiveParser(for:firstBytes:resourceFork:name:));
+(nullable __kindof XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle resourceFork:(nullable XADResourceFork *)fork name:(NSString *)name nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr NS_SWIFT_NAME(archiveParser(for:resourceFork:name:));
+(nullable __kindof XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header name:(NSString *)name nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr NS_SWIFT_NAME(archiveParser(for:firstBytes:name:));
+(nullable __kindof XADArchiveParser *)archiveParserForFileURL:(NSURL *)filename error:(NSError *_Nullable __autoreleasing *_Nullable)errorptr NS_SWIFT_NAME(archiveParser(for:));


-(instancetype)init NS_DESIGNATED_INITIALIZER;

@property (nonatomic, retain) XADHandle *handle;
@property (NS_NONATOMIC_IOSONLY, retain, nullable) XADResourceFork *resourceFork;
@property (NS_NONATOMIC_IOSONLY, copy) NSString *name;
@property (NS_NONATOMIC_IOSONLY, copy) NSString *filename;
@property (NS_NONATOMIC_IOSONLY, copy) NSArray<NSString*> *allFilenames;

@property (NS_NONATOMIC_IOSONLY, weak, nullable) id<XADArchiveParserDelegate> delegate;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDictionary<XADArchiveKeys,id> *properties;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *currentFilename;

@property (NS_NONATOMIC_IOSONLY, getter=isEncrypted, readonly) BOOL encrypted;
@property (NS_NONATOMIC_IOSONLY, copy, nullable) NSString *password;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasPassword;

@property (NS_NONATOMIC_IOSONLY, copy) XADStringEncodingName encodingName;
@property (NS_NONATOMIC_IOSONLY, readonly) float encodingConfidence;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL caresAboutPasswordEncoding;
@property (nonatomic, copy, nullable) XADStringEncodingName passwordEncodingName;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) XADStringSource *stringSource;

-(nullable XADString *)linkDestinationForDictionary:(NSDictionary<XADArchiveKeys,id> *)dict NS_SWIFT_UNAVAILABLE("Call throws on failure");
-(nullable XADString *)linkDestinationForDictionary:(NSDictionary<XADArchiveKeys,id> *)dict error:(XADError *)errorptr NS_REFINED_FOR_SWIFT;
-(nullable XADString *)linkDestinationForDictionary:(NSDictionary<XADArchiveKeys,id> *)dict nserror:(NSError *__autoreleasing __nullable*__nullable)errorptr;
-(nullable NSDictionary<NSString*,NSData*> *)extendedAttributesForDictionary:(NSDictionary<XADArchiveKeys,id> *)dict;
-(nullable NSData *)finderInfoForDictionary:(NSDictionary<XADArchiveKeys,id> *)dict;
#if __APPLE__
+(NSString*)possibleUTIForDictionary:(NSDictionary<XADArchiveKeys,id> *)dict;

+(UTType*)possibleContentTypeForDictionary:(NSDictionary<XADArchiveKeys,id> *)dict API_AVAILABLE(macos(11.0), macCatalyst(14.0), ios(14.0), watchos(7.0), tvos(14.0));
#endif

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL wasStopped;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasChecksum;
-(BOOL)testChecksum NS_SWIFT_UNAVAILABLE("throws exception");
-(XADError)testChecksumWithoutExceptions NS_REFINED_FOR_SWIFT;
-(BOOL)testChecksumWithError:(NSError**)error NS_REFINED_FOR_SWIFT;



// Internal functions

+(NSArray<NSString*> *)scanForVolumesWithFilename:(NSString *)filename regex:(XADRegex *)regex;
+(NSArray<NSString*> *)scanForVolumesWithFilename:(NSString *)filename
regex:(XADRegex *)regex firstFileExtension:(nullable NSString *)firstext;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL shouldKeepParsing;

-(CSHandle *)handleAtDataOffsetForDictionary:(NSDictionary<XADArchiveKeys,id> *)dict;
@property (NS_NONATOMIC_IOSONLY, readonly, retain) XADSkipHandle *skipHandle;
-(CSHandle *)zeroLengthHandleWithChecksum:(BOOL)checksum;
-(nullable CSHandle *)subHandleFromSolidStreamForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasVolumes;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<NSNumber*> *volumeSizes;
@property (NS_NONATOMIC_IOSONLY, readonly, retain) CSHandle *currentHandle;

-(void)setObject:(id)object forPropertyKey:(XADArchiveKeys)key;
-(void)addPropertiesFromDictionary:(NSDictionary<XADArchiveKeys,id> *)dict;
-(void)setIsMacArchive:(BOOL)ismac;

-(void)addEntryWithDictionary:(NSMutableDictionary<XADArchiveKeys,id> *)dict;
-(void)addEntryWithDictionary:(NSMutableDictionary<XADArchiveKeys,id> *)dict retainPosition:(BOOL)retainpos;

-(XADString *)XADStringWithString:(NSString *)string;
-(nullable XADString *)XADStringWithData:(NSData *)data;
-(nullable XADString *)XADStringWithData:(NSData *)data encodingName:(XADStringEncodingName)encoding;
-(nullable XADString *)XADStringWithBytes:(const void *)bytes length:(NSInteger)length;
-(nullable XADString *)XADStringWithBytes:(const void *)bytes length:(NSInteger)length encodingName:(XADStringEncodingName)encoding;
-(nullable XADString *)XADStringWithCString:(const char *)cstring;
-(nullable XADString *)XADStringWithCString:(const char *)cstring encodingName:(XADStringEncodingName)encoding;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADPath *XADPath;
-(XADPath *)XADPathWithString:(NSString *)string;
-(XADPath *)XADPathWithUnseparatedString:(NSString *)string;
-(XADPath *)XADPathWithData:(NSData *)data separators:(XADPathSeparator)separators;
-(XADPath *)XADPathWithData:(NSData *)data encodingName:(XADStringEncodingName)encoding separators:(XADPathSeparator)separators;
-(XADPath *)XADPathWithBytes:(const void *)bytes length:(NSInteger)length separators:(XADPathSeparator)separators;
-(XADPath *)XADPathWithBytes:(const void *)bytes length:(NSInteger)length encodingName:(XADStringEncodingName)encoding separators:(XADPathSeparator)separators;
-(XADPath *)XADPathWithCString:(const char *)cstring separators:(XADPathSeparator)separators;
-(XADPath *)XADPathWithCString:(const char *)cstring encodingName:(XADStringEncodingName)encoding separators:(XADPathSeparator)separators;

@property (NS_NONATOMIC_IOSONLY, readonly, copy, nullable) NSData *encodedPassword;
@property (NS_NONATOMIC_IOSONLY, readonly, nullable) const char *encodedCStringPassword;

-(void)reportInterestingFileWithReason:(NSString *)reason,... NS_FORMAT_FUNCTION(1,2);
-(void)reportInterestingFileWithReason:(NSString *)reason format:(va_list)args NS_FORMAT_FUNCTION(1,0);



// Subclasses implement these:

#if __has_feature(objc_class_property)
@property (class, readonly) int requiredHeaderSize;
#else
+(int)requiredHeaderSize;
#endif
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name propertiesToAdd:(NSMutableDictionary<XADArchiveKeys,id> *)props;
+(nullable NSArray<NSString*> *)volumesForHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name;

-(void)parse NS_SWIFT_UNAVAILABLE("Call throws on failure");
-(nullable CSHandle *)handleForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict wantChecksum:(BOOL)checksum NS_SWIFT_UNAVAILABLE("Call throws on failure");
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *formatName;

-(nullable CSHandle *)handleForSolidStreamWithObject:(id)obj wantChecksum:(BOOL)checksum;

//! Exception-free wrapper for subclass method.<br>
//! Will, in addition, return \c XADBreakError if the delegate
//! requested parsing to stop.
-(XADError)parseWithoutExceptions NS_REFINED_FOR_SWIFT;

//! Exception-free wrapper for subclass method.<br>
//! Will, in addition, pass \c XADBreakError and return \c NO if the delegate
//! requested parsing to stop.
-(BOOL)parseWithError:(NSError *__autoreleasing __nullable*__nullable)error;

//! Exception-free wrapper for subclass method.
-(nullable CSHandle *)handleForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict wantChecksum:(BOOL)checksum error:(nullable XADError *)errorptr NS_REFINED_FOR_SWIFT;
//! Exception-free wrapper for subclass method.
-(nullable CSHandle *)handleForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict wantChecksum:(BOOL)checksum nserror:(NSError *__autoreleasing __nullable*__nullable)errorptr ;

@end

@protocol XADArchiveParserDelegate <NSObject>
@optional

-(void)archiveParser:(XADArchiveParser *)parser foundEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict NS_SWIFT_UNAVAILABLE("");
-(BOOL)archiveParser:(XADArchiveParser *)parser foundEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict error:(NSError**)outError;
-(BOOL)archiveParsingShouldStop:(XADArchiveParser *)parser;
-(void)archiveParserNeedsPassword:(XADArchiveParser *)parser;
-(void)archiveParser:(XADArchiveParser *)parser findsFileInterestingForReason:(NSString *)reason;

@end

NSMutableArray *XADSortVolumes(NSMutableArray *volumes,NSString *firstfileextension) UNAVAILABLE_ATTRIBUTE;

NS_ASSUME_NONNULL_END
