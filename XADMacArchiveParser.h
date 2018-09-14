#import "XADArchiveParser.h"
#import "CSStreamHandle.h"

extern XADArchiveKeys const XADIsMacBinaryKey;
extern XADArchiveKeys const XADMightBeMacBinaryKey;
extern XADArchiveKeys const XADDisableMacForkExpansionKey;

@interface XADMacArchiveParser:XADArchiveParser
{
	XADPath *previousname;
	NSMutableArray *dittodirectorystack;

	NSMutableDictionary *queueddittoentry;
	NSData *queueddittodata;

	NSMutableDictionary *cachedentry;
	NSData *cacheddata;
	CSHandle *cachedhandle;
}

+(int)macBinaryVersionForHeader:(NSData *)header;

-(instancetype)init;

-(void)parse;
-(void)parseWithSeparateMacForks;

-(void)addEntryWithDictionary:(NSMutableDictionary<XADArchiveKeys,id> *)dict retainPosition:(BOOL)retainpos;

-(BOOL)parseAppleDoubleWithDictionary:(NSMutableDictionary<XADArchiveKeys,id> *)dict
name:(XADPath *)name retainPosition:(BOOL)retainpos;

@property (NS_NONATOMIC_IOSONLY, retain) XADPath *previousFilename;
-(XADPath *)topOfDittoDirectoryStack;
-(void)pushDittoDirectory:(XADPath *)directory;
-(void)popDittoDirectoryStackUntilCanonicalPrefixFor:(XADPath *)path;

-(void)queueDittoDictionary:(NSMutableDictionary<XADArchiveKeys,id> *)dict data:(NSData *)data;
-(void)addQueuedDittoDictionaryAndRetainPosition:(BOOL)retainpos;
-(void)addQueuedDittoDictionaryWithName:(XADPath *)newname
isDirectory:(BOOL)isdir retainPosition:(BOOL)retainpos;

-(BOOL)parseMacBinaryWithDictionary:(NSMutableDictionary<XADArchiveKeys,id> *)dict
name:(XADPath *)name retainPosition:(BOOL)retainpos;

-(void)addEntryWithDictionary:(NSMutableDictionary<XADArchiveKeys,id> *)dict
retainPosition:(BOOL)retainpos data:(NSData *)data;
-(void)addEntryWithDictionary:(NSMutableDictionary<XADArchiveKeys,id> *)dict
retainPosition:(BOOL)retainpos handle:(CSHandle *)handle;

-(CSHandle *)handleForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict wantChecksum:(BOOL)checksum;

-(NSString *)descriptionOfValueInDictionary:(NSDictionary<XADArchiveKeys,id> *)dict key:(NSString *)key;
-(NSString *)descriptionOfKey:(NSString *)key;

-(CSHandle *)rawHandleForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict wantChecksum:(BOOL)checksum;
-(void)inspectEntryDictionary:(NSMutableDictionary<XADArchiveKeys,id> *)dict;

@end
