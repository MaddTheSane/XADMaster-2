/*
 * XADPath.h
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
#import "XADString.h"
#pragma clang diagnostic pop

NS_ASSUME_NONNULL_BEGIN

typedef const char* XADPathSeparator NS_TYPED_ENUM;
XADEXTERN XADPathSeparator const XADUnixPathSeparator NS_SWIFT_NAME(unix);
XADEXTERN XADPathSeparator const XADWindowsPathSeparator NS_SWIFT_NAME(windows);
XADEXTERN XADPathSeparator const XADEitherPathSeparator NS_SWIFT_NAME(either);
XADEXTERN XADPathSeparator const XADNoPathSeparator NS_SWIFT_NAME(none);

XADEXPORT
@interface XADPath:NSObject <XADString,NSCopying>
{
	XADPath *parent;

	NSArray<NSString*> *cachedcanonicalcomponents;
	NSString *cachedencoding;
}

#if __has_feature(objc_class_property)
@property (class, readonly, copy) XADPath *emptyPath;
#else
+(XADPath *)emptyPath;
#endif
+(instancetype)pathWithString:(NSString *)string;
+(instancetype)pathWithStringComponents:(NSArray<NSString*> *)components;
+(instancetype)separatedPathWithString:(NSString *)string;
+(instancetype)decodedPathWithData:(NSData *)bytedata encodingName:(XADStringEncodingName)encoding separators:(XADPathSeparator)separators;
+(instancetype)analyzedPathWithData:(NSData *)bytedata source:(XADStringSource *)stringsource
separators:(XADPathSeparator)pathseparators;

-(instancetype)init NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithParent:(nullable XADPath *)parentpath NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithPath:(XADPath *)path parent:(nullable XADPath *)parentpath;

@property (NS_NONATOMIC_IOSONLY, getter=isAbsolute, readonly) BOOL absolute;
@property (NS_NONATOMIC_IOSONLY, getter=isEmpty, readonly) BOOL empty;
-(BOOL)isCanonicallyEqual:(id)other;
-(BOOL)isCanonicallyEqual:(id)other encodingName:(XADStringEncodingName)encoding;
-(BOOL)hasPrefix:(XADPath *)other;
-(BOOL)hasCanonicalPrefix:(XADPath *)other;
-(BOOL)hasCanonicalPrefix:(XADPath *)other encodingName:(XADStringEncodingName)encoding;

@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger depth; // Note: Does not take . or .. paths into account.
-(NSInteger)depthWithEncodingName:(XADStringEncodingName)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<NSString*> *pathComponents;
-(NSArray<NSString*> *)pathComponentsWithEncodingName:(XADStringEncodingName)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<NSString*> *canonicalPathComponents;
-(NSArray<NSString*> *)canonicalPathComponentsWithEncodingName:(XADStringEncodingName)encoding;
-(void)_addPathComponentsToArray:(NSMutableArray<NSString*> *)components encodingName:(XADStringEncodingName)encoding;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *lastPathComponent;
-(NSString *)lastPathComponentWithEncodingName:(XADStringEncodingName)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *firstPathComponent;
-(NSString *)firstPathComponentWithEncodingName:(XADStringEncodingName)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *firstCanonicalPathComponent;
-(NSString *)firstCanonicalPathComponentWithEncodingName:(XADStringEncodingName)encoding;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADPath *pathByDeletingLastPathComponent;
-(XADPath *)pathByDeletingLastPathComponentWithEncodingName:(XADStringEncodingName)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADPath *pathByDeletingFirstPathComponent;
-(XADPath *)pathByDeletingFirstPathComponentWithEncodingName:(XADStringEncodingName)encoding;

-(XADPath *)pathByAppendingXADStringComponent:(XADString *)component;
-(XADPath *)pathByAppendingPath:(XADPath *)path;
-(XADPath *)_copyWithParent:(nullable XADPath *)newparent;

// These are safe for filesystem use, and adapted to the current platform.
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *sanitizedPathString;
-(NSString *)sanitizedPathStringWithEncodingName:(XADStringEncodingName)encoding;

// XADString interface.
// NOTE: These are not guaranteed to be safe for usage as filesystem paths,
// only for display!
-(BOOL)canDecodeWithEncodingName:(XADStringEncodingName)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *string;
-(NSString *)stringWithEncodingName:(XADStringEncodingName)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *data;
-(void)_appendPathToData:(NSMutableData *)data;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL encodingIsKnown;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADStringEncodingName encodingName;
@property (NS_NONATOMIC_IOSONLY, readonly) float confidence;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) XADStringSource *source;

#ifdef __APPLE__
-(BOOL)canDecodeWithEncoding:(NSStringEncoding)encoding;
-(NSString *)stringWithEncoding:(NSStringEncoding)encoding;
-(NSString *)sanitizedPathStringWithEncoding:(NSStringEncoding)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly) NSStringEncoding encoding;
#endif

// Other interfaces.
@property (NS_NONATOMIC_IOSONLY, readonly) NSUInteger hash;

// Deprecated.
@property (NS_NONATOMIC_IOSONLY, readonly, copy, null_unspecified) XADPath *safePath DEPRECATED_ATTRIBUTE; // Deprecated. Use sanitizedPathString: instead.

// Subclass methods.
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL _isPartAbsolute;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL _isPartEmpty;
-(NSInteger)_depthOfPartWithEncodingName:(NSString *)encoding;
-(void)_addPathComponentsOfPartToArray:(NSMutableArray<NSString*> *)array encodingName:(XADStringEncodingName)encoding;
-(NSString *)_lastPathComponentOfPartWithEncodingName:(XADStringEncodingName)encoding;
-(NSString *)_firstPathComponentOfPartWithEncodingName:(XADStringEncodingName)encoding;
-(nullable XADPath *)_pathByDeletingLastPathComponentOfPartWithEncodingName:(XADStringEncodingName)encoding;
-(nullable XADPath *)_pathByDeletingFirstPathComponentOfPartWithEncodingName:(XADStringEncodingName)encoding;
-(BOOL)_canDecodePartWithEncodingName:(XADStringEncodingName)encoding;
-(void)_appendPathForPartToData:(NSMutableData *)data;
@property (NS_NONATOMIC_IOSONLY, readonly, strong, nullable) XADStringSource *_sourceForPart;

@end

XADEXTERN
@interface XADStringPath:XADPath
{
	NSString *string;
}

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
-(instancetype)initWithComponentString:(NSString *)pathstring NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithComponentString:(NSString *)pathstring parent:(nullable XADPath *)parentpath NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithPath:(XADStringPath *)path parent:(nullable XADPath *)parentpath;
-(instancetype)initWithParent:(nullable XADPath *)parentpath NS_DESIGNATED_INITIALIZER;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL _isPartAbsolute;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL _isPartEmpty;
-(NSInteger)_depthOfPartWithEncodingName:(XADStringEncodingName)encoding;
-(void)_addPathComponentsOfPartToArray:(NSMutableArray *)array encodingName:(XADStringEncodingName)encoding;
-(NSString *)_lastPathComponentOfPartWithEncodingName:(XADStringEncodingName)encoding;
-(NSString *)_firstPathComponentOfPartWithEncodingName:(XADStringEncodingName)encoding;
-(nullable XADPath *)_pathByDeletingLastPathComponentOfPartWithEncodingName:(XADStringEncodingName)encoding;
-(nullable XADPath *)_pathByDeletingFirstPathComponentOfPartWithEncodingName:(XADStringEncodingName)encoding;
-(BOOL)_canDecodePartWithEncodingName:(XADStringEncodingName)encoding;
-(void)_appendPathForPartToData:(NSMutableData *)data;
@property (NS_NONATOMIC_IOSONLY, readonly, strong, nullable) XADStringSource *_sourceForPart;

@end

XADEXTERN
@interface XADRawPath:XADPath
{
	NSData *data;
	XADStringSource *source;
	XADPathSeparator separators;
}

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
-(instancetype)initWithData:(NSData *)bytedata source:(XADStringSource *)stringsource
separators:(XADPathSeparator)pathseparators NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithData:(NSData *)bytedata source:(XADStringSource *)stringsource
separators:(XADPathSeparator)pathseparators parent:(XADPath *)parentpath NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithPath:(XADRawPath *)path parent:(nullable XADPath *)parentpath;
-(instancetype)initWithParent:(nullable XADPath *)parentpath NS_DESIGNATED_INITIALIZER;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL _isPartAbsolute;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL _isPartEmpty;
-(NSInteger)_depthOfPartWithEncodingName:(XADStringEncodingName)encoding;
-(void)_addPathComponentsOfPartToArray:(NSMutableArray<NSString*> *)array encodingName:(XADStringEncodingName)encoding;
-(NSString *)_lastPathComponentOfPartWithEncodingName:(XADStringEncodingName)encoding;
-(NSString *)_firstPathComponentOfPartWithEncodingName:(XADStringEncodingName)encoding;
-(nullable XADPath *)_pathByDeletingLastPathComponentOfPartWithEncodingName:(XADStringEncodingName)encoding;
-(nullable XADPath *)_pathByDeletingFirstPathComponentOfPartWithEncodingName:(XADStringEncodingName)encoding;
-(BOOL)_canDecodePartWithEncodingName:(XADStringEncodingName)encoding;
-(void)_appendPathForPartToData:(NSMutableData *)data;
@property (NS_NONATOMIC_IOSONLY, readonly, strong, nullable) XADStringSource *_sourceForPart;

@end

NS_ASSUME_NONNULL_END
