/*
 * XADARCParser.m
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
#import "XADARCParser.h"
#import "XADARCCrunchHandle.h"
#import "XADARCCrushHandle.h"
#import "XADARCDistillHandle.h"
#import "XADRLE90Handle.h"
#import "XADSqueezeHandle.h"
#import "XADCompressHandle.h"
#import "XADCRCHandle.h"
#import "XADXORHandle.h"
#import "NSDateXAD.h"

static BOOL IsLoaderARCName(const uint8_t *bytes)
{
	return memcmp(&bytes[2]," unpacker ",11)==0;
}

static BOOL IsRegularARCName(const uint8_t *bytes)
{
	if(bytes[0]==0) return NO;
	for(int i=0;i<0x0d && bytes[i]!=0;i++) if(bytes[i]<32) return NO;
	return YES;
}

static BOOL IsARCHeader(const uint8_t *bytes,int length,BOOL acceptloader)
{
	if(length<0x1d) return NO;

	// Check ID.
	if(bytes[0x00]!=0x1a) return NO;

	// Check file name.
	if(acceptloader)
	{
		if(!IsLoaderARCName(&bytes[2]))
		if(!IsRegularARCName(&bytes[2])) return NO;
	}
	else
	{
		if(IsLoaderARCName(&bytes[2])) return NO;
		if(!IsRegularARCName(&bytes[2])) return NO;
	}

	// Simplified checks if the file is an old-style uncompressed file.
	if(bytes[0x01]==0x01)
	{
		uint32_t size=CSUInt32LE(&bytes[0x0f]);
		if(size>0x1000000) return NO; // Assume files are less than 16 megabytes.

		// Check next file or end marker, if it fits in the buffer.
		uint32_t nextoffset=0x19+size;

		if(length>=nextoffset+1)
		if(bytes[nextoffset]!=0x1a) return NO;

		return YES;
	}
	else
	{
		// Check sizes.
		uint32_t compsize=CSUInt32LE(&bytes[0x0f]);
		uint32_t uncompsize=CSUInt32LE(&bytes[0x19]);
		if(uncompsize>0x1000000) return NO; // Assume files are less than 16 megabytes.
		if(compsize>uncompsize) return NO; // Assume files are always compressed or stored.

		// Check next file or end marker, if it fits in the buffer.
		uint32_t nextoffset=0x1d+compsize;
		if(bytes[0x01]&0x80) nextoffset+=12;

		if(length>=nextoffset+1)
		if(bytes[nextoffset]!=0x1a) return NO;

		return YES;
	}
}

@implementation XADARCParser

+(int)requiredHeaderSize { return 0x1d; }

+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name
{
	const uint8_t *bytes=data.bytes;
	NSInteger length=data.length;

	return IsARCHeader(bytes,(int)MIN(length, INT32_MAX),NO);
}

-(void)parse
{
	CSHandle *fh=self.handle;

	XADPath *parent=self.XADPath;

	while(self.shouldKeepParsing && !fh.atEndOfFile)
	{
		// Scan for next header.
		int n=0;
		for(;;)
		{
			int magic=[fh readUInt8];
			if(magic==0x1a) break;
			if(++n>=64) [XADException raiseIllegalDataException];
		}

		int method=[fh readUInt8];
		if(method==0x00) break;

		if(method==0x1f || method==0x80)
		{
			if(parent.empty) break;
			parent=parent.pathByDeletingLastPathComponent;
			continue;
		}

		uint8_t namebuf[13];
		[fh readBytes:13 toBuffer:namebuf];

		int namelength=0;
		while(namelength<12 && namebuf[namelength]!=0) namelength++;
		if(namelength>1 && namebuf[namelength-1]==' ') namelength--;
		if(namelength>1 && namebuf[namelength-1]=='.') namelength--;
		NSData *namedata=[NSData dataWithBytes:namebuf length:namelength];

		uint32_t compsize=[fh readUInt32LE];
		uint16_t date=[fh readUInt16LE];
		uint16_t time=[fh readUInt16LE];
		uint16_t crc16=[fh readUInt16LE];

		uint32_t uncompsize;
		if(method==1) uncompsize=compsize;
		else uncompsize=[fh readUInt32LE];

		uint32_t loadaddress=0,execaddress=0,fileattrs=0;
		if(method&0x80)
		{
			loadaddress=[fh readUInt32LE];
			execaddress=[fh readUInt32LE];
			fileattrs=[fh readUInt32LE];
		}

		off_t dataoffset=fh.offsetInFile;

		XADString *name=[self XADStringWithData:namedata];
		XADPath *path=[parent pathByAppendingXADStringComponent:name];

		if(method==0x1e || (method==0x82 && ((loadaddress&0xffffff00)==0xfffddc00)))
		{
			NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithObjectsAndKeys:
				path,XADFileNameKey,
				@YES,XADIsDirectoryKey,
				[NSDate XADDateWithMSDOSDate:date time:time],XADLastModificationDateKey,
				@(method),@"ARCMethod",
			nil];

			[self addEntryWithDictionary:dict];

			parent=path;
		}
		else
		{
			NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithObjectsAndKeys:
				path,XADFileNameKey,
				@(uncompsize),XADFileSizeKey,
				@(compsize),XADCompressedSizeKey,
				@(dataoffset),XADDataOffsetKey,
				@(compsize),XADDataLengthKey,
				[NSDate XADDateWithMSDOSDate:date time:time],XADLastModificationDateKey,
				@(method),@"ARCMethod",
				@(crc16),@"ARCCRC16",
			nil];

			NSString *methodname=nil;
			switch(method&0x7f)
			{
				case 0x01: methodname=@"None (old)"; break;
				case 0x02: methodname=@"None"; break;
				case 0x03: methodname=@"Packed"; break;
				case 0x04: methodname=@"Squeezed"; break;
				case 0x05: methodname=@"Crunched (no packing)"; break;
				case 0x06: methodname=@"Crunched"; break;
				case 0x07: methodname=@"Crunched (fast)"; break;
				case 0x08: methodname=@"Crunched (LZW)"; break;
				case 0x09: methodname=@"Squashed"; break;
				case 0x0a: methodname=@"Crushed"; break;
				case 0x0b: methodname=@"Distilled"; break;
				case 0x7f: methodname=@"Compressed"; break;
			}
			if(methodname) dict[XADCompressionNameKey] = [self XADStringWithString:methodname];

			if(method&0x80)
			{
				dict[@"ARCArchimedesLoadAddress"] = @(loadaddress);
				dict[@"ARCArchimedesExecAddress"] = @(execaddress);
				dict[@"ARCArchimedesFileAttributes"] = @(fileattrs);
			}

			[self addEntryWithDictionary:dict];

			[fh seekToFileOffset:dataoffset+compsize];
		}
	}
}

-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum
{
	if(dict[XADIsDirectoryKey]) return nil;

	CSHandle *handle=[self handleAtDataOffsetForDictionary:dict];
	int method=[dict[@"ARCMethod"] intValue];
	int crc=[dict[@"ARCCRC16"] intValue];
	uint32_t length=[dict[XADFileSizeKey] unsignedIntValue];

	// TODO: We should somehow figure out if an ARC file is actually encrypted.
	// However, there seems to be no way to do this, so the client has to
	// explicitly set a password without being asked for one.
	if(self.hasPassword)
	{
		NSData *passdata=self.encodedPassword;
		handle=[[[XADXORHandle alloc] initWithHandle:handle password:passdata] autorelease];
	}

	switch(method&0x7f)
	{
		case 0x01: // Stored (untested)
			[self reportInterestingFileWithReason:@"Untested older stored file"];
		break;

		case 0x02: // Stored
		break;

		case 0x03: // Packed
			handle=[[[XADRLE90Handle alloc] initWithHandle:handle
			length:length] autorelease];
		break;

		case 0x04: // Squeezed+packed
			handle=[[[XADSqueezeHandle alloc] initWithHandle:handle] autorelease];

			handle=[[[XADRLE90Handle alloc] initWithHandle:handle
			length:length] autorelease];
		break;

		case 0x05: // Crunched
			handle=[[[XADARCCrunchHandle alloc] initWithHandle:handle
			length:length useFastHash:NO] autorelease];
		break;

		case 0x06: // Crunched+packed
			handle=[[[XADARCCrunchHandle alloc] initWithHandle:handle useFastHash:NO] autorelease];

			handle=[[[XADRLE90Handle alloc] initWithHandle:handle
			length:length] autorelease];
		break;

		case 0x07: // Crunched+packed (fast)
			handle=[[[XADARCCrunchHandle alloc] initWithHandle:handle useFastHash:YES] autorelease];

			handle=[[[XADRLE90Handle alloc] initWithHandle:handle
			length:length] autorelease];
		break;

		case 0x08: // Crunched+packed (LZW)
		{
			int byte=[handle readUInt8];
			if(byte!=0x0c) [XADException raiseIllegalDataException];

			handle=[[[XADCompressHandle alloc] initWithHandle:handle
			flags:0x8c] autorelease];

			handle=[[[XADRLE90Handle alloc] initWithHandle:handle
			length:length] autorelease];
		}
		break;

		case 0x09: // Squashed
			handle=[[[XADCompressHandle alloc] initWithHandle:handle
			length:length flags:0x8d] autorelease];
		break;

		case 0x0a: // Crushed
			handle=[[[XADARCCrushHandle alloc] initWithHandle:handle] autorelease];

			handle=[[[XADRLE90Handle alloc] initWithHandle:handle
			length:length] autorelease];
		break;

		case 0x0b: // Distilled
			handle=[[[XADARCDistillHandle alloc] initWithHandle:handle
			length:length] autorelease];
		break;

		case 0x7f: // Compressed (untested)
		{
			[self reportInterestingFileWithReason:@"Untested compression method 0x7f (compress)"];

			int byte=[handle readUInt8];

			handle=[[[XADCompressHandle alloc] initWithHandle:handle
			length:length flags:byte|0x80] autorelease];
		}
		break;

		default:
			[self reportInterestingFileWithReason:@"Unsupported compression method %d",method];
			return nil;
	}

	if(checksum) handle=[XADCRCHandle IBMCRC16HandleWithHandle:handle length:length correctCRC:crc conditioned:NO];

	return handle;
}

-(NSString *)formatName { return @"ARC"; }

@end




@implementation XADARCSFXParser

+(int)requiredHeaderSize { return 0x10000; }

+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name propertiesToAdd:(NSMutableDictionary *)props
{
	const uint8_t *bytes=data.bytes;
	NSInteger length=data.length;

	// .COM executable, type ARC520.COM. Mangled first entry contains a jump
	// to unpack code in first entry, which we skip.
	if(IsARCHeader(&bytes[0],(int)MIN(length, INT32_MAX),YES))
	{
		uint32_t datasize=CSUInt32LE(&bytes[0x0f]);
		uint32_t nextoffs;
		if(bytes[1]==1) nextoffs=datasize+0x19;
		else nextoffs=datasize+0x1d;

		props[@"ARCSFXOffset"] = @(nextoffs);
		return YES;
	}

	// .COM executable, type ARC512.COM. Archive is preceeded by a three-byte
	// jump to code in a (mangled?) first entry, which we skip.
	if(IsARCHeader(&bytes[3],(int)MIN(length-3, INT32_MAX-3),YES))
	{
		uint32_t datasize=CSUInt32LE(&bytes[0x0f+3]);

		uint32_t nextoffs;
		if(bytes[1+3]==1) nextoffs=datasize+0x19+3;
		else nextoffs=datasize+0x1d+3;

		props[@"ARCSFXOffset"] = @(nextoffs);
		return YES;
	}

	// .EXE executable. Scan for an archive start.
	if(length>2)
	if(bytes[0]=='M'&&bytes[1]=='Z')
	{
		for(NSInteger i=2;i<=length-0x1d /*&& i<0x10000-0x1d*/;i++)
		{
			if(IsARCHeader(&bytes[i],(int)(length-i),NO))
			{
				props[@"ARCSFXOffset"] = @(i);
				return YES;
			}
		}
	}

	return NO;
}

-(void)parse
{
	CSHandle *fh=self.handle;

	off_t offs=[self.properties[@"ARCSFXOffset"] longLongValue];

	[fh seekToFileOffset:offs];

	[super parse];
}


-(NSString *)formatName { return @"Self-extracting ARC"; }

@end





