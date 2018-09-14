#import "XADARJParser.h"
#import "XADARJFastestHandle.h"
#import "XADLZHStaticHandle.h"
#import "XADXORHandle.h"
#import "XADCRCHandle.h"
#import "NSDateXAD.h"
#import "CRC.h"

// TODO: Multi-volume support

static int StringLength(const char *str,const char *end);
static NSData *ReadNullTerminatedString(CSHandle *fh);

@implementation XADARJParser

+(int)requiredHeaderSize { return 0x8000; }

+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name
{
	const uint8_t *bytes=data.bytes;
	NSInteger length=data.length;

	if(length<40) return NO;

	for(NSInteger i=0;i<=length-4;i++)
	{
		if(bytes[i]==0x60&&bytes[i+1]==0xea)
		{
			int size=CSUInt16LE(&bytes[i+2]);
			if(size>=32 && size<=2600 && i+4+size+4<=length)
			{
				uint32_t headcrc=XADCalculateCRC(0xffffffff,&bytes[i+4],size,XADCRCTable_edb88320);
				uint32_t storedcrc=CSUInt32LE(&bytes[i+4+size]);
				if(storedcrc==~headcrc) return YES;
			}
		}
	}

	return NO;
}

-(void)parse
{
	CSHandle *fh=self.handle;

	int headersize;
	NSData *header;
	for(;;)
	{
		int byte;
		do byte=[fh readUInt8];
		while(byte==0x60);

		if(byte==0xea)
		{
			off_t pos=fh.offsetInFile;

			headersize=[fh readUInt16LE];
			if(headersize>=32 && headersize<=2600)
			{
				header=[fh readDataOfLength:headersize];
				uint32_t crc=[fh readUInt32LE];
				if(XADCalculateCRC(0xffffffff,header.bytes,headersize,XADCRCTable_edb88320)==~crc)
				break;
			}

			[fh seekToFileOffset:pos];
		}
	}

	const uint8_t *headerbytes=header.bytes;

	int firstsize=headerbytes[0];
	//int version=headerbytes[1];
	//int minversion=headerbytes[2];
	//int os=headerbytes[3];
	//int archiveflags=headerbytes[4];
	//int securityversion=headerbytes[5];
	int filetype=headerbytes[6];
	uint32_t archivecreataion=CSUInt32LE(&headerbytes[8]);
	uint32_t archivemodification=CSUInt32LE(&headerbytes[12]);
	//uint32_t archivesize=CSUInt32LE(&headerbytes[16]);
	//uint32_t securityoffs=CSUInt32LE(&headerbytes[20]);
	//int filespecpos=CSUInt16LE(&headerbytes[24]);
	//int securitylength=CSUInt16LE(&headerbytes[26]);

	if(filetype!=2) [XADException raiseIllegalDataException];

	const char *filename=(const char *)&headerbytes[firstsize];
	int filenamelen=StringLength(filename,(const char *)&headerbytes[headersize]);

	const char *comment=(const char *)&headerbytes[firstsize+filenamelen+1];
	int commentlen=StringLength(comment,(const char *)&headerbytes[headersize]);

	properties[XADCreationDateKey] = [NSDate XADDateWithMSDOSDateTime:archivecreataion];
	properties[XADLastModificationDateKey] = [NSDate XADDateWithMSDOSDateTime:archivemodification];
	if(filenamelen) properties[@"ARJOriginalArchiveName"] = [self XADStringWithBytes:filename length:filenamelen];
	if(commentlen) properties[XADCommentKey] = [self XADStringWithBytes:comment length:commentlen];

	int extlen=[fh readUInt16LE];
	if(extlen) [fh skipBytes:extlen+4];

	while(self.shouldKeepParsing)
	{
		if([fh readUInt8]!=0x60||[fh readUInt8]!=0xea) [XADException raiseIllegalDataException];

		int headersize=[fh readUInt16LE];
		if(headersize==0) break;
		if(headersize<32||headersize>2600) [XADException raiseIllegalDataException];

		int firstsize=[fh readUInt8];
		int version=[fh readUInt8];
		int minversion=[fh readUInt8];
		int os=[fh readUInt8];
		int flags=[fh readUInt8];
		int method=[fh readUInt8];
		int filetype=[fh readUInt8];
		int passwordmod=[fh readUInt8];
		uint32_t modification=[fh readUInt32LE];
		uint32_t compsize=[fh readUInt32LE];
		uint32_t size=[fh readUInt32LE];
		uint32_t crc=[fh readUInt32LE];
		/*int filespecoffs=*/[fh readUInt16LE];
		int accessmode=[fh readUInt16LE];
		[fh skipBytes:firstsize-28];

		NSData *filename=ReadNullTerminatedString(fh);
		NSData *comment=ReadNullTerminatedString(fh);

		/*uint32_t headcrc=*/[fh readUInt32LE];

		int extlen=[fh readUInt16LE];
		if(extlen) [fh skipBytes:extlen+4];

		XADPathSeparator separator;
		if(flags&0x10) separator=XADUnixPathSeparator;
		else separator=XADWindowsPathSeparator;

		off_t pos=fh.offsetInFile;

		NSDate *modificationdate;
		if(os==2) modificationdate=[NSDate dateWithTimeIntervalSince1970:modification];
		else modificationdate=[NSDate XADDateWithMSDOSDateTime:modification];

		NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithObjectsAndKeys:
			[self XADPathWithData:filename separators:separator],XADFileNameKey,
			@(pos),XADDataOffsetKey,
			@(compsize),XADDataLengthKey,
			@(compsize),XADCompressedSizeKey,
			@(size),XADFileSizeKey,
			modificationdate,XADLastModificationDateKey,
			@(accessmode),XADDOSFileAttributesKey,
			@(version),@"ARJVersion",
			@(minversion),@"ARJMinimumVersion",
			@(os),@"ARJOS",
			@(flags),@"ARJFlags",
			@(method),@"ARJMethod",
			@(filetype),@"ARJFileType",
			@(crc),@"ARJCRC32",
		nil];

		if(filetype==3) dict[XADIsDirectoryKey] = @YES;

		if(flags&0x01)
		{
			dict[XADIsEncryptedKey] = @YES;
			dict[@"ARJPasswordModifier"] = @(passwordmod);
		}

		NSString *osname=nil;
		switch(os)
		{
			case 0: osname=@"MS-DOS"; break;
			case 1: osname=@"PRIMOS"; break;
			case 2: osname=@"Unix"; break;
			case 3: osname=@"Amiga"; break;
			case 4: osname=@"Mac OS"; break;
			case 5: osname=@"OS/2"; break;
			case 6: osname=@"Apple GS"; break;
			case 7: osname=@"Atari ST"; break;
			case 8: osname=@"NeXT"; break;
			case 9: osname=@"VAX VMS"; break;
			case 10: osname=@"Windows 95"; break;
			case 11: osname=@"Win32"; break;
			default: osname=@"Unknown"; break;
		}
		dict[@"ARJOSName"] = [self XADStringWithString:osname];

		NSString *methodname=nil;
		switch(method)
		{
			case 0: methodname=@"None"; break;
			case 1: methodname=@"Most"; break;
			case 2: methodname=@"Medium"; break;
			case 3: methodname=@"Fast"; break;
			case 4: methodname=@"Fastest"; break;
			default: methodname=@"Unknown"; break;
		}
		dict[XADCompressionNameKey] = [self XADStringWithString:methodname];

		if(comment.length) dict[XADCommentKey] = [self XADStringWithData:comment];

		[self addEntryWithDictionary:dict];

		[fh seekToFileOffset:pos+compsize];
	}
}


-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum
{
	CSHandle *handle=[self handleAtDataOffsetForDictionary:dict];
	off_t size=[dict[XADFileSizeKey] longLongValue];
	int method=[dict[@"ARJMethod"] intValue];
	uint32_t crc=[dict[@"ARJCRC32"] unsignedIntValue];
	NSNumber *crypto=dict[XADIsEncryptedKey];

	if(crypto&&crypto.boolValue)
	{
		NSMutableData *passdata=[NSMutableData dataWithData:self.encodedPassword];
		uint8_t *passbytes=passdata.mutableBytes;
		int passlength=(int)passdata.length;
		int mod=[dict[@"ARJPasswordModifier"] intValue];

		for(int i=0;i<passlength;i++) passbytes[i]+=mod;

		handle=[[[XADXORHandle alloc] initWithHandle:handle password:passdata] autorelease];

		// TODO: Handle GOST-40 and GOST-256
	}

	switch(method)
	{
		case 0: // No compression
		break;

		case 1: // LZH compression
		case 2:
		case 3:
			handle=[[[XADLZHStaticHandle alloc] initWithHandle:handle length:size windowBits:15] autorelease];
		break;

		case 4: // Fast compression
			handle=[[[XADARJFastestHandle alloc] initWithHandle:handle length:size] autorelease];
		break;

		default:
			[self reportInterestingFileWithReason:@"Unsupported compression method %d",method];
			return nil;
	}

	if(checksum) handle=[XADCRCHandle IEEECRC32HandleWithHandle:handle length:size correctCRC:crc conditioned:YES];

	return handle;
}

-(NSString *)formatName { return @"ARJ"; }

@end

static int StringLength(const char *str,const char *end)
{
	int len=0;
	while(str+len<end && str[len]) len++;
	return len;
}

static NSData *ReadNullTerminatedString(CSHandle *fh)
{
	NSMutableData *data=[NSMutableData data];

	for(;;)
	{
		uint8_t byte=[fh readUInt8];
		if(!byte) break;
		[data appendBytes:&byte length:1];
	}

	return data;
}
