/*
 * PDFStream.h
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

#import "NSDictionaryNumberExtension.h"

#import "../CSHandle.h"
#import "../CSByteStreamHandle.h"

typedef NS_ENUM(int, PDFImageType) {
	PDFUnsupportedImageType = 0,
	PDFIndexedImageType  = 1,
	PDFGrayImageType = 2,
	PDFRGBImageType = 3,
	PDFCMYKImageType = 4,
	PDFLabImageType = 5,
	PDFSeparationImageType = 6,
	PDFMaskImageType = 7
};

@class PDFParser,PDFObjectReference;

XADEXPORT
@interface PDFStream:NSObject
{
	NSDictionary *dict;
	CSHandle *fh;
	off_t offs;
	PDFObjectReference *ref;
	PDFParser *parser;
}

NS_ASSUME_NONNULL_BEGIN

-(instancetype)initWithDictionary:(NSDictionary *)dictionary fileHandle:(CSHandle *)filehandle
offset:(off_t)offset reference:(PDFObjectReference *)reference parser:(PDFParser *)owner;

@property (NS_NONATOMIC_IOSONLY, readonly, retain) NSDictionary *dictionary;
@property (NS_NONATOMIC_IOSONLY, readonly, retain) PDFObjectReference *reference;

@property (NS_NONATOMIC_IOSONLY, readonly, getter=isImage) BOOL image;
@property (NS_NONATOMIC_IOSONLY, readonly, getter=isJPEGImage) BOOL JPEGImage;
@property (NS_NONATOMIC_IOSONLY, readonly, getter=isJPEG2000Image) BOOL JPEG2000Image;

@property (NS_NONATOMIC_IOSONLY, readonly) int imageWidth;
@property (NS_NONATOMIC_IOSONLY, readonly) int imageHeight;
@property (NS_NONATOMIC_IOSONLY, readonly) int imageBitsPerComponent;

@property (NS_NONATOMIC_IOSONLY, readonly) PDFImageType imageType;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger numberOfImageComponents;
@property (NS_NONATOMIC_IOSONLY, readonly) NSString *imageColourSpaceName;

@property (NS_NONATOMIC_IOSONLY, readonly) PDFImageType imagePaletteType;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger numberOfImagePaletteComponents;
@property (NS_NONATOMIC_IOSONLY, readonly, retain, nullable) NSString *imagePaletteColourSpaceName;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger numberOfImagePaletteColours;
-(nullable NSData *)imagePaletteData;
-(nullable id)_paletteColourSpaceObject;

-(PDFImageType)_typeForColourSpaceObject:(id)colourspace;
-(NSInteger)_numberOfComponentsForColourSpaceObject:(id)colourspace;
-(nullable NSString *)_nameForColourSpaceObject:(id)colourspace;

-(nullable NSData *)imageICCColourProfile;
-(nullable NSData *)_ICCColourProfileForColourSpaceObject:(id)colourspace;

-(nullable NSString *)imageSeparationName;
-(nullable NSArray *)imageDecodeArray;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasMultipleFilters;
-(nullable NSString *)finalFilter;

-(CSHandle *)rawHandle;
-(CSHandle *)handle;
-(CSHandle *)JPEGHandle;
-(CSHandle *)handleExcludingLast:(BOOL)excludelast;
-(nullable CSHandle *)handleExcludingLast:(BOOL)excludelast decrypted:(BOOL)decrypted;
-(nullable CSHandle *)handleForFilterName:(NSString *)filtername decodeParms:(NSDictionary *)decodeparms parentHandle:(CSHandle *)parent;
-(nullable CSHandle *)predictorHandleForDecodeParms:(NSDictionary *)decodeparms parentHandle:(CSHandle *)parent;

@end

XADEXPORT
@interface PDFASCII85Handle:CSByteStreamHandle
{
	uint32_t val;
	uint8_t finalbytes;
}

-(id)initWithHandle:(CSHandle *)handle;

-(void)resetByteStream;
-(uint8_t)produceByteAtOffset:(off_t)pos;

@end

@interface PDFHexHandle:CSByteStreamHandle

-(uint8_t)produceByteAtOffset:(off_t)pos;

@end



XADEXPORT
@interface PDFTIFFPredictorHandle:CSByteStreamHandle
{
	int cols,comps,bpc;
	int prev[4];
}

-(instancetype)initWithHandle:(CSHandle *)handle columns:(int)columns
components:(int)components bitsPerComponent:(int)bitspercomp;
-(uint8_t)produceByteAtOffset:(off_t)pos;

@end

XADEXPORT
@interface PDFPNGPredictorHandle:CSByteStreamHandle
{
	int cols,comps,bpc;
	uint8_t *prevbuf;
	int type;
}

-(instancetype)initWithHandle:(CSHandle *)handle columns:(int)columns
components:(int)components bitsPerComponent:(int)bitspercomp;
-(void)resetByteStream;
-(uint8_t)produceByteAtOffset:(off_t)pos;

@end

NS_ASSUME_NONNULL_END
