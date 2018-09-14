#import "XADCompressParser.h"
#import "XADCompressHandle.h"


@implementation XADCompressParser

+(int)requiredHeaderSize { return 3; }

+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name
{
	NSInteger length=data.length;
	const uint8_t *bytes=data.bytes;

	return length>=3&&bytes[0]==0x1f&&bytes[1]==0x9d;
}

-(void)parse
{
	CSHandle *fh=self.handle;

	[fh skipBytes:2];
	int flags=[fh readUInt8];

	NSString *contentname=self.name.stringByDeletingPathExtension;

	NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithObjectsAndKeys:
		[self XADPathWithUnseparatedString:contentname],XADFileNameKey,
		[self XADStringWithString:@"Compress"],XADCompressionNameKey,
		@3LL,XADDataOffsetKey,
		@(flags),@"CompressFlags",
	nil];

	if([contentname matchedByPattern:@"\\.(tar|cpio|pax)$" options:REG_ICASE])
	dict[XADIsArchiveKey] = @YES;

	off_t size=self.handle.fileSize;
	if(size!=CSHandleMaxLength)
	dict[XADCompressedSizeKey] = @(size-3);

	[self addEntryWithDictionary:dict];
}

-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum
{
	return [[[XADCompressHandle alloc] initWithHandle:[self handleAtDataOffsetForDictionary:dict]
	flags:[dict[@"CompressFlags"] intValue]] autorelease];
}

-(NSString *)formatName { return @"Compress"; }

@end
