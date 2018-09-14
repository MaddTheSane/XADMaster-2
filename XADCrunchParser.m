#import "XADCrunchParser.h"
#import "XADCrunchHandles.h"
#import "XADRLE90Handle.h"
#import "XADChecksumHandle.h"
#import "NSDateXAD.h"

@implementation XADCrunchParser

+(NSMutableDictionary *)parseWithHandle:(CSHandle *)fh endOffset:(off_t)end parser:(XADArchiveParser *)parser
{
	int magic=[fh readUInt8];
	if(magic!=0x76) return nil;

	int type=[fh readUInt8];
	if(type!=0xfe && type!=0xfd) return nil;

	NSMutableData *data=[NSMutableData data];
	uint8_t byte;
	while((byte=[fh readUInt8])) [data appendBytes:&byte length:1];

	const char *bytes=data.bytes;
	NSInteger length=data.length;

	NSData *namepart=data;
	NSData *comment=nil;
	NSInteger namelength;
	for(NSInteger i=0;i<length;i++)
	{
		if(bytes[i]=='.')
		{
			namelength=i+4;
			if(namelength>length||bytes[namelength-1]==' ') namelength--;
			if(namelength>length||bytes[namelength-1]==' ') namelength--;
			if(namelength>length||bytes[namelength-1]==' ') namelength--;

			namepart=[data subdataWithRange:NSMakeRange(0,namelength)];

			if(i+7<length && bytes[i+4]==' ' && bytes[i+5]=='[' && bytes[length-1]==']')
			comment=[data subdataWithRange:NSMakeRange(i+6,length-i-7)];

			break;
		}
	}

	int version1=[fh readUInt8];
	int version2=[fh readUInt8];
	int errordetection=[fh readUInt8];
	[fh skipBytes:1];

	NSString *compname;
	BOOL old=(version2&0xf0)==0x10;
	if(type==0xfe)
	{
		if(old) compname=@"LZW 1.0";
		else compname=@"LZW 2.0";
	}
	else
	{
		if(old) compname=@"LZHUF 1.0";
		else compname=@"LZHUF 2.0";
	}

	off_t dataoffset=fh.offsetInFile;

	NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithObjectsAndKeys:
		[parser XADPathWithData:namepart separators:XADNoPathSeparator],XADFileNameKey,
		[parser XADStringWithString:compname],XADCompressionNameKey,
		@(end-dataoffset-2),XADCompressedSizeKey,
		@(dataoffset),XADDataOffsetKey,
		@(end-dataoffset),XADDataLengthKey,
		@(type),@"CrunchType",
		@(version1),@"CrunchReferenceRevision",
		@(version2),@"CrunchSignificantRevision",
		@(errordetection),@"CrunchErrorDetection",
	nil];

	if(comment) dict[XADCommentKey] = [parser XADStringWithData:comment];

	return dict;
}

+(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum handle:(CSHandle *)handle
{
	int type=[dict[@"CrunchType"] intValue];
	int version2=[dict[@"CrunchSignificantRevision"] intValue];
	int errordetection=[dict[@"CrunchErrorDetection"] intValue];
	BOOL old=(version2&0xf0)==0x10;
	BOOL haschecksum=errordetection==0;

	if(type==0xfe) handle=[[[XADCrunchZHandle alloc] initWithHandle:handle old:old hasChecksum:haschecksum] autorelease];
	else handle=[[[XADCrunchYHandle alloc] initWithHandle:handle old:old hasChecksum:haschecksum] autorelease];

	return handle;
}




+(int)requiredHeaderSize { return 1024; }

+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name
{
	const uint8_t *bytes=data.bytes;
	NSInteger length=data.length;

	if(length<9) return NO;

	if(bytes[0]!=0x76 || (bytes[1]!=0xfe && bytes[1]!=0xfd)) return NO;

	if(bytes[2]==0) return NO;
	for(NSInteger i=2;i<length;i++)
	{
		if(bytes[i]==0)
		{
			if(i+4>length) return NO;
			if(bytes[i+1]<0x10||bytes[i+1]>0x2f) return NO;
			if(bytes[i+2]<0x10||bytes[i+2]>0x2f) return NO;
			return YES;
		}
		//if(bytes[i]<32) return NO;
	}

	return NO;
}

-(void)parse
{
	CSHandle *fh=self.handle;

	NSMutableDictionary *dict=[XADCrunchParser parseWithHandle:fh
	endOffset:fh.fileSize parser:self];

	XADPath *filename=dict[XADFileNameKey];
	NSData *namedata=filename.data;
	const char *bytes=namedata.bytes;
	NSInteger length=namedata.length;

	if(length>4)
	if(bytes[length-4]=='.')
	if(tolower(bytes[length-3])=='l')
	if(tolower(bytes[length-2])=='b')
	if(tolower(bytes[length-1])=='r')
	{
		dict[XADIsArchiveKey] = @YES;
	}

	[self addEntryWithDictionary:dict];
}

-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum
{
	CSHandle *handle=[self handleAtDataOffsetForDictionary:dict];
	return [XADCrunchParser handleForEntryWithDictionary:dict wantChecksum:checksum handle:handle];
}

-(NSString *)formatName { return @"Crunch"; }

@end




