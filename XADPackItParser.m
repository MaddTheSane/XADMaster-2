/*
 * XADPackItParser.m
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
#import "XADPackItParser.h"
#import "XADStuffItHuffmanHandle.h"
#import "XADCRCHandle.h"
#import "NSDateXAD.h"

@implementation XADPackItParser

+(int)requiredHeaderSize
{
	return 4;
}

+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name
{
	NSInteger length=data.length;
	const uint8_t *bytes=data.bytes;

	if(length<4) return NO;

	if(bytes[0]=='P'&&bytes[1]=='M'&&bytes[2]=='a')
	if(bytes[3]=='g'||bytes[3]=='4'||bytes[3]=='5'||bytes[3]=='6') return YES;

	return NO;
}

-(void)parse
{
	[self setIsMacArchive:YES];

	CSHandle *handle=self.handle;

	for(;;)
	{
		uint32_t magic=[handle readID];
		if(magic=='PEnd') break;

		off_t start=handle.offsetInFile;

		BOOL comp,encrypted;
		CSHandle *fh;
		CSInputBuffer *input=NULL;
		NSMutableDictionary *datadesc;

		if(magic=='PMag')
		{
			comp=NO;
			encrypted=NO;
			fh=handle;
		}
		else if(magic=='PMa4'||magic=='PMa5'||magic=='PMa6')
		{
			comp=YES;

			CSHandle *src;
			if(magic=='PMa4')
			{
				src=handle;
				encrypted=NO;
			}
			else if(magic=='PMa5')
			{
				src=[[[XADPackItXORHandle alloc] initWithHandle:handle
				password:[self.password dataUsingEncoding:NSMacOSRomanStringEncoding]] autorelease];
				encrypted=YES;
			}
			else //if(magic=='PMa6')
			{
				src=[[[XADPackItDESHandle alloc] initWithHandle:handle
				password:[self.password dataUsingEncoding:NSMacOSRomanStringEncoding]] autorelease];
				encrypted=YES;
			}

			XADStuffItHuffmanHandle *hh=[[[XADStuffItHuffmanHandle alloc] initWithHandle:src] autorelease];
			input=hh->input;
			fh=hh;
		}
		else { [XADException raiseIllegalDataException]; for(;;); }

		int namelen=[fh readUInt8];
		if(namelen>63) namelen=63;
		uint8_t namebuf[63];
		[fh readBytes:63 toBuffer:namebuf];
		XADPath *name=[self XADPathWithBytes:namebuf length:namelen separators:XADNoPathSeparator];

		uint32_t type=[fh readUInt32BE];
		uint32_t creator=[fh readUInt32BE];
		int finderflags=[fh readUInt16BE];
		[fh skipBytes:2];
		uint32_t datasize=[fh readUInt32BE];
		uint32_t rsrcsize=[fh readUInt32BE];
		uint32_t modification=[fh readUInt32BE];
		uint32_t creation=[fh readUInt32BE];
		/*int headcrc=*/[fh readUInt16BE];

		uint32_t datacompsize,rsrccompsize;
		off_t end;

		if(!comp)
		{
			[fh skipBytes:datasize+rsrcsize];
			int crc=[fh readUInt16BE];

			datacompsize=datasize;
			rsrccompsize=rsrcsize;
			end=start+94+datacompsize+rsrccompsize+2;

			datadesc=[NSMutableDictionary dictionaryWithObjectsAndKeys:
				@(start+94),@"Offset",
				@(datasize+rsrcsize),@"Length",
				@(crc),@"CRC",
			nil];
		}
		else
		{
			[fh skipBytes:datasize];
			datacompsize=(int)CSInputBufferOffset(input)-94;

			[fh skipBytes:rsrcsize];
			rsrccompsize=(int)CSInputBufferOffset(input)-datacompsize-94;

			int crc=[fh readUInt16BE];

			CSInputSkipToByteBoundary(input);

			int crypto;
			if(magic=='PMa4')
			{
				end=start+CSInputBufferOffset(input);
				crypto=0;
			}
			else
			{
				end=start+((CSInputBufferOffset(input)+7)&~7);
				if(magic=='PMa5') crypto=1;
				else crypto=2;
			}

			datadesc=[NSMutableDictionary dictionaryWithObjectsAndKeys:
				@(start),@"Offset",
				@(end-start),@"Length",
				@(datasize+rsrcsize+94),@"UncompressedLength",
				@(crc),@"CRC",
				@(crypto),@"Crypto",
			nil];
		}

		if(datasize||!rsrcsize)
		{
			[self addEntryWithDictionary:[NSMutableDictionary dictionaryWithObjectsAndKeys:
				name,XADFileNameKey,
				@(type),XADFileTypeKey,
				@(creator),XADFileCreatorKey,
				@(finderflags),XADFinderFlagsKey,
				@(datasize),XADFileSizeKey,
				@(datacompsize),XADCompressedSizeKey,
				[NSDate XADDateWithTimeIntervalSince1904:modification],XADLastModificationDateKey,
				[NSDate XADDateWithTimeIntervalSince1904:creation],XADCreationDateKey,
				[self XADStringWithString:comp?@"Huffman":@"None"],XADCompressionNameKey,
				@(encrypted),XADIsEncryptedKey,

				datadesc,XADSolidObjectKey,
				@0U,XADSolidOffsetKey,
				@(datasize),XADSolidLengthKey,
			nil]];
		}

		if(rsrcsize)
		{
			[self addEntryWithDictionary:[NSMutableDictionary dictionaryWithObjectsAndKeys:
				name,XADFileNameKey,
				@(type),XADFileTypeKey,
				@(creator),XADFileCreatorKey,
				@(finderflags),XADFinderFlagsKey,
				@(rsrcsize),XADFileSizeKey,
				@(rsrccompsize),XADCompressedSizeKey,
				[NSDate XADDateWithTimeIntervalSince1904:modification],XADLastModificationDateKey,
				[NSDate XADDateWithTimeIntervalSince1904:creation],XADCreationDateKey,
				[self XADStringWithString:comp?@"Huffman":@"None"],XADCompressionNameKey,
				@(encrypted),XADIsEncryptedKey,
				@YES,XADIsResourceForkKey,

				datadesc,XADSolidObjectKey,
				@(datasize),XADSolidOffsetKey,
				@(rsrcsize),XADSolidLengthKey,
			nil]];
		}

		[handle seekToFileOffset:end];
	}
}

-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum
{
	return [self subHandleFromSolidStreamForEntryWithDictionary:dict];
}

-(CSHandle *)handleForSolidStreamWithObject:(id)obj wantChecksum:(BOOL)checksum
{
	off_t offs=[obj[@"Offset"] longLongValue];
	off_t len=[obj[@"Length"] longLongValue];
	CSHandle *handle=[self.handle nonCopiedSubHandleFrom:offs length:len];

	NSNumber *uncomplennum=obj[@"UncompressedLength"];
	if(uncomplennum != nil)
	{
		off_t uncomplen=uncomplennum.longLongValue;
		int crypto=[obj[@"Crypto"] intValue];

		if(crypto==1)
		{
			handle=[[[XADPackItXORHandle alloc] initWithHandle:handle length:len
			password:[self.password dataUsingEncoding:NSMacOSRomanStringEncoding]] autorelease];
		}
		else if(crypto==2)
		{
			handle=[[[XADPackItDESHandle alloc] initWithHandle:handle length:len
			password:[self.password dataUsingEncoding:NSMacOSRomanStringEncoding]] autorelease];
		}

		handle=[[[XADStuffItHuffmanHandle alloc] initWithHandle:handle length:uncomplen] autorelease];
		handle=[handle nonCopiedSubHandleFrom:94 length:uncomplen-94];
	}

	if(checksum)
	{
		handle=[XADCRCHandle CCITTCRC16HandleWithHandle:handle length:handle.fileSize
		correctCRC:[obj[@"CRC"] intValue] conditioned:NO];
	}

	return handle;
}

-(NSString *)formatName
{
	return @"PackIt";
}

@end



@implementation XADPackItXORHandle

-(id)initWithHandle:(CSHandle *)handle password:(NSData *)passdata
{
	return [self initWithHandle:handle length:CSHandleMaxLength password:passdata];
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length password:(NSData *)passdata
{
	if((self=[super initWithInputBufferForHandle:handle length:length]))
	{
		const uint8_t *passbytes=passdata.bytes;
		NSInteger passlen=passdata.length;

		uint8_t passbuf[8];

		memset(passbuf,0,8);
		memcpy(passbuf,passbytes,passlen<8?passlen:8);

		static const int keytr1[56]=
		{
			57,49,41,33,25,17, 9, 1,58,50,42,34,26,18,10, 2,59,51,43,35,27,19,11,03,60,52,44,36,
			63,55,47,39,31,23,15, 7,62,54,46,38,30,22,14, 6,61,53,45,37,29,21,13, 5,28,20,12, 4
		};

		memset(key,0,8);
		for(int i=0;i<56;i++)
		{
			int bitindex=keytr1[i]-1;
			key[i/8]|=((passbuf[bitindex/8]<<(bitindex%8))&0x80)>>(i%8);
		}

		[self setBlockPointer:block];
	}
	return self;
}


-(int)produceBlockAtOffset:(off_t)pos
{
	memset(block,0,8);

	for(int i=0;i<8;i++)
	{
		if(CSInputAtEOF(input)) { [self endBlockStream]; break; }
		block[i]=CSInputNextByte(input)^key[(pos+i)%7];
	}

	return 8;
}

@end



@implementation XADPackItDESHandle

-(id)initWithHandle:(CSHandle *)handle password:(NSData *)passdata
{
	return [self initWithHandle:handle length:CSHandleMaxLength password:passdata];
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length password:(NSData *)passdata
{
	if((self=[super initWithInputBufferForHandle:handle length:length]))
	{
		const uint8_t *passbytes=passdata.bytes;
		NSInteger passlen=passdata.length;

		uint8_t key[8];
		memset(key,0,8);
		memcpy(key,passbytes,passlen<8?passlen:8);

		DES_set_key(key,&schedule);

		[self setBlockPointer:block];
	}
	return self;
}


-(int)produceBlockAtOffset:(off_t)pos
{
	memset(block,0,8);

	for(int i=0;i<8;i++)
	{
		if(CSInputAtEOF(input)) { [self endBlockStream]; break; }
		block[i]=CSInputNextByte(input);
	}

	DES_encrypt(block,1,&schedule);

	return 8;
}

@end
