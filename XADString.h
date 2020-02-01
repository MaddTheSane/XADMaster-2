/*
 * XADString.h
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

NS_ASSUME_NONNULL_BEGIN

@class XADStringSource, UniversalDetector;

//! The supported encodings used by \c XADString
typedef NSString *XADStringEncodingName NS_TYPED_ENUM;

XADEXTERN XADStringEncodingName const XADUTF8StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.utf8);
XADEXTERN XADStringEncodingName const XADASCIIStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.ascii);

XADEXTERN XADStringEncodingName const XADISOLatin1StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin1);
XADEXTERN XADStringEncodingName const XADISOLatin2StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin2);
XADEXTERN XADStringEncodingName const XADISOLatin3StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin3);
XADEXTERN XADStringEncodingName const XADISOLatin4StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin4);
XADEXTERN XADStringEncodingName const XADISOLatin5StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin5);
XADEXTERN XADStringEncodingName const XADISOLatin6StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin6);
XADEXTERN XADStringEncodingName const XADISOLatin7StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin7);
XADEXTERN XADStringEncodingName const XADISOLatin8StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin8);
XADEXTERN XADStringEncodingName const XADISOLatin9StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin9);
XADEXTERN XADStringEncodingName const XADISOLatin10StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin10);
XADEXTERN XADStringEncodingName const XADISOLatin11StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin11);
XADEXTERN XADStringEncodingName const XADISOLatin12StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin12);
XADEXTERN XADStringEncodingName const XADISOLatin13StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin13);
XADEXTERN XADStringEncodingName const XADISOLatin14StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin14);
XADEXTERN XADStringEncodingName const XADISOLatin15StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin15);
XADEXTERN XADStringEncodingName const XADISOLatin16StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin16);

XADEXTERN XADStringEncodingName const XADShiftJISStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.shiftJIS);

XADEXTERN XADStringEncodingName const XADWindowsCP1250StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.windowsCP1250);
XADEXTERN XADStringEncodingName const XADWindowsCP1251StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.windowsCP1251);
XADEXTERN XADStringEncodingName const XADWindowsCP1252StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.windowsCP1252);
XADEXTERN XADStringEncodingName const XADWindowsCP1253StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.windowsCP1253);
XADEXTERN XADStringEncodingName const XADWindowsCP1254StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.windowsCP1254);

XADEXTERN XADStringEncodingName const XADMacOSRomanStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSRoman);
XADEXTERN XADStringEncodingName const XADMacOSJapaneseStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSJapanese);
XADEXTERN XADStringEncodingName const XADMacOSTraditionalChineseStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSTraditionalChinese);
XADEXTERN XADStringEncodingName const XADMacOSKoreanStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSKorean);
XADEXTERN XADStringEncodingName const XADMacOSArabicStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSArabic);
XADEXTERN XADStringEncodingName const XADMacOSHebrewStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSHebrew);
XADEXTERN XADStringEncodingName const XADMacOSGreekStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSGreek);
XADEXTERN XADStringEncodingName const XADMacOSCyrillicStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSCyrillic);
XADEXTERN XADStringEncodingName const XADMacOSSimplifiedChineseStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSSimplifiedChinese);
XADEXTERN XADStringEncodingName const XADMacOSRomanianStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSRomanian);
XADEXTERN XADStringEncodingName const XADMacOSUkranianStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSUkranian);
XADEXTERN XADStringEncodingName const XADMacOSThaiStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSThai);
XADEXTERN XADStringEncodingName const XADMacOSCentralEuropeanRomanStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSCentralEuropean);
XADEXTERN XADStringEncodingName const XADMacOSIcelandicStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSIcelandic);
XADEXTERN XADStringEncodingName const XADMacOSTurkishStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSTurkish);
XADEXTERN XADStringEncodingName const XADMacOSCroatianStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSCroatian);


@protocol XADString <NSObject>

-(BOOL)canDecodeWithEncodingName:(XADStringEncodingName)encoding NS_SWIFT_NAME(canDecode(with:));
@property (NS_NONATOMIC_IOSONLY, readonly, copy, nullable) NSString *string;
-(nullable NSString *)stringWithEncodingName:(XADStringEncodingName)encoding NS_SWIFT_NAME(string(with:));
@property (NS_NONATOMIC_IOSONLY, readonly, copy, nullable) NSData *data;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL encodingIsKnown;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADStringEncodingName encodingName;
@property (NS_NONATOMIC_IOSONLY, readonly) float confidence;

@property (NS_NONATOMIC_IOSONLY, readonly, strong, nullable) XADStringSource *source;

#ifdef __APPLE__
-(BOOL)canDecodeWithEncoding:(NSStringEncoding)encoding;
-(nullable NSString *)stringWithEncoding:(NSStringEncoding)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly) NSStringEncoding encoding NS_REFINED_FOR_SWIFT;
#endif

@end


XADEXPORT
@interface XADString:NSObject <XADString,NSCopying>
{
	NSData *data;
	NSString *string;
	XADStringSource *source;
}

+(instancetype)XADStringWithString:(NSString *)string;
+(instancetype)analyzedXADStringWithData:(NSData *)bytedata source:(XADStringSource *)stringsource;
+(nullable instancetype)decodedXADStringWithData:(NSData *)bytedata encodingName:(XADStringEncodingName)encoding;

+(NSString *)escapedStringForData:(NSData *)data encodingName:(XADStringEncodingName)encoding;
+(NSString *)escapedStringForBytes:(const void *)bytes length:(size_t)length encodingName:(XADStringEncodingName)encoding;
+(NSString *)escapedASCIIStringForBytes:(const void *)bytes length:(size_t)length;
+(NSData *)escapedASCIIDataForString:(NSString *)string;

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
-(instancetype)initWithData:(NSData *)bytedata source:(XADStringSource *)stringsource NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithString:(NSString *)knownstring NS_DESIGNATED_INITIALIZER;

-(BOOL)canDecodeWithEncodingName:(XADStringEncodingName)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy, nullable) NSString *string;
-(nullable NSString *)stringWithEncodingName:(XADStringEncodingName)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy, nullable) NSData *data;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL encodingIsKnown;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADStringEncodingName encodingName;
@property (NS_NONATOMIC_IOSONLY, readonly) float confidence;

@property (NS_NONATOMIC_IOSONLY, readonly, strong, nullable) XADStringSource *source;

-(BOOL)hasASCIIPrefix:(NSString *)asciiprefix;
-(XADString *)XADStringByStrippingASCIIPrefixOfLength:(NSInteger)length;

#ifdef __APPLE__
-(BOOL)canDecodeWithEncoding:(NSStringEncoding)encoding;
-(nullable NSString *)stringWithEncoding:(NSStringEncoding)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly) NSStringEncoding encoding NS_REFINED_FOR_SWIFT;
#endif

@end

@interface XADString (PlatformSpecific)

+(BOOL)canDecodeData:(NSData *)data encodingName:(XADStringEncodingName)encoding;
+(BOOL)canDecodeBytes:(const void *)bytes length:(size_t)length encodingName:(XADStringEncodingName)encoding;
+(nullable NSString *)stringForData:(NSData *)data encodingName:(XADStringEncodingName)encoding;
+(nullable NSString *)stringForBytes:(const void *)bytes length:(size_t)length encodingName:(XADStringEncodingName)encoding;
+(nullable NSData *)dataForString:(NSString *)string encodingName:(XADStringEncodingName)encoding;
#if __has_feature(objc_class_property)
@property (class, NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<NSArray<NSString*>*> *availableEncodingNames;
#else
+(NSArray<NSArray<NSString*>*> *)availableEncodingNames;
#endif

#ifdef __APPLE__
+(XADStringEncodingName)encodingNameForEncoding:(NSStringEncoding)encoding;
+(NSStringEncoding)encodingForEncodingName:(XADStringEncodingName)encoding;
#endif

@end



XADEXPORT
@interface XADStringSource:NSObject
{
	UniversalDetector *detector;
	XADStringEncodingName fixedencodingname;
	BOOL mac,hasanalyzeddata;

	#ifdef __APPLE__
	NSStringEncoding fixedencoding;
	#endif
}

-(instancetype)init NS_DESIGNATED_INITIALIZER;

-(void)analyzeData:(NSData *)data;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasAnalyzedData;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADStringEncodingName encodingName;
@property (NS_NONATOMIC_IOSONLY, readonly) float confidence;
@property (NS_NONATOMIC_IOSONLY, readonly, strong, nullable) UniversalDetector *detector;

@property (NS_NONATOMIC_IOSONLY, readwrite, copy, nullable) XADStringEncodingName fixedEncodingName;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasFixedEncoding;
@property (NS_NONATOMIC_IOSONLY, readwrite) BOOL prefersMacEncodings;

#ifdef __APPLE__
@property (NS_NONATOMIC_IOSONLY, readonly) NSStringEncoding encoding NS_REFINED_FOR_SWIFT;
@property (NS_NONATOMIC_IOSONLY) NSStringEncoding fixedEncoding NS_REFINED_FOR_SWIFT;
#endif

@end

NS_ASSUME_NONNULL_END
