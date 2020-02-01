/*
 * XADDiskDoublerParser.m
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
#import "XADDiskDoublerParser.h"

#import "XADCompressHandle.h"
#import "XADDiskDoublerMethod2Handle.h"
#import "XADCompactProLZHHandle.h"
#import "XADStuffItHuffmanHandle.h"
#import "XADStacLZSHandle.h"
#import "XADCompactProRLEHandle.h"
#import "XADCompactProLZHHandle.h"
#import "XADDiskDoublerADnHandle.h"
#import "XADDiskDoublerDDnHandle.h"

#import "XADXORHandle.h"
#import "XADDeltaHandle.h"

#import "XADCRCHandle.h"
#import "XADChecksumHandle.h"
#import "XADXORSumHandle.h"

#import "NSDateXAD.h"

@implementation XADDiskDoublerParser

+(int)requiredHeaderSize
{
	return 124;
}

+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name
{
	NSInteger length=data.length;
	const uint8_t *bytes=data.bytes;

	if(length>=84)
	{
		if(CSUInt32BE(bytes)==0xabcd0054)
		if(XADCalculateCRC(0,bytes,82,XADCRCReverseTable_1021)==
		XADUnReverseCRC16(CSUInt16BE(bytes+82))) return YES;

		if(CSUInt32BE(bytes)==0xabcd0054)
		if(CSUInt16BE(bytes+82)==0) return YES; // Really old files have 0000 instead of a CRC.
	}

	if(length>=78)
	{
		if(CSUInt32BE(bytes)=='DDAR')
		if(XADCalculateCRC(0,bytes,76,XADCRCReverseTable_1021)==
		XADUnReverseCRC16(CSUInt16BE(bytes+76))) return YES;
	}

	if(length>=62)
	{
		if(CSUInt32BE(bytes)=='DDA2')
		if(XADCalculateCRC(0,bytes,60,XADCRCReverseTable_1021)==
		XADUnReverseCRC16(CSUInt16BE(bytes+60))) return YES;
	}

	return NO;
}

-(void)parse
{
	[self setIsMacArchive:YES];

	CSHandle *fh=self.handle;
	uint32_t magic=[fh readID];

	if(magic==0xabcd0054)
	{
		NSString *name=self.name;
		if([name.pathExtension isEqual:@"dd"]) name=name.stringByDeletingPathExtension;
		XADPath *xadname=[self XADPathWithUnseparatedString:name];
		[self parseFileHeaderWithHandle:fh name:xadname];
	}
	else if(magic=='DDAR') [self parseArchive];
	else if(magic=='DDA2') [self parseArchive2];
}

// TODO: look at memory and refcount issues for automatic pool upgrade

-(void)parseArchive
{
	CSHandle *fh=self.handle;
	[fh skipBytes:74];

	XADPath *currdir=self.XADPath;

	while(self.shouldKeepParsing)
	{
		if(fh.atEndOfFile) break;
		uint32_t magic=[fh readID];

		if(magic==0xabcd0054)
		{
			// Skip redundant file headers that sometimes appear at the end of files.
			[fh skipBytes:80];
			continue;
		}

		if(magic!='DDAR') [XADException raiseIllegalDataException];

		[fh skipBytes:4];

		int namelen=[fh readUInt8];
		if(namelen>63) namelen=63;
		uint8_t namebuf[63];
		[fh readBytes:63 toBuffer:namebuf];

		int isdir=[fh readUInt8];
		int enddir=[fh readUInt8];
		uint32_t datasize=[fh readUInt32BE];
		uint32_t rsrcsize=[fh readUInt32BE];
		uint32_t creation=[fh readUInt32BE];
		uint32_t modification=[fh readUInt32BE];
		uint32_t type=[fh readUInt32BE];
		uint32_t creator=[fh readUInt32BE];
		int finderflags=[fh readUInt16BE];
		[fh skipBytes:18];
		int datacrc=[fh readUInt16BE];
		int rsrccrc=[fh readUInt16BE];
		[fh skipBytes:2];

		XADPath *name=[currdir pathByAppendingXADStringComponent:[self XADStringWithBytes:namebuf length:namelen]];

		off_t start=fh.offsetInFile;

		if(enddir)
		{
			currdir=currdir.pathByDeletingLastPathComponent;
		}
		else if(isdir)
		{
			NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithObjectsAndKeys:
				name,XADFileNameKey,
				[NSDate XADDateWithTimeIntervalSince1904:creation],XADCreationDateKey,
				[NSDate XADDateWithTimeIntervalSince1904:modification],XADLastModificationDateKey,
				@(finderflags),XADFinderFlagsKey, // TODO: is this valid?
				@YES,XADIsDirectoryKey,
			nil];

			[self addEntryWithDictionary:dict];
			currdir=name;

			[fh seekToFileOffset:start];
		}
		else if(finderflags&0x20)
		{
			if(datasize||!rsrcsize)
			{
				[self addEntryWithDictionary:[NSMutableDictionary dictionaryWithObjectsAndKeys:
					name,XADFileNameKey,
					@(datasize),XADFileSizeKey,
					@(datasize),XADCompressedSizeKey,
					[NSDate XADDateWithTimeIntervalSince1904:modification],XADLastModificationDateKey,
					[NSDate XADDateWithTimeIntervalSince1904:creation],XADCreationDateKey,
					@(type),XADFileTypeKey,
					@(creator),XADFileCreatorKey,
					@(finderflags),XADFinderFlagsKey,
					[self XADStringWithString:[self nameForMethod:0]],XADCompressionNameKey,

					@(start),XADDataOffsetKey,
					@(datasize),XADDataLengthKey,
					@0,@"DiskDoublerMethod",
					@(datacrc),@"DiskDoublerCRC",
					@0,@"DiskDoublerDeltaType",
				nil]];
			}

			if(rsrcsize)
			{
				[self addEntryWithDictionary:[NSMutableDictionary dictionaryWithObjectsAndKeys:
					name,XADFileNameKey,
					@(rsrcsize),XADFileSizeKey,
					@(rsrcsize),XADCompressedSizeKey,
					[NSDate XADDateWithTimeIntervalSince1904:modification],XADLastModificationDateKey,
					[NSDate XADDateWithTimeIntervalSince1904:creation],XADCreationDateKey,
					@(type),XADFileTypeKey,
					@(creator),XADFileCreatorKey,
					@(finderflags),XADFinderFlagsKey,
					[self XADStringWithString:[self nameForMethod:0]],XADCompressionNameKey,
					@YES,XADIsResourceForkKey,

					@(start+datasize),XADDataOffsetKey,
					@(rsrcsize),XADDataLengthKey,
					@0,@"DiskDoublerMethod",
					@(rsrccrc),@"DiskDoublerCRC",
					@0,@"DiskDoublerDeltaType",
				nil]];
			}

			[fh seekToFileOffset:start+datasize+rsrcsize];
		}
		else
		{
			uint32_t filemagic=[fh readID];
			if(filemagic!=0xabcd0054) [XADException raiseIllegalDataException];
			uint32_t totalsize=[self parseFileHeaderWithHandle:fh name:name];

			[fh seekToFileOffset:start+84+totalsize];
		}
	}
}

-(void)parseArchive2
{
	CSHandle *fh=self.handle;
	[fh skipBytes:58];

	XADPath *currdir=self.XADPath;
	int lastdirlevel=0;

	while(self.shouldKeepParsing)
	{
		off_t start=fh.offsetInFile;

		uint32_t magic=[fh readID];
		if(magic!='DDA2') [XADException raiseIllegalDataException];

		int entrytype=[fh readUInt16BE];
		if(entrytype==0xbbbb) break;

		int namelen=[fh readUInt8];
		if(namelen>31) namelen=31;
		uint8_t namebuf[31];
		[fh readBytes:31 toBuffer:namebuf];

		int dirlevel=[fh readUInt32BE]-2;
		uint32_t totalsize=[fh readUInt32BE];

		if(dirlevel<0)
		{
			[fh seekToFileOffset:start+totalsize];
			continue;
		}

		for(int i=dirlevel;i<lastdirlevel;i++) currdir=currdir.pathByDeletingLastPathComponent;
		lastdirlevel=dirlevel;

		XADPath *name=[currdir pathByAppendingXADStringComponent:[self XADStringWithBytes:namebuf length:namelen]];

		if(entrytype&0x8000)
		{
			if(dirlevel>=0) // ignore top-level directory
			{
				[fh skipBytes:8];
				uint32_t creation=[fh readUInt32BE];
				uint32_t modification=[fh readUInt32BE];

				NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithObjectsAndKeys:
					name,XADFileNameKey,
					[NSDate XADDateWithTimeIntervalSince1904:creation],XADCreationDateKey,
					[NSDate XADDateWithTimeIntervalSince1904:modification],XADLastModificationDateKey,
					@YES,XADIsDirectoryKey,
				nil];

				[self addEntryWithDictionary:dict];
				currdir=name;
			}
		}
		else
		{
			[fh skipBytes:10];
			uint32_t filemagic=[fh readID];
			if(filemagic!=0xabcd0054) [XADException raiseIllegalDataException];

			[self parseFileHeaderWithHandle:fh name:name];
		}

		[fh seekToFileOffset:start+totalsize];
	}
}

-(uint32_t)parseFileHeaderWithHandle:(CSHandle *)fh name:(XADPath *)name
{
	uint32_t datasize=[fh readUInt32BE];
	uint32_t datacompsize=[fh readUInt32BE];
	uint32_t rsrcsize=[fh readUInt32BE];
	uint32_t rsrccompsize=[fh readUInt32BE];
	uint32_t datamethod=[fh readUInt8];
	uint32_t rsrcmethod=[fh readUInt8];
	int info1=[fh readUInt8];
	[fh skipBytes:1];
	uint32_t modification=[fh readUInt32BE];
	uint32_t creation=[fh readUInt32BE];
	uint32_t type=[fh readUInt32BE];
	uint32_t creator=[fh readUInt32BE];
	int finderflags=[fh readUInt16BE];
	[fh skipBytes:6];
	int datacrc=[fh readUInt16BE];
	int rsrccrc=[fh readUInt16BE];
	int info2=[fh readUInt8];
	[fh skipBytes:1];
	int datadelta=[fh readUInt16BE];
	int rsrcdelta=[fh readUInt16BE];
	[fh skipBytes:20];
	int datacrc2=[fh readUInt16BE];
	int rsrccrc2=[fh readUInt16BE];
	[fh skipBytes:2];

	off_t start=fh.offsetInFile;

	if(datasize||!rsrcsize)
	{
		[self addEntryWithDictionary:[NSMutableDictionary dictionaryWithObjectsAndKeys:
			name,XADFileNameKey,
			@(datasize),XADFileSizeKey,
			@(datacompsize),XADCompressedSizeKey,
			[NSDate XADDateWithTimeIntervalSince1904:modification],XADLastModificationDateKey,
			[NSDate XADDateWithTimeIntervalSince1904:creation],XADCreationDateKey,
			@(type),XADFileTypeKey,
			@(creator),XADFileCreatorKey,
			@(finderflags),XADFinderFlagsKey,
			[self XADStringWithString:[self nameForMethod:datamethod]],XADCompressionNameKey,

			@(start),XADDataOffsetKey,
			@(datacompsize),XADDataLengthKey,
			@(datamethod),@"DiskDoublerMethod",
			@(datacrc),@"DiskDoublerCRC",
			@(datacrc2),@"DiskDoublerCRC2",
			@(datadelta),@"DiskDoublerDeltaType",
			@(info1),@"DiskDoublerInfo1",
			@(info2),@"DiskDoublerInfo2",
		nil]];
	}

	if(rsrcsize)
	{
		[self addEntryWithDictionary:[NSMutableDictionary dictionaryWithObjectsAndKeys:
			name,XADFileNameKey,
			@(rsrcsize),XADFileSizeKey,
			@(rsrccompsize),XADCompressedSizeKey,
			[NSDate XADDateWithTimeIntervalSince1904:modification],XADLastModificationDateKey,
			[NSDate XADDateWithTimeIntervalSince1904:creation],XADCreationDateKey,
			@(type),XADFileTypeKey,
			@(creator),XADFileCreatorKey,
			@(finderflags),XADFinderFlagsKey,
			[self XADStringWithString:[self nameForMethod:rsrcmethod]],XADCompressionNameKey,
			@YES,XADIsResourceForkKey,

			@(start+datacompsize),XADDataOffsetKey,
			@(rsrccompsize),XADDataLengthKey,
			@(rsrcmethod),@"DiskDoublerMethod",
			@(rsrccrc),@"DiskDoublerCRC",
			@(rsrccrc2),@"DiskDoublerCRC2",
			@(rsrcdelta),@"DiskDoublerDeltaType",
			@(info1),@"DiskDoublerInfo1",
			@(info2),@"DiskDoublerInfo2",
		nil]];
	}

	return datacompsize+rsrccompsize;
}

-(NSString *)nameForMethod:(int)method
{
	switch(method&0x7f)
	{
		case 0: return @"None";
		case 1: return @"Compress";
		case 2: return @"Method 2"; // Name unknown
		case 3: return @"RLE"; // No support or testcases
		case 4: return @"Huffman"; // packit? - No support or testcases
		case 5: return @"Method 5"; // Almost same as method 2, but untested.
		case 6: return @"ADS/AD2";
		case 7: return @"Stac LZS";
		case 8: return @"Compact Pro";
		case 9: return @"AD/AD1";
		case 10: return @"DDn";
		default: return [NSString stringWithFormat:@"Method %d",method&0x7f];
	}
}

-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum
{
	if(dict[XADIsDirectoryKey]) return nil;

	CSHandle *handle=[self handleAtDataOffsetForDictionary:dict];
	off_t size=[dict[XADFileSizeKey] longLongValue];

	int method=[dict[@"DiskDoublerMethod"] intValue];
	int info1=[dict[@"DiskDoublerInfo1"] intValue];
	int info2=[dict[@"DiskDoublerInfo2"] intValue];
	int correctchecksum=[dict[@"DiskDoublerCRC"] intValue];

	switch(method&0x7f)
	{
		case 0: // No compression
		break;

		case 1: // Compress
		{
			int xor=0;
			if(info1>=0x2a&&(info2&0x80)==0) xor=0x5a;

			int m1=[handle readUInt8]^xor;
			int m2=[handle readUInt8]^xor;
			int flags=[handle readUInt8]^xor;

			handle=[[XADCompressHandle alloc] initWithHandle:handle
			length:size flags:flags];

			if(xor) handle=[[XADXORHandle alloc] initWithHandle:handle
			password:[NSData dataWithBytes:(uint8_t[]){xor} length:1]];

			if(checksum)
			{
				handle=[[XADChecksumHandle alloc] initWithHandle:handle length:size
				correctChecksum:correctchecksum-m1-m2-flags
				mask:0xffff];
			}
		}
		break;

		case 2: // Method 2
		case 5: // Method 5 - Untested!
		{
			int xor=0;
			if(info1>=0x2a&&(info2&0x80)==0) xor=0x5a;

			int numtrees;

			if((method&0x7f)==5)
			{
				[self reportInterestingFileWithReason:@"Untested compression method 5"];

				numtrees=[handle readUInt8];
				if(numtrees==0) numtrees=256;
			}
			else
			{
				numtrees=256;
			}

			handle=[[XADDiskDoublerMethod2Handle alloc]
			initWithHandle:handle length:size numberOfTrees:numtrees];

			if(xor) handle=[[XADXORHandle alloc] initWithHandle:handle
			password:[NSData dataWithBytes:(uint8_t[]){xor} length:1]];

			if(checksum)
			{
				handle=[[XADChecksumHandle alloc] initWithHandle:handle length:size
				correctChecksum:correctchecksum mask:0xffff];
			}
		}
		break;

		case 4: // Huffman - Untested!
		{
			[self reportInterestingFileWithReason:@"Untested compression method 4 (huffman)"];

			int xor=0;
			if(info1>=0x2a&&(info2&0x80)==0) xor=0x5a;

			handle=[[XADStuffItHuffmanHandle alloc] initWithHandle:handle
			length:size];

			if(xor) handle=[[XADXORHandle alloc] initWithHandle:handle
			password:[NSData dataWithBytes:(uint8_t[]){xor}length:1]];

			if(checksum)
			{
				handle=[[XADChecksumHandle alloc] initWithHandle:handle length:size
				correctChecksum:correctchecksum mask:0xffff];
			}
		}
		break;

		case 7: // Stac LZS
		{
			[handle skipBytes:6];
			uint32_t numentries=[handle readUInt32BE];

			[handle skipBytes:8+2*numentries];

			handle=[[XADXORHandle alloc] initWithHandle:handle
			password:[NSData dataWithBytes:(uint8_t[]){0xff} length:1]];

			handle=[[XADStacLZSHandle alloc] initWithHandle:handle
			length:size];

			handle=[[XADXORHandle alloc] initWithHandle:handle
			password:[NSData dataWithBytes:(uint8_t[]){0xff} length:1]];

			if(checksum)
			{
				if((size&1)==0) correctchecksum^=0xff;
				handle=[[XADXORSumHandle alloc] initWithHandle:handle length:size
				correctChecksum:correctchecksum];
			}
		}
		break;

		case 8: // Compact Pro
		{
			int sub=0;
			for(int i=0;i<16;i++) sub+=[handle readUInt8];

			if(sub==0) handle=[[XADCompactProLZHHandle alloc]
			initWithHandle:handle blockSize:0xfff0];

			handle=[[XADCompactProRLEHandle alloc] initWithHandle:handle
			length:size];

			if(checksum)
			{
				handle=[XADCRCHandle IBMCRC16HandleWithHandle:handle length:size
				correctCRC:correctchecksum conditioned:NO];
			}
		}
		break;

		case 6:
		case 9: // DiskDoubler AD
		{
			handle=[[XADDiskDoublerADnHandle alloc] initWithHandle:handle length:size];
		}
		break;

		case 10: // DiskDoubler DD
		{
			handle=[[XADDiskDoublerDDnHandle alloc] initWithHandle:handle length:size];
		}
		break;

		default:
			[self reportInterestingFileWithReason:@"Unsupported compression method %d",method&0x7f];
			return nil;
	}

	int delta=[dict[@"DiskDoublerDeltaType"] intValue];
	switch(delta)
	{
		case 0: break; // No delta processing

		case 1:
			handle=[[XADDeltaHandle alloc] initWithHandle:handle length:size];
		break;

		default:
			[self reportInterestingFileWithReason:@"Unsupported preprocessing method %d",delta];
			return nil;
	}

	return handle;
}

-(NSString *)formatName
{
	return @"DiskDoubler";
}

@end



