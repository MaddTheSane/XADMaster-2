#import "XADXARParser.h"
#import "XADGzipParser.h"
#import "CSZlibHandle.h"
#import "CSBzip2Handle.h"
#import "XADLZMAHandle.h"
#import "XADXZHandle.h"
#import "XADMD5Handle.h"
#import "XADSHA1Handle.h"
#import "XADRegex.h"
#import "NSDateXAD.h"

#define GroundState 0
#define XarState 1
#define TocState 2
#define FileState 3
#define DataState 4
#define ExtendedAttributeState 5
#define OldExtendedAttributeState 6

static const NSString *StringFormat=@"String";
static const NSString *XADStringFormat=@"XADString";
static const NSString *DecimalFormat=@"Decimal";
static const NSString *OctalFormat=@"Octal";
static const NSString *HexFormat=@"Hex";
static const NSString *DateFormat=@"Date";

@implementation XADXARParser

+(int)requiredHeaderSize { return 4; }

+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name
{
	const uint8_t *bytes=data.bytes;
	NSInteger length=data.length;

	return length>=4&&bytes[0]=='x'&&bytes[1]=='a'&&bytes[2]=='r'&&bytes[3]=='!';
}

-(void)parse
{
	CSHandle *fh=self.handle;

	[fh skipBytes:4];
	int headsize=[fh readUInt16BE];
	[fh skipBytes:2];
	uint64_t tablecompsize=[fh readUInt64BE];
	uint64_t tableuncompsize=[fh readUInt64BE];

	heapoffset=headsize+tablecompsize;

	filedefinitions=@{@"name": @[@"Name",StringFormat],
		@"type": @[@"Type",StringFormat],
		@"link": @[@"Link",StringFormat],
		@"mtime": @[XADLastModificationDateKey,DateFormat],
		@"atime": @[XADLastAccessDateKey,DateFormat],
		@"ctime": @[XADCreationDateKey,DateFormat],
		@"mode": @[XADPosixPermissionsKey,OctalFormat],
		@"uid": @[XADPosixUserKey,DecimalFormat],
		@"gid": @[XADPosixGroupKey,DecimalFormat],
		@"user": @[XADPosixUserNameKey,XADStringFormat],
		@"group": @[XADPosixGroupNameKey,XADStringFormat]};

	datadefinitions=@{@"size": @[XADFileSizeKey,DecimalFormat],
		@"offset": @[XADDataOffsetKey,DecimalFormat],
		@"length": @[XADDataLengthKey,DecimalFormat],
		@"extracted-checksum": @[@"XARChecksum",HexFormat],
		@"extracted-checksum style": @[@"XARChecksumStyle",StringFormat],
		@"encoding style": @[@"XAREncodingStyle",StringFormat]};

	eadefinitions=@{@"name": @[@"Name",StringFormat],
		@"size": @[@"Size",DecimalFormat],
		@"offset": @[@"Offset",DecimalFormat],
		@"length": @[@"Length",DecimalFormat],
		@"extracted-checksum": @[@"Checksum",HexFormat],
		@"extracted-checksum style": @[@"ChecksumStyle",StringFormat],
		@"encoding style": @[@"EncodingStyle",StringFormat]};

	files=[NSMutableArray array];
	filestack=[NSMutableArray array];

	state=GroundState;

	CSZlibHandle *zh=[CSZlibHandle zlibHandleWithHandle:[fh nonCopiedSubHandleFrom:headsize length:tablecompsize]];
	NSData *data=[zh readDataOfLength:(int)tableuncompsize];

	//NSLog(@"%@",[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);

	NSXMLParser *xml=[[[NSXMLParser alloc] initWithData:data] autorelease];
	xml.delegate = self;
	[xml parse];

	// Check for XIP files, the worst file format ever. This is a cpio file
	// inside a gz file inside a xar, plus a metadata file. The metadata file
	// is currently ignored.
	// The XARDisableXIP boolean property can be used to disable this check.
	NSNumber *disablexip=self.properties[@"XARDisableXIP"];
	if(disablexip == nil || !disablexip.boolValue)
	if(files.count==2)
	{
		NSMutableDictionary *first=files[0];
		NSMutableDictionary *second=files[1];
		NSString *firstname=first[@"Name"];
		NSString *secondname=second[@"Name"];
		NSString *secondstyle=second[@"XAREncodingStyle"];

		if([firstname isEqual:@"Metadata"] &&
		[secondname isEqual:@"Content"] &&
		[secondstyle isEqual:@"application/octet-stream"])
		{
			second[XADIsArchiveKey] = @YES;
			second[@"XARIsXIP"] = @YES;
			[self finishFile:second parentPath:self.XADPath];
			return;
		}
	}

	NSEnumerator *enumerator=[files objectEnumerator];
	NSMutableDictionary *file;
	while((file=[enumerator nextObject]))
	{
		if(!self.shouldKeepParsing) break;
		[self finishFile:file parentPath:self.XADPath];
	}
}

-(void)finishFile:(NSMutableDictionary *)file parentPath:(XADPath *)parentpath
{
	NSString *name=file[@"Name"];
	NSString *type=file[@"Type"];
	NSString *link=file[@"Link"];
	NSArray *filearray=file[@"Files"];
	NSDictionary *eas=file[@"ExtendedAttributes"];

	[file removeObjectForKey:@"Name"];
	[file removeObjectForKey:@"Type"];
	[file removeObjectForKey:@"Link"];
	[file removeObjectForKey:@"Files"];
	[file removeObjectForKey:@"ExtendedAttributes"];

	XADPath *path=[parentpath pathByAppendingXADStringComponent:[self XADStringWithString:name]];
	file[XADFileNameKey] = path;

	if([type isEqual:@"directory"]||filearray)
	{
		file[XADIsDirectoryKey] = @YES;
	}
	else if([type isEqual:@"symlink"])
	{
		if(!link) return;
		file[XADLinkDestinationKey] = [self XADStringWithString:link];
	}

	NSMutableDictionary *eadict=[NSMutableDictionary dictionary];
	NSMutableDictionary *resfork=nil;
	int numeas=0;
	if(eas)
	{
		NSEnumerator *enumerator=[eas objectEnumerator];
		NSMutableDictionary *ea;
		while((ea=[enumerator nextObject]))
		{
			NSString *name=ea[@"Name"];
			if(!name) continue;

			if([name isEqual:@"com.apple.ResourceFork"])
			{
				resfork=ea;
			}
			else
			{
				NSString *encodingstyle=ea[@"EncodingStyle"];
				NSNumber *offset=ea[@"Offset"];
				NSNumber *length=ea[@"Length"];
				NSNumber *size=ea[@"Size"];
				NSData *checksum=ea[@"Checksum"];
				NSString *checksumstyle=ea[@"ChecksumStyle"];

				CSHandle *handle=[self handleForEncodingStyle:encodingstyle
				offset:offset length:length size:size checksum:checksum
				checksumStyle:checksumstyle];

				NSData *data=nil;
				@try { [handle remainingFileContents]; }
				@catch(id e) { NSLog(@"Exception while extracting XAR extended attribute for file %@: %@",path,e); }

				if(data)
				{
					if(!handle.hasChecksum || handle.checksumCorrect)
					{
						eadict[name] = data;
						numeas++;
					}
				}
				else
				{
					NSLog(@"Checksum mismatch while extracting extended attribute from XAR file %@",path);
				}
			}
		}

		if(numeas)
		{
			file[XADExtendedAttributesKey] = eadict;
		}
	}

	NSNumber *datalen=file[XADDataLengthKey];
	if(datalen != nil) file[XADCompressedSizeKey] = datalen;
	else file[XADCompressedSizeKey] = @0;

	if(!file[XADFileSizeKey]) file[XADFileSizeKey] = @0;

	NSString *encodingstyle=file[@"XAREncodingStyle"];
	NSNumber *isxip=file[@"XARIsXIP"];
	XADString *compressionname=[self compressionNameForEncodingStyle:encodingstyle isXIP:isxip && isxip.boolValue];
	if(compressionname) file[XADCompressionNameKey] = compressionname;

	[self addEntryWithDictionary:file];

	if(resfork)
	{
		NSMutableDictionary *resfile=[NSMutableDictionary dictionaryWithDictionary:file];

		NSNumber *size=resfork[@"Size"];
		NSNumber *offset=resfork[@"Offset"];
		NSNumber *length=resfork[@"Length"];
		NSData *checksum=resfork[@"Checksum"];
		NSString *checksumstyle=resfork[@"ChecksumStyle"];
		NSString *encodingstyle=resfork[@"EncodingStyle"];

		if(size != nil) resfile[XADFileSizeKey] = size;
		if(offset != nil) resfile[XADDataOffsetKey] = offset;
		if(length != nil) resfile[XADDataLengthKey] = length;
		if(length != nil) resfile[XADCompressedSizeKey] = length;
		if(checksum) resfile[@"XARChecksum"] = checksum;
		if(checksumstyle) resfile[@"XARChecksumStyle"] = checksumstyle;
		if(encodingstyle) resfile[@"XAREncodingStyle"] = encodingstyle;

		XADString *compressionname=[self compressionNameForEncodingStyle:encodingstyle isXIP:NO];
		if(compressionname) resfile[XADCompressionNameKey] = compressionname;

		resfile[XADIsResourceForkKey] = @YES;

		[self addEntryWithDictionary:resfile];
	}

	if(filearray)
	{
		NSEnumerator *enumerator=[filearray objectEnumerator];
		NSMutableDictionary *file;
		while((file=[enumerator nextObject])) [self finishFile:file parentPath:path];
	}
}

-(XADString *)compressionNameForEncodingStyle:(NSString *)encodingstyle isXIP:(BOOL)isxip
{
	NSString *compressionname=nil;

	if(isxip) compressionname=@"Deflate";
	else if(!encodingstyle || encodingstyle.length==0) compressionname=@"None";
	else if([encodingstyle isEqual:@"application/octet-stream"]) compressionname=@"None";
	else if([encodingstyle isEqual:@"application/x-gzip"]) compressionname=@"Deflate";
	else if([encodingstyle isEqual:@"application/x-bzip2"]) compressionname=@"Bzip2";
	else if([encodingstyle isEqual:@"application/x-xz"]) compressionname=@"LZMA (XZ)";
	else if([encodingstyle isEqual:@"application/x-lzma"]) compressionname=@"LZMA";

	if(compressionname) return [self XADStringWithString:compressionname];
	else return nil;
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)name
namespaceURI:(NSString *)namespace qualifiedName:(NSString *)qname
attributes:(NSDictionary *)attributes
{
	switch(state)
	{
		case GroundState:
			if([name isEqual:@"xar"]) state=XarState;
		break;

		case XarState:
			if([name isEqual:@"toc"]) state=TocState;
		break;

		case TocState:
			if([name isEqual:@"file"])
			{
				currfile=[NSMutableDictionary dictionary];
				state=FileState;
			}
		break;

		case FileState:
			if([name isEqual:@"file"])
			{
				[filestack addObject:currfile];
				currfile=[NSMutableDictionary dictionary];
				curreas=nil;
				state=FileState;
			}
			else if([name isEqual:@"data"]) state=DataState;
			else if([name isEqual:@"ea"])
			{
				currea=[NSMutableDictionary dictionary];
				state=ExtendedAttributeState;
			}
			else [self startSimpleElement:name attributes:attributes
			definitions:filedefinitions destinationDictionary:currfile];
		break;

		case DataState:
			[self startSimpleElement:name attributes:attributes
			definitions:datadefinitions destinationDictionary:currfile];
		break;

		case ExtendedAttributeState:
			if([name isEqual:@"com.apple.ResourceFork"]||
			[name isEqual:@"com.apple.FinderInfo"])
			{
				currea=[NSMutableDictionary dictionaryWithObject:name forKey:@"Name"];
				state=OldExtendedAttributeState;
			}
			else [self startSimpleElement:name attributes:attributes
			definitions:eadefinitions destinationDictionary:currea];
		break;

		case OldExtendedAttributeState:
			[self startSimpleElement:name attributes:attributes
			definitions:eadefinitions destinationDictionary:currea];
		break;
	}
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)name
namespaceURI:(NSString *)namespace qualifiedName:(NSString *)qname
{
	switch(state)
	{
		case TocState:
			if([name isEqual:@"toc"]) [parser abortParsing];
		break;

		case FileState:
			if([name isEqual:@"file"])
			{
				if(curreas)
				{
					currfile[@"ExtendedAttributes"] = curreas;
					curreas=nil;
				}

				if(filestack.count)
				{
					NSMutableDictionary *parent=filestack.lastObject;
					[filestack removeLastObject];

					NSMutableArray *filearray=parent[@"Files"];
					if(filearray) [filearray addObject:currfile];
					else parent[@"Files"] = [NSMutableArray arrayWithObject:currfile];

					currfile=parent;
				}
				else
				{
					[files addObject:currfile];
					currfile=nil;
					state=TocState;
				}
			}
			else [self endSimpleElement:name definitions:filedefinitions
			destinationDictionary:currfile];
		break;

		case DataState:
			if([name isEqual:@"data"]) state=FileState;
			else [self endSimpleElement:name definitions:datadefinitions
			destinationDictionary:currfile];
		break;

		case ExtendedAttributeState:
			if([name isEqual:@"ea"])
			{
				if(currea) // Might have been nil'd by OldExtendedAttributeState.
				{
					if(!curreas) curreas=[NSMutableArray array];
					[curreas addObject:currea];
					currea=nil;
				}
				state=FileState;
			}
			else [self endSimpleElement:name definitions:eadefinitions
			destinationDictionary:currea];
		break;

		case OldExtendedAttributeState:
			if([name isEqual:currea[@"Name"]])
			{
				if(!curreas) curreas=[NSMutableArray array];
				[curreas addObject:currea];
				currea=nil;
				state=ExtendedAttributeState;
			}
			else [self endSimpleElement:name definitions:eadefinitions
			destinationDictionary:currea];
		break;
	}
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	[currstring appendString:string];
}

-(void)startSimpleElement:(NSString *)name attributes:(NSDictionary *)attributes
definitions:(NSDictionary *)definitions destinationDictionary:(NSMutableDictionary *)dest
{
	NSEnumerator *enumerator=[attributes keyEnumerator];
	NSString *key;
	while((key=[enumerator nextObject]))
	{
		NSArray *definition=definitions[[NSString stringWithFormat:@"%@ %@",name,key]];
		if(definition) [self parseDefinition:definition string:attributes[key] destinationDictionary:dest];
	}

	NSArray *definition=definitions[name];
	if(definition) currstring=[NSMutableString string];
}

-(void)endSimpleElement:(NSString *)name definitions:(NSDictionary *)definitions
destinationDictionary:(NSMutableDictionary *)dest
{
	if(!currstring) return;

	NSArray *definition=definitions[name];
	[self parseDefinition:definition string:currstring destinationDictionary:dest];

	currstring=nil;
}

-(void)parseDefinition:(NSArray *)definition string:(NSString *)string
destinationDictionary:(NSMutableDictionary *)dest
{
	NSString *key=definition[0];
	NSString *format=definition[1];

	id obj=nil;
	if(format==StringFormat) obj=string;
	else if(format==XADStringFormat) obj=[self XADStringWithString:string];
	else if(format==DecimalFormat) obj=@(strtoll(string.UTF8String,NULL,10));
	else if(format==OctalFormat) obj=@(strtoll(string.UTF8String,NULL,8));
	else if(format==HexFormat)
	{
		NSMutableData *data=[NSMutableData data];
		uint8_t byte = '\0';
		NSInteger n=0,length=string.length;
		for(int i=0;i<length;i++)
		{
			unichar c=[string characterAtIndex:i];
			if(isxdigit(c))
			{
				int val=0;
				if(c>='0'&&c<='9') val=c-'0';
				else if(c>='A'&&c<='F') val=c-'A'+10;
				else if(c>='a'&&c<='f') val=c-'a'+10;

				if(n&1) { byte|=val; [data appendBytes:&byte length:1]; }
				else byte=val<<4;

				n++;
			}
		}
		obj=data;
	}
	else if(format==DateFormat)
	{
		NSArray *matches=[string substringsCapturedByPattern:@"^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2})(:([0-9]{2})(.([0-9]+))?)?(([+-])([0-9]{2}):([0-9]{2})|Z)$"];
		if(matches)
		{
			int year=[matches[1] intValue];
			int month=[matches[2] length]?[matches[2] intValue]:1;
			int day=[matches[3] length]?[matches[3] intValue]:1;
			int hour=[matches[4] length]?[matches[4] intValue]:0;
			int minute=[matches[5] length]?[matches[5] intValue]:0;
			int second=[matches[7] length]?[matches[7] intValue]:0;

			int timeoffs=0;
			if([matches[11] length])
			{
				timeoffs=[matches[12] intValue]*60+[matches[13] intValue];
				if([matches[11] isEqual:@"-"]) timeoffs=-timeoffs;
			}
			NSTimeZone *tz=[NSTimeZone timeZoneForSecondsFromGMT:timeoffs*60];

			obj=[NSDate XADDateWithYear:year month:month day:day hour:hour minute:minute second:second timeZone:tz];
		}
	}

	if(obj) dest[key] = obj;
}

-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum
{
	NSData *checksumdata=nil;
	NSString *checksumstyle=nil;
	if(checksum)
	{
		checksumdata=dict[@"XARChecksum"];
		checksumstyle=dict[@"XARChecksumStyle"];
	}

	NSNumber *offset=dict[XADDataOffsetKey];
	NSNumber *length=dict[XADDataLengthKey];
	NSNumber *size=dict[XADFileSizeKey];

	NSNumber *isxip=dict[@"XARIsXIP"];
	if(isxip && isxip.boolValue)
	{
		CSHandle *handle=[self.handle nonCopiedSubHandleFrom:offset.longLongValue+heapoffset
		length:length.longLongValue];

		return [[[XADGzipHandle alloc] initWithHandle:handle] autorelease];
	}
	else
	{
		return [self handleForEncodingStyle:dict[@"XAREncodingStyle"]
		offset:offset length:length size:size checksum:checksumdata checksumStyle:checksumstyle];
	}
}

-(CSHandle *)handleForEncodingStyle:(NSString *)encodingstyle offset:(NSNumber *)offset
length:(NSNumber *)length size:(NSNumber *)size checksum:(NSData *)checksum checksumStyle:(NSString *)checksumstyle
{
	off_t sizeval=size.longLongValue;

	CSHandle *handle;
	if(offset != nil)
	{
		handle=[self.handle nonCopiedSubHandleFrom:offset.longLongValue+heapoffset
		length:length.longLongValue];

		if(!encodingstyle||encodingstyle.length==0); // no encoding style, copy
		else if([encodingstyle isEqual:@"application/octet-stream"]);  // octe-stream, also copy
		else if([encodingstyle isEqual:@"application/x-gzip"]) handle=[CSZlibHandle zlibHandleWithHandle:handle length:sizeval];
		else if([encodingstyle isEqual:@"application/x-bzip2"]) handle=[CSBzip2Handle bzip2HandleWithHandle:handle length:sizeval];
		else if([encodingstyle isEqual:@"application/x-xz"]) handle=[[[XADXZHandle alloc] initWithHandle:handle length:sizeval] autorelease];
		else if([encodingstyle isEqual:@"application/x-lzma"])
		{
			int first=[handle readUInt8];
			if(first==0xff)
			{
				/*[handle seekToFileOffset:0];
				return [[[XADXZHandle alloc] initWithHandle:handle length:sizeval ...] autorelease];
				*/
				return nil;
			}
			else
			{
				[handle seekToFileOffset:0];
				NSData *props=[handle readDataOfLength:5];
				uint64_t streamsize=[handle readUInt64LE];
				handle=[[[XADLZMAHandle alloc] initWithHandle:handle length:streamsize propertyData:props] autorelease];
			}
		}
		else return nil;
	}
	else
	{
		handle=[self zeroLengthHandleWithChecksum:YES];
	}

	if(checksum&&checksumstyle)
	{
		if([checksumstyle isEqual:@"MD5"])
		{
			return [[[XADMD5Handle alloc] initWithHandle:handle length:sizeval correctDigest:checksum] autorelease];
		}
		else if([checksumstyle isEqual:@"SHA1"])
		{
			return [[[XADSHA1Handle alloc] initWithHandle:handle length:sizeval correctDigest:checksum] autorelease];
		}
	}

	return handle;
}



-(NSString *)formatName { return @"XAR"; }

@end

