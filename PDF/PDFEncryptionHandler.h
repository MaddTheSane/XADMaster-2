/*
 * PDFEncryptionHandler.h
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
#import "PDFEncryptionUtils.h"
#import "../CSHandle.h"

XADEXTERN NSExceptionName const PDFUnsupportedEncryptionException;

@class PDFEncryptionAlgorithm;
@class PDFObjectReference,PDFString;

XADEXPORT
@interface PDFEncryptionHandler:NSObject
{
	int version,revision;
	NSDictionary *encrypt;
	NSData *permanentid;

	NSString *password;
	BOOL needspassword;

	NSMutableDictionary *keys,*algorithms;
	PDFEncryptionAlgorithm *streamalgorithm,*stringalgorithm;
}

+(BOOL)isEncryptedForTrailerDictionary:(NSDictionary *)trailer;

-(instancetype)initWithEncryptDictionary:(NSDictionary *)encryptdict permanentID:(NSData *)permanentiddata;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL needsPassword;
-(BOOL)setPassword:(NSString *)newpassword;

-(NSData *)documentKeyOfLength:(int)length;
-(NSData *)keyOfLength:(int)length forReference:(PDFObjectReference *)ref AES:(BOOL)aes;

-(NSData *)decryptString:(PDFString *)string;
-(CSHandle *)decryptStream:(PDFStream *)stream;

/*-(NSData *)keyForReference:(PDFObjectReference *)ref AES:(BOOL)aes;
-(NSData *)userKey;
-(void)calculateKeyForPassword:(NSString *)password;*/

@end


XADEXPORT
@interface PDFEncryptionAlgorithm:NSObject

-(NSData *)decryptedData:(NSData *)data reference:(PDFObjectReference *)ref;
-(CSHandle *)decryptedHandle:(CSHandle *)handle reference:(PDFObjectReference *)ref;
-(void)calculateKeyForPassword:(NSString *)password;

@end


XADEXPORT
@interface PDFNoAlgorithm:PDFEncryptionAlgorithm

-(NSData *)decryptedData:(NSData *)data reference:(PDFObjectReference *)ref;
-(CSHandle *)decryptedHandle:(CSHandle *)handle reference:(PDFObjectReference *)ref;

@end


XADEXPORT
@interface PDFStandardAlgorithm:PDFEncryptionAlgorithm
{
	int keylength;
	PDFEncryptionHandler *parent;
}

-(instancetype)initWithLength:(int)length handler:(PDFEncryptionHandler *)handler;
-(NSData *)keyForReference:(PDFObjectReference *)ref AES:(BOOL)aes;

@end


XADEXPORT
@interface PDFRC4Algorithm:PDFStandardAlgorithm

-(NSData *)decryptedData:(NSData *)data reference:(PDFObjectReference *)ref;
-(CSHandle *)decryptedHandle:(CSHandle *)handle reference:(PDFObjectReference *)ref;

@end

XADEXPORT
@interface PDFAESAlgorithm:PDFStandardAlgorithm

-(NSData *)decryptedData:(NSData *)data reference:(PDFObjectReference *)ref;
-(CSHandle *)decryptedHandle:(CSHandle *)handle reference:(PDFObjectReference *)ref;

@end

