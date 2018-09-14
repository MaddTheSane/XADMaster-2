#import "XADLZHParser.h"
#import "XADLZHStaticHandle.h"
#import "XADLZHDynamicHandle.h"
#import "XADLArcHandles.h"
#import "XADPMArc1Handle.h"
#import "XADLZHOldHandles.h"
#import "XADCRCHandle.h"
#import "NSDateXAD.h"

@implementation XADLZHParser

+(int)requiredHeaderSize { return 7; }

+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name
{
	const uint8_t *bytes=data.bytes;
	NSInteger length=data.length;

	if(length<7) return NO;

	if(bytes[2]=='-'&&bytes[3]=='l'&&bytes[4]=='h'&&bytes[6]=='-') // lzh files
	{
		if(bytes[5]=='0'||bytes[5]=='1') return YES; // uncompressed and old
		if(bytes[5]=='2'||bytes[5]=='3') return YES; // old experimental
		if(bytes[5]=='4'||bytes[5]=='5'||bytes[5]=='6'||bytes[5]=='7') return YES; // new
		if(bytes[5]=='d') return YES; // directory
	}

	if(bytes[2]=='-'&&bytes[3]=='l'&&bytes[4]=='z'&&bytes[6]=='-') // larc files
	{
		if(bytes[5]=='0'||bytes[5]=='4'||bytes[5]=='5') return YES;
	}

	if(bytes[2]=='-'&&bytes[3]=='p'&&bytes[4]=='m'&&bytes[6]=='-') // pmarc files
	{
		if(bytes[5]=='0'||bytes[5]=='1'||bytes[5]=='2') return YES;
	}

	return NO;
}

-(void)parseWithSeparateMacForks
{
	CSHandle *fh=self.handle;

	int guessedos=0;

	while(self.shouldKeepParsing && !fh.atEndOfFile)
	{
		off_t start=fh.offsetInFile;

		uint8_t b1=[fh readUInt8];
		if(b1==0) break;

		uint8_t b2=[fh readUInt8];

		int firstword=b1|(b2<<8);

		uint8_t method[5];
		[fh readBytes:5 toBuffer:method];

		uint32_t compsize=[fh readUInt32LE];
		uint32_t size=[fh readUInt32LE];
		uint32_t time=[fh readUInt32LE];

		int attrs=[fh readUInt8];
		int level=[fh readUInt8];

		NSString *compname=[[[NSString alloc] initWithBytes:method length:5 encoding:NSISOLatin1StringEncoding] autorelease];

		NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithObjectsAndKeys:
			@(size),XADFileSizeKey,
			[self XADStringWithString:compname],XADCompressionNameKey,
			@(level),@"LHAHeaderLevel",
		nil];

		uint32_t headersize;
		int os = 0;

		if(level==0||level==1)
		{
			headersize=(firstword&0xff)+2;

			dict[XADLastModificationDateKey] = [NSDate XADDateWithMSDOSDateTime:time];

			int namelen=[fh readUInt8];
			uint8_t namebuffer[namelen];
			[fh readBytes:namelen toBuffer:namebuffer];

			int actualnamelen=0;
			while(actualnamelen<namelen)
			{
				if(namebuffer[actualnamelen]==0)
				{
					dict[XADCommentKey] = [self XADStringWithBytes:&namebuffer[actualnamelen+1]
					length:namelen-actualnamelen-1];
					break;
				}
				actualnamelen++;
			}

			dict[@"LHAHeaderFileNameData"] = [NSData dataWithBytes:namebuffer length:actualnamelen];

			int crc=[fh readUInt16LE];
			dict[@"LHACRC16"] = @(crc);

			if(level==1)
			{
				os=[fh readUInt8];
				dict[@"LHAOS"] = @(os);

				for(;;)
				{
					int extsize=[fh readUInt16LE];
					if(extsize==0) break;
					headersize+=extsize;
					compsize-=extsize;

					[self parseExtendedForDictionary:dict size:extsize-2];
				}
			}
		}
		else if(level==2)
		{
			[self reportInterestingFileWithReason:@"LZH level 2 file"];

			headersize=firstword;

			dict[XADLastModificationDateKey] = [NSDate dateWithTimeIntervalSince1970:time];

			int crc=[fh readUInt16LE];
			dict[@"LHACRC16"] = @(crc);

			os=[fh readUInt8];

			for(;;)
			{
				int extsize=[fh readUInt16LE];
				if(extsize==0) break;
				[self parseExtendedForDictionary:dict size:extsize-2];
			}
		}
		else if(level==3)
		{
			[self reportInterestingFileWithReason:@"LZH level 3 file"];

			if(firstword!=4) [XADException raiseNotSupportedException];

			dict[XADLastModificationDateKey] = [NSDate dateWithTimeIntervalSince1970:time];

			int crc=[fh readUInt16LE];
			dict[@"LHACRC16"] = @(crc);

			os=[fh readUInt8];

			headersize=[fh readUInt32LE];

			for(;;)
			{
				int extsize=[fh readUInt32LE];
				if(extsize==0) break;
				[self parseExtendedForDictionary:dict size:extsize-4];
			}
		}
		else { [XADException raiseIllegalDataException]; for(;;); }

		if(level==0)
		{
			if(!guessedos)
			{
				NSString *name=self.filename;

				if([name matchedByPattern:@"\\.(lha|run)$"
				options:REG_ICASE]) guessedos='A';
				else guessedos='M';
			}

			if(guessedos=='M')
			{
				dict[@"LHAGuessedOSName"] = [self XADStringWithString:@"MS-DOS"];
				dict[XADDOSFileAttributesKey] = @(attrs);
			}
			else
			{
				dict[@"LHAGuessedOSName"] = [self XADStringWithString:@"Amiga"];
				dict[XADAmigaProtectionBitsKey] = @(attrs);
			}
		}
		else
		{
			dict[@"LHAOS"] = @(os);

			NSString *osname=nil;
			switch(os)
			{
				case 'M': osname=@"MS-DOS"; break;
				case '2': osname=@"OS/2"; break;
				case '9': osname=@"OS9"; break;
				case 'K': osname=@"OS/68K"; break;
				case '3': osname=@"OS/386"; break;
				case 'H': osname=@"HUMAN"; break;
				case 'U': osname=@"Unix"; break;
				case 'C': osname=@"CP/M"; break;
				case 'F': osname=@"FLEX"; break;
				case 'm': osname=@"Mac OS"; break;
				case 'w': osname=@"Windows 95, 98"; break;
				case 'W': osname=@"Windows NT"; break;
				case 'R': osname=@"Runser"; break;
				case 'T': osname=@"TownsOS"; break;
				case 'X': osname=@"XOSK"; break;
				//case '': methodname=@""; break;
			}
			if(osname) dict[@"LHAOSName"] = [self XADStringWithString:osname];

			dict[XADDOSFileAttributesKey] = @(attrs);

			if(os=='m')
			{
				[self setIsMacArchive:YES];
				dict[XADMightBeMacBinaryKey] = @YES;
			}
		}

		[dict setValue:@(compsize) forKey:XADCompressedSizeKey];
		[dict setValue:@(compsize) forKey:XADDataLengthKey];
		[dict setValue:@(start+headersize) forKey:XADDataOffsetKey];

		if(memcmp(method,"-lhd-",5)==0) [dict setValue:@YES forKey:XADIsDirectoryKey];

		NSData *filenamedata=dict[@"LHAExtFileNameData"];
		if(!filenamedata) filenamedata=dict[@"LHAHeaderFileNameData"];
		NSData *directorydata=dict[@"LHAExtDirectoryData"];
		XADPath *path=nil;
		if(directorydata)
		{
			path=[self XADPathWithData:directorydata separators:"\xff"];
			if(filenamedata&&filenamedata.length)
			path=[path pathByAppendingXADStringComponent:[self XADStringWithData:filenamedata]];
		}
		else if(filenamedata)
		{
			path=[self XADPathWithData:filenamedata separators:"\xff\\/"];
		}

		if(path) dict[XADFileNameKey] = path;

		[self addEntryWithDictionary:dict];

		[fh seekToFileOffset:start+headersize+compsize];
	}
}

-(void)parseExtendedForDictionary:(NSMutableDictionary *)dict size:(int)size
{
	CSHandle *fh=self.handle;
	off_t nextpos=fh.offsetInFile+size;

	switch([fh readUInt8])
	{
		case 0x01:
			dict[@"LHAExtFileNameData"] = [fh readDataOfLength:size-1];
		break;

		case 0x02:
			dict[@"LHAExtDirectoryData"] = [fh readDataOfLength:size-1];
		break;

		case 0x3f:
		case 0x71:
			dict[XADCommentKey] = [self XADStringWithData:[fh readDataOfLength:size-1]];
		break;

		case 0x40:
			dict[XADDOSFileAttributesKey] = @([fh readUInt16LE]);
		break;

		case 0x41:
			dict[XADCreationDateKey] = [NSDate XADDateWithWindowsFileTimeLow:[fh readUInt32LE]
			high:[fh readUInt32LE]];
			dict[XADLastModificationDateKey] = [NSDate XADDateWithWindowsFileTimeLow:[fh readUInt32LE]
			high:[fh readUInt32LE]];
			dict[XADLastAccessDateKey] = [NSDate XADDateWithWindowsFileTimeLow:[fh readUInt32LE]
			high:[fh readUInt32LE]];
		break;

		case 0x42:
			// 64-bit file sizes
			[self reportInterestingFileWithReason:@"64-bit file"];
			[XADException raiseNotSupportedException];
		break;

		case 0x50:
			dict[XADPosixPermissionsKey] = @([fh readUInt16LE]);
		break;

		case 0x51:
			dict[XADPosixGroupKey] = @([fh readUInt16LE]);
			dict[XADPosixUserKey] = @([fh readUInt16LE]);
		break;

		case 0x52:
			dict[XADPosixGroupNameKey] = [self XADStringWithData:[fh readDataOfLength:size-1]];
		break;

		case 0x53:
			dict[XADPosixUserNameKey] = [self XADStringWithData:[fh readDataOfLength:size-1]];
		break;

		case 0x54:
			dict[XADLastModificationDateKey] = [NSDate dateWithTimeIntervalSince1970:[fh readUInt32LE]];
		break;

		case 0x7f:
			dict[XADDOSFileAttributesKey] = @([fh readUInt16LE]);
			dict[XADPosixPermissionsKey] = @([fh readUInt16LE]);
			dict[XADPosixGroupKey] = @([fh readUInt16LE]);
			dict[XADPosixUserKey] = @([fh readUInt16LE]);
			dict[XADCreationDateKey] = [NSDate dateWithTimeIntervalSince1970:[fh readUInt32LE]];
			dict[XADLastModificationDateKey] = [NSDate dateWithTimeIntervalSince1970:[fh readUInt32LE]];
		break;

		// case 0xc4: // compressed comment, -lh5- 4096
		// case 0xc5: // compressed comment, -lh5- 8192
		// case 0xc6: // compressed comment, -lh5- 16384
		// case 0xc7: // compressed comment, -lh5- 32768
		// case 0xc8: // compressed comment, -lh5- 65536

		case 0xff:
			dict[XADPosixPermissionsKey] = @([fh readUInt32LE]);
			dict[XADPosixGroupKey] = @([fh readUInt32LE]);
			dict[XADPosixUserKey] = @([fh readUInt32LE]);
			dict[XADCreationDateKey] = [NSDate dateWithTimeIntervalSince1970:[fh readUInt32LE]];
			dict[XADLastModificationDateKey] = [NSDate dateWithTimeIntervalSince1970:[fh readUInt32LE]];
		break;
	}

	[fh seekToFileOffset:nextpos];
}


-(CSHandle *)rawHandleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum
{
	CSHandle *handle=[self handleAtDataOffsetForDictionary:dict];
	off_t size=[dict[XADFileSizeKey] longLongValue];
	NSString *method=[dict[XADCompressionNameKey] string];
	int crc=[dict[@"LHACRC16"] intValue];

	if([method isEqual:@"-lh0-"])
	{
		// no compression, do nothing
	}
	else if([method isEqual:@"-lh1-"])
	{
		handle=[[[XADLZHDynamicHandle alloc] initWithHandle:handle length:size] autorelease];
	}
	else if([method isEqual:@"-lh2-"])
	{
		[self reportInterestingFileWithReason:@"-lh2- compression"];
		handle=[[[XADLZH2Handle alloc] initWithHandle:handle length:size] autorelease];
	}
	else if([method isEqual:@"-lh3-"])
	{
		[self reportInterestingFileWithReason:@"-lh3- compression"];
		handle=[[[XADLZH3Handle alloc] initWithHandle:handle length:size] autorelease];
	}
	else if([method isEqual:@"-lh4-"])
	{
		handle=[[[XADLZHStaticHandle alloc] initWithHandle:handle length:size windowBits:12] autorelease];
	}
	else if([method isEqual:@"-lh5-"])
	{
		handle=[[[XADLZHStaticHandle alloc] initWithHandle:handle length:size windowBits:13] autorelease];
	}
	else if([method isEqual:@"-lh6-"])
	{
		handle=[[[XADLZHStaticHandle alloc] initWithHandle:handle length:size windowBits:15] autorelease];
	}
	else if([method isEqual:@"-lh7-"])
	{
		handle=[[[XADLZHStaticHandle alloc] initWithHandle:handle length:size windowBits:16] autorelease];
	}
	else if([method isEqual:@"-lzs-"])
	{
		handle=[[[XADLArcLZSHandle alloc] initWithHandle:handle length:size] autorelease];
	}
	else if([method isEqual:@"-lz4-"])
	{
		// no compression, do nothing
	}
	else if([method isEqual:@"-lz5-"])
	{
		handle=[[[XADLArcLZ5Handle alloc] initWithHandle:handle length:size] autorelease];
	}
	else if([method isEqual:@"-pm0-"])
	{
		// no compression, do nothing
	}
	else if([method isEqual:@"-pm1-"])
	{
		handle=[[[XADPMArc1Handle alloc] initWithHandle:handle length:size] autorelease];
	}
	else if([method isEqual:@"-pm2-"])
	{
		handle=[[[XADPMArc2Handle alloc] initWithHandle:handle length:size] autorelease];
	}
	else // not supported
	{
		[self reportInterestingFileWithReason:@"Unsupported compression method %@",method];
		return nil; 
	}

	if(checksum) handle=[XADCRCHandle IBMCRC16HandleWithHandle:handle length:size correctCRC:crc conditioned:NO];

	return handle;
}

-(NSString *)formatName { return @"LZH"; }

@end
