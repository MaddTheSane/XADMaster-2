#import "XADArchiveParser.h"
#import "PDF/PDFParser.h"

@interface XADPDFParser:XADArchiveParser
{
	PDFParser *parser;
}

+(int)requiredHeaderSize;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name;

-(instancetype)init;

-(void)parse;
-(NSString *)compressionNameForStream:(PDFStream *)stream excludingLast:(BOOL)excludelast;

-(CSHandle *)handleForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict wantChecksum:(BOOL)checksum;

-(NSString *)formatName;

@end

@interface XAD8BitPaletteExpansionHandle:CSByteStreamHandle
{
	NSData *palette;

	uint8_t bytebuffer[8];	
	int numchannels,currentchannel;
}

-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length
numberOfChannels:(int)numberofchannels palette:(NSData *)palettedata;

-(void)resetByteStream;
-(uint8_t)produceByteAtOffset:(off_t)pos;

@end
