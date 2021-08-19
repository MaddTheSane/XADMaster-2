/*
 * PDFParser.h
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

#import "PDFStream.h"
#import "PDFEncryptionHandler.h"
#import "../ClangAnalyser.h"

XADEXTERN NSExceptionName const PDFWrongMagicException;
XADEXTERN NSExceptionName const PDFInvalidFormatException;
XADEXTERN NSExceptionName const PDFParserException;

XADEXPORT
@interface PDFParser:NSObject
{
	CSHandle *mainhandle,*fh;

	NSMutableDictionary *objdict;
	NSMutableArray *unresolved;

	NSDictionary *trailerdict;
	PDFEncryptionHandler *encryption;

	SEL passwordaction;
	__unsafe_unretained id passwordtarget;

	int currchar;
}

+(instancetype)parserWithHandle:(CSHandle *)handle;
+(instancetype)parserForPath:(NSString *)path;

-(instancetype)initWithHandle:(CSHandle *)handle;

@property (NS_NONATOMIC_IOSONLY, readonly, getter=isEncrypted) BOOL encrypted;
-(BOOL)needsPassword;
-(BOOL)setPassword:(NSString *)password;
-(void)setPasswordRequestAction:(SEL)action target:(id)target;

-(NSDictionary *)objectDictionary;
-(NSDictionary *)trailerDictionary;
-(NSDictionary *)rootDictionary;
-(NSDictionary *)infoDictionary;

-(NSData *)permanentID;
-(NSData *)currentID;

-(NSDictionary *)pagesRoot;

-(PDFEncryptionHandler *)encryptionHandler;

-(void)startParsingFromHandle:(CSHandle *)handle atOffset:(off_t)offset;
-(off_t)parserFileOffset;
-(void)proceed;
-(void)proceedWithoutCommentHandling;
-(void)skipWhitespace;
-(void)proceedAssumingCharacter:(uint8_t)c errorMessage:(NSString *)error;
-(void)proceedWithoutCommentHandlingAssumingCharacter:(uint8_t)c errorMessage:(NSString *)error;

-(void)parse;

-(NSDictionary *)parsePDFXref;
-(NSDictionary *)parsePDFXrefTable;
-(NSDictionary *)parsePDFXrefStream;
-(void)setupEncryptionIfNeededForTrailerDictionary:(NSDictionary *)trailer;

-(id)parsePDFObjectWithReferencePointer:(PDFObjectReference **)refptr;
-(uint64_t)parseSimpleInteger;
-(uint64_t)parseIntegerOfSize:(int)size fromHandle:(CSHandle *)handle default:(uint64_t)def;

-(void)parsePDFCompressedObjectStream:(PDFStream *)stream;

-(id)parsePDFTypeWithParent:(PDFObjectReference *)parent;
-(NSNull *)parsePDFNull;
-(NSNumber *)parsePDFBool;
-(NSNumber *)parsePDFNumber;
-(NSString *)parsePDFWord;
-(PDFString *)parsePDFStringWithParent:(PDFObjectReference *)parent;
-(PDFString *)parsePDFHexStringWithParent:(PDFObjectReference *)parent;
-(NSArray *)parsePDFArrayWithParent:(PDFObjectReference *)parent;
-(NSDictionary *)parsePDFDictionaryWithParent:(PDFObjectReference *)parent;

-(void)resolveIndirectObjects;

-(void)_raiseParserException:(NSString *)error CLANG_ANALYZER_NORETURN;

@end


XADEXPORT
@interface PDFString:NSObject <NSCopying>
{
	NSData *data;
	PDFObjectReference *ref;
	PDFParser *parser;
}

-(instancetype)initWithData:(NSData *)bytes parent:(PDFObjectReference *)parent parser:(PDFParser *)owner;

-(NSData *)data;
-(PDFObjectReference *)reference;
-(NSData *)rawData;
-(NSString *)string;

@end


XADEXPORT
@interface PDFObjectReference:NSObject <NSCopying>
{
	int num,gen;
}

+(instancetype)referenceWithNumber:(int)objnum generation:(int)objgen;
+(instancetype)referenceWithNumberObject:(NSNumber *)objnum generationObject:(NSNumber *)objgen;

-(instancetype)initWithNumber:(int)objnum generation:(int)objgen;

@property (NS_NONATOMIC_IOSONLY, readonly) int number;
@property (NS_NONATOMIC_IOSONLY, readonly) int generation;

@end

