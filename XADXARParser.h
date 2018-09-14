#import "XADArchiveParser.h"

@interface XADXARParser:XADArchiveParser <NSXMLParserDelegate>
{
	off_t heapoffset;
	int state;

	NSDictionary *filedefinitions,*datadefinitions,*eadefinitions;

	NSMutableDictionary *currfile,*currea;
	NSMutableArray *files,*filestack,*curreas;
	NSMutableString *currstring;
}

+(int)requiredHeaderSize;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name;

-(void)parse;

-(void)finishFile:(NSMutableDictionary *)file parentPath:(XADPath *)parentpath;
-(XADString *)compressionNameForEncodingStyle:(NSString *)encodingstyle isXIP:(BOOL)isxip;

-(void)startSimpleElement:(NSString *)name attributes:(NSDictionary *)attributes
definitions:(NSDictionary *)definitions destinationDictionary:(NSMutableDictionary *)dest;
-(void)endSimpleElement:(NSString *)name definitions:(NSDictionary *)definitions
destinationDictionary:(NSMutableDictionary *)dest;
-(void)parseDefinition:(NSArray *)definition string:(NSString *)string
destinationDictionary:(NSMutableDictionary *)dest;

-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum;
-(CSHandle *)handleForEncodingStyle:(NSString *)encodingstyle offset:(NSNumber *)offset
length:(NSNumber *)length size:(NSNumber *)size checksum:(NSData *)checksum checksumStyle:(NSString *)checksumstyle;

-(NSString *)formatName;

@end
