#import "XADMacBinaryParser.h"

@implementation XADMacBinaryParser

+(int)requiredHeaderSize
{
	return 128;
}

+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name
{
	return [XADMacArchiveParser macBinaryVersionForHeader:data]>0;
}

-(void)parseWithSeparateMacForks
{
	[self setIsMacArchive:YES];

	[properties removeObjectForKey:XADDisableMacForkExpansionKey];
	[self addEntryWithDictionary:[NSMutableDictionary dictionaryWithObjectsAndKeys:
		@YES,XADIsMacBinaryKey,
	nil]];
}

-(CSHandle *)rawHandleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum
{
	return self.handle;
}

-(void)inspectEntryDictionary:(NSMutableDictionary *)dict
{
	NSNumber *rsrc=dict[XADIsResourceForkKey];
	if(rsrc&&rsrc.boolValue) return;

	if([self.name matchedByPattern:@"\\.sea(\\.|$)" options:REG_ICASE]||
	[[dict[XADFileNameKey] string] matchedByPattern:@"\\.(sea|sit|cpt)$" options:REG_ICASE])
	dict[XADIsArchiveKey] = @YES;

	// TODO: Better detection of embedded archives. Also applies to BinHex!
//	if([[dict objectForKey:XADFileTypeKey] unsignedIntValue]=='APPL')...
}

-(NSString *)formatName
{
	return @"MacBinary";
}

@end
