#import "XADMacArchiveParser.h"
#import "XADArchiveParserDescriptions.h"
#import "XADAppleDouble.h"
#import "CSMemoryHandle.h"
#import "NSDateXAD.h"
#import "CRC.h"

#if !__has_feature(objc_arc)
#error this file needs to be compiled with Automatic Reference Counting (ARC)
#endif

NSString *const XADIsMacBinaryKey=@"XADIsMacBinary";
NSString *const XADMightBeMacBinaryKey=@"XADMightBeMacBinary";
NSString *const XADDisableMacForkExpansionKey=@"XADDisableMacForkExpansionKey";

@implementation XADMacArchiveParser
@synthesize previousFilename = previousname;

+(int)macBinaryVersionForHeader:(NSData *)header
{
	if(header.length<128) return NO;
	const uint8_t *bytes=header.bytes;

	// Check zero fill bytes.
	if(bytes[0]!=0) return 0;
	if(bytes[74]!=0) return 0;
	if(bytes[82]!=0) return 0;
	for(int i=108;i<=115;i++) if(bytes[i]!=0) return 0;

	// Check for a valid name.
	if(bytes[1]==0||bytes[1]>63) return 0;
	for(int i=0;i<bytes[1];i++) if(bytes[i+2]==0) return 0;

	// Check for a valid checksum.
	if(XADCalculateCRC(0,bytes,124,XADCRCReverseTable_1021)==
	XADUnReverseCRC16(CSUInt16BE(bytes+124)))
	{
		// Check for a valid signature.
		if(CSUInt32BE(bytes+102)=='mBIN') return 3; // MacBinary III
		else return 2; // MacBinary II
	}

	// Some final heuristics before accepting a version I file.
	for(int i=99;i<=125;i++) if(bytes[i]!=0) return 0;
	if(CSUInt32BE(bytes+83)>0x7fffffff) return 0; // Data fork size
	if(CSUInt32BE(bytes+87)>0x7fffffff) return 0; // Resource fork size
	if(CSUInt32BE(bytes+91)==0) return 0; // Creation date
	if(CSUInt32BE(bytes+95)==0) return 0; // Last modified date

	return 1; // MacBinary I
}

-(id)init
{
	if((self=[super init]))
	{
		previousname=nil;
		dittodirectorystack=[NSMutableArray new];

		queueddittoentry=nil;
		queueddittodata=nil;

		cachedentry=nil;
		cacheddata=nil;
		cachedhandle=nil;
	}
	return self;
}

-(void)parse
{
	[self parseWithSeparateMacForks];

	// If we have a queued ditto fork left over, get rid of it as it isn't a directory.
	if(queueddittoentry) [self addQueuedDittoDictionaryAndRetainPosition:NO];
}

-(void)parseWithSeparateMacForks {}

-(void)addEntryWithDictionary:(NSMutableDictionary *)dict retainPosition:(BOOL)retainpos
{
	if(retainpos) [XADException raiseNotSupportedException];

	// Check if expansion of forks is disabled
	NSNumber *disable=properties[XADDisableMacForkExpansionKey];
	if(disable&&disable.boolValue)
	{
		NSNumber *isbin=dict[XADIsMacBinaryKey];
		if(isbin&&isbin.boolValue) dict[XADIsArchiveKey] = @YES;

		[super addEntryWithDictionary:dict retainPosition:retainpos];
		return;
	}

	XADPath *name=dict[XADFileNameKey];

	NSNumber *dirnum=dict[XADIsDirectoryKey];
	BOOL isdir=dirnum && dirnum.boolValue;

	// If we have a queued ditto fork, check if it has the same name as this entry,
	// and get rid of it.
	if(queueddittoentry)
	{
		XADPath *queuedname=queueddittoentry[XADFileNameKey];
		if([queuedname isCanonicallyEqual:name])
		{
			[self addQueuedDittoDictionaryWithName:name isDirectory:isdir retainPosition:retainpos];
		}
		else
		{
			[self addQueuedDittoDictionaryAndRetainPosition:retainpos];
		}
	}

	// Handle directories
	if(isdir)
	{
		// Discard directories used for ditto forks
		NSString *firstcomponent=[name firstPathComponentWithEncodingName:XADUTF8StringEncodingName];
		if(firstcomponent && [firstcomponent isEqual:@"__MACOSX"]) return;

		// Pop deeper directories off the directory stack, and push this directory
		[self popDittoDirectoryStackUntilCanonicalPrefixFor:name];
		[self pushDittoDirectory:name];
	}
	else
	{
		// Check for MacBinary files.
		if([self parseMacBinaryWithDictionary:dict name:name retainPosition:retainpos]) return;

		// Check if the file is a ditto fork.
		if([self parseAppleDoubleWithDictionary:dict name:name retainPosition:retainpos]) return;

	}

	// Nothing else worked, it's a normal file. Remember its filename, and output it.
	self.previousFilename = dict[XADFileNameKey];
	[super addEntryWithDictionary:dict retainPosition:retainpos];
}



-(BOOL)parseAppleDoubleWithDictionary:(NSMutableDictionary *)dict
name:(XADPath *)name retainPosition:(BOOL)retainpos
{
	// Ditto forks are only ever UTF-8.
	if(![name canDecodeWithEncodingName:XADUTF8StringEncodingName]) return NO;

	// Resource forks are at most 16 megabytes. Ignore larger files, as we will
	// be reading the whole file into memory.
	NSNumber *filesizenum=dict[XADFileSizeKey];
	if(filesizenum == nil) return NO;

	off_t filesize=filesizenum.longLongValue;
	if(filesize>16*1024*1024+65536) return NO;

	// Check the file name.
	NSString *first=[name firstPathComponentWithEncodingName:XADUTF8StringEncodingName];
	NSString *last=[name lastPathComponentWithEncodingName:XADUTF8StringEncodingName];
	XADPath *basepath=[name pathByDeletingLastPathComponentWithEncodingName:XADUTF8StringEncodingName];

	// Ditto forks are always prefixed with "._".
	if(![last hasPrefix:@"._"]) return NO;
	NSString *newlast=[last substringFromIndex:2];

	// Sometimes, they are stored in a root directory named "__MACOSX".
	// Get rid of this directory.
	if([first isEqual:@"__MACOSX"]) basepath=[basepath pathByDeletingFirstPathComponentWithEncodingName:XADUTF8StringEncodingName];

	// Recreate the original name and path.
	XADPath *origname=[basepath pathByAppendingXADStringComponent:[self XADStringWithString:newlast]];

	// Try to see if we can match this name against a previously encountered name.
	// If so, set flags to remember we found a name, and replace the name with that
	// of the earlier entry, to make isEqual: work right.
	BOOL matchfound=NO,isdir=NO;

	// Check if the name is canonically the same as the previous file unpacked.
	if(previousname && [origname isCanonicallyEqual:previousname encodingName:XADUTF8StringEncodingName])
	{
		origname=previousname;
		matchfound=YES;
	}

	// Pop deeper directories off the stack of directory names, and check if the
	// name is the same as the top directory on the stack.
	[self popDittoDirectoryStackUntilCanonicalPrefixFor:origname];
	XADPath *stackname=[self topOfDittoDirectoryStack];
	if(stackname && [origname isCanonicallyEqual:stackname encodingName:XADUTF8StringEncodingName])
	{
		origname=stackname;
		isdir=YES;
		matchfound=YES;
	}

	// Parse AppleDouble format.
	off_t rsrcoffs,rsrclen;
	NSDictionary *extattrs=nil;
	NSData *dittodata=nil;

	@try
	{
		CSHandle *fh=[self rawHandleForEntryWithDictionary:dict wantChecksum:YES];
		dittodata=[fh remainingFileContents];

		CSMemoryHandle *memhandle=[CSMemoryHandle memoryHandleForReadingData:dittodata];

		if(![XADAppleDouble parseAppleDoubleWithHandle:memhandle
		resourceForkOffset:&rsrcoffs resourceForkLength:&rsrclen
		extendedAttributes:&extattrs]) @throw @"Failed to read AppleDouble format";
	}
	@catch(id e)
	{
		// Reading or parsing failed, so add this as a regular entry with the
		// cached data, if any.
		[self addEntryWithDictionary:dict retainPosition:retainpos data:dittodata];
		return YES;
	}

	// Build a new entry dictionary for the fork.
	NSMutableDictionary *newdict=[NSMutableDictionary dictionaryWithDictionary:dict];

	newdict[@"MacOriginalDictionary"] = dict;
	newdict[@"MacDataOffset"] = @(rsrcoffs);
	newdict[@"MacDataLength"] = @(rsrclen);
	newdict[XADFileSizeKey] = @(rsrclen);
	newdict[XADIsResourceForkKey] = @YES;

	// Replace name, remove unused entries.
	newdict[XADFileNameKey] = origname;
	[newdict removeObjectsForKeys:@[XADDataLengthKey,XADDataOffsetKey,XADPosixPermissionsKey,
		XADPosixUserKey,XADPosixUserNameKey,XADPosixGroupKey,XADPosixGroupNameKey]];

	// TODO: This replaces any existing attributes. None should
	// exist, but maybe just in case they should be merged if they do.
	if(extattrs) newdict[XADExtendedAttributesKey] = extattrs;

	if(isdir) newdict[XADIsDirectoryKey] = @YES;

	if(matchfound)
	{
		// If we matched this entry with the name of an earlier one, it is done,
		// and we can output it.
		[self inspectEntryDictionary:newdict]; // This is probably not necessary.
		[self addEntryWithDictionary:newdict retainPosition:retainpos data:dittodata];
	}
	else
	{
		// If we didn't find the name for this entry from a previous entry, we will
		// need to keep it around until we can look at the next entry to see its name
		// matches.
		[self queueDittoDictionary:newdict data:dittodata];
	}

	return YES;
}


-(XADPath *)topOfDittoDirectoryStack
{
	if(!dittodirectorystack.count) return nil;
	return dittodirectorystack.lastObject;
}

-(void)pushDittoDirectory:(XADPath *)directory
{
	[dittodirectorystack addObject:directory];
}

-(void)popDittoDirectoryStackUntilCanonicalPrefixFor:(XADPath *)path
{
	while(dittodirectorystack.count)
	{
		XADPath *dir=dittodirectorystack.lastObject;
		if([path hasPrefix:dir]) return;
		[dittodirectorystack removeLastObject];
	}
}




-(void)queueDittoDictionary:(NSMutableDictionary *)dict data:(NSData *)data
{
	queueddittoentry=dict;
	queueddittodata=data;
}

-(void)addQueuedDittoDictionaryAndRetainPosition:(BOOL)retainpos
{
	[self addQueuedDittoDictionaryWithName:nil isDirectory:NO retainPosition:retainpos];
}

-(void)addQueuedDittoDictionaryWithName:(XADPath *)newname
isDirectory:(BOOL)isdir retainPosition:(BOOL)retainpos
{
	if(newname) queueddittoentry[XADFileNameKey] = newname;
	if(isdir) queueddittoentry[XADIsDirectoryKey] = @YES;

	[self inspectEntryDictionary:queueddittoentry];
	[self addEntryWithDictionary:queueddittoentry retainPosition:retainpos data:queueddittodata];

	queueddittoentry=nil;
	queueddittodata=nil;
}




-(BOOL)parseMacBinaryWithDictionary:(NSMutableDictionary *)dict
name:(XADPath *)name retainPosition:(BOOL)retainpos
{
	NSNumber *isbinobj=dict[XADIsMacBinaryKey];
	BOOL isbin = isbinobj != nil ? isbinobj.boolValue : NO;

	NSNumber *checkobj=dict[XADMightBeMacBinaryKey];
	BOOL check = checkobj != nil ? checkobj.boolValue : NO;

	// Return if this file is not known or suspected to be MacBinary.
	if(!isbin&&!check) return NO;

	// Don't bother checking files inside unseekable streams unless known to be MacBinary.
	if(!isbin&&[self.handle isKindOfClass:[CSStreamHandle class]]) return NO;

	CSHandle *fh=[self rawHandleForEntryWithDictionary:dict wantChecksum:YES];

	NSData *header=[fh readDataOfLengthAtMost:128];
	if(header.length!=128) return NO;

	// Check the file if it is not known to be MacBinary.
	if(!isbin&&[XADMacArchiveParser macBinaryVersionForHeader:header]==0) return NO;

	// TODO: should this be turned on or not? probably not.
	//[self setIsMacArchive:YES];

	const uint8_t *bytes=header.bytes;

	uint32_t datasize=CSUInt32BE(bytes+83);
	uint32_t rsrcsize=CSUInt32BE(bytes+87);
	int extsize=CSUInt16BE(bytes+120);

	XADPath *newpath;
	if(name)
	{
		XADPath *parent=name.pathByDeletingLastPathComponent;
		XADString *namepart=[self XADStringWithBytes:bytes+2 length:bytes[1]];
		newpath=[parent pathByAppendingXADStringComponent:namepart];
	}
	else
	{
		newpath=[self XADPathWithBytes:bytes+2 length:bytes[1] separators:XADNoPathSeparator];
	}

	NSMutableDictionary *template=[NSMutableDictionary dictionaryWithDictionary:dict];
	template[@"MacOriginalDictionary"] = dict;
	template[XADFileNameKey] = newpath;
	template[XADFileTypeKey] = @(CSUInt32BE(bytes+65));
	template[XADFileCreatorKey] = @(CSUInt32BE(bytes+69));
	template[XADFinderFlagsKey] = @(bytes[101]+(bytes[73]<<8));
	template[XADCreationDateKey] = [NSDate XADDateWithTimeIntervalSince1904:CSUInt32BE(bytes+91)];
	template[XADLastModificationDateKey] = [NSDate XADDateWithTimeIntervalSince1904:CSUInt32BE(bytes+95)];
	[template removeObjectForKey:XADDataLengthKey];
	[template removeObjectForKey:XADDataOffsetKey];
	[template removeObjectForKey:XADIsMacBinaryKey];
	[template removeObjectForKey:XADMightBeMacBinaryKey];

	#define BlockSize(size) (((size)+127)&~127)
	if(datasize||!rsrcsize)
	{
		NSMutableDictionary *newdict=[NSMutableDictionary dictionaryWithDictionary:template];
		newdict[@"MacDataOffset"] = @(128+BlockSize(extsize));
		newdict[@"MacDataLength"] = @(datasize);
		newdict[XADFileSizeKey] = @(datasize);
		newdict[XADCompressedSizeKey] = @BlockSize(datasize);

		[self inspectEntryDictionary:newdict];
		[self addEntryWithDictionary:newdict retainPosition:retainpos handle:fh];
	}

	if(rsrcsize)
	{
		NSMutableDictionary *newdict=[NSMutableDictionary dictionaryWithDictionary:template];
		newdict[@"MacDataOffset"] = @(128+BlockSize(extsize)+BlockSize(datasize));
		newdict[@"MacDataLength"] = @(rsrcsize);
		newdict[XADFileSizeKey] = @(rsrcsize);
		newdict[XADCompressedSizeKey] = @BlockSize(rsrcsize);
		newdict[XADIsResourceForkKey] = @YES;

		[self inspectEntryDictionary:newdict];
		[self addEntryWithDictionary:newdict retainPosition:retainpos handle:fh];
	}

	return YES;
}




-(void)addEntryWithDictionary:(NSMutableDictionary *)dict
retainPosition:(BOOL)retainpos data:(NSData *)data
{
	cachedentry=dict;
	cacheddata=data;
	cachedhandle=nil;
	[super addEntryWithDictionary:dict retainPosition:retainpos];
	cachedentry=nil;
	cacheddata=nil;
}

-(void)addEntryWithDictionary:(NSMutableDictionary *)dict
retainPosition:(BOOL)retainpos handle:(CSHandle *)handle
{
	cachedentry=dict;
	cacheddata=nil;
	cachedhandle=handle;
	[super addEntryWithDictionary:dict retainPosition:retainpos];
	cachedentry=nil;
	cachedhandle=nil;
}




-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum
{
	NSDictionary *origdict=dict[@"MacOriginalDictionary"];
	if(origdict)
	{
		off_t offset=[dict[@"MacDataOffset"] longLongValue];
		off_t length=[dict[@"MacDataLength"] longLongValue];

		if(!length) return [self zeroLengthHandleWithChecksum:checksum];

		CSHandle *handle=nil;
		if(cachedentry==dict)
		{
			if(cachedhandle) handle=cachedhandle;
			else if(cacheddata) handle=[CSMemoryHandle memoryHandleForReadingData:cacheddata];
		}

		if(!handle) handle=[self rawHandleForEntryWithDictionary:origdict wantChecksum:checksum];

		return [handle nonCopiedSubHandleFrom:offset length:length];
	}
	else
	{
		return [self rawHandleForEntryWithDictionary:dict wantChecksum:checksum];
	}
}




-(NSString *)descriptionOfValueInDictionary:(NSDictionary *)dict key:(NSString *)key
{
	id object=dict[key];
	if(!object) return nil;

	if([key isEqual:@"MacOriginalDictionary"])
	{
		if(![object isKindOfClass:[NSDictionary class]]) return [object description];
		return XADHumanReadableEntryWithDictionary(object,self);
	}
	else if([key isEqual:XADMightBeMacBinaryKey])
	{
		if(![object isKindOfClass:[NSNumber class]]) return [object description];
		return XADHumanReadableBoolean([object longLongValue]);
	}
	else
	{
		return [super descriptionOfValueInDictionary:dict key:key];
	}
}

-(NSString *)descriptionOfKey:(NSString *)key
{
	static NSDictionary *descriptions=nil;
	if(!descriptions) descriptions=@{XADIsMacBinaryKey: NSLocalizedString(@"Is an embedded MacBinary file",@""),
		 XADMightBeMacBinaryKey: NSLocalizedString(@"Check for MacBinary",@""),
		 XADDisableMacForkExpansionKey: NSLocalizedString(@"Mac OS fork handling is disabled",@""),
		 @"MacOriginalDictionary": NSLocalizedString(@"Original archive entry",@""),
		 @"MacDataOffset": NSLocalizedString(@"Start of embedded data",@""),
		 @"MacDataLength": NSLocalizedString(@"Length of embedded data",@"")};

	NSString *description=descriptions[key];
	if(description) return description;

	return [super descriptionOfKey:key];
}




-(CSHandle *)rawHandleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum
{
	return nil;
}

-(void)inspectEntryDictionary:(NSMutableDictionary *)dict
{
}

@end

