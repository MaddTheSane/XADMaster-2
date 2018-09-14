#import "XADResourceFork.h"
#import "CSMemoryHandle.h"

#define ResourceMapHeader 22 // 16+4+2 bytes reserved for in-memory structures.
#define ResourceMapEntryHeader 2 // 2-byte type count actually part of type list.
#define ResourceMapEntrySize 8 // 4+2+2 bytes per type list entry.

@implementation XADResourceFork

+(XADResourceFork *)resourceForkWithHandle:(CSHandle *)handle
{
	if(!handle) return nil;
	XADResourceFork *fork=[[self new] autorelease];
	[fork parseFromHandle:handle];
	return fork;
}

+(XADResourceFork *)resourceForkWithHandle:(CSHandle *)handle error:(XADError *)errorptr
{
	@try { return [self resourceForkWithHandle:handle]; }
	@catch(id exception) { if(errorptr) *errorptr=[XADException parseException:exception]; }
	return nil;
}

+(instancetype)resourceForkWithHandle:(XADHandle *)handle nserror:(NSError * _Nullable *)errorptr
{
	@try { return [self resourceForkWithHandle:handle]; }
	@catch(id exception) {
		if(errorptr)
			*errorptr=[XADException parseExceptionReturningNSError:exception];
		return nil;
	}
	if(errorptr)
		*errorptr=[NSError errorWithDomain:XADErrorDomain code:XADErrorUnknown userInfo:nil];

	return nil;
}

-(instancetype)init
{
	if((self=[super init]))
	{
		resources=nil;
	}
	return self;
}

-(void)dealloc
{
	[resources release];
	[super dealloc];
}

-(void)parseFromHandle:(CSHandle *)handle
{
	off_t pos=handle.offsetInFile;

	off_t dataoffset=[handle readUInt32BE];
	off_t mapoffset=[handle readUInt32BE];
	off_t datalength=[handle readUInt32BE];
	off_t maplength=[handle readUInt32BE];

	CSHandle *datahandle=[handle nonCopiedSubHandleFrom:pos+dataoffset length:datalength];
	NSMutableDictionary *dataobjects=[self _parseResourceDataFromHandle:datahandle];

	// Load the map into memory so that traversing its data structures
	// doesn't cause countless seeks in compressed or encrypted input streams
	[handle seekToFileOffset:pos+mapoffset];
	NSData *mapdata=[handle readDataOfLength:(int)maplength];
	CSHandle *maphandle=[CSMemoryHandle memoryHandleForReadingData:mapdata];

	[resources release];
	resources=[[self _parseMapFromHandle:maphandle withDataObjects:dataobjects] retain];
}

-(NSData *)resourceDataForType:(uint32_t)type identifier:(int)identifier
{
	NSNumber *typekey=@(type);
	NSNumber *identifierkey=@(identifier);
	NSDictionary *resourcesoftype=resources[typekey];
	NSDictionary *resource=resourcesoftype[identifierkey];
	return resource[@"Data"];
}

-(NSMutableDictionary *)_parseResourceDataFromHandle:(CSHandle *)handle
{
	NSMutableDictionary *dict=[NSMutableDictionary dictionary];
	while(!handle.atEndOfFile)
	{
		NSNumber *key=@(handle.offsetInFile);
		uint32_t length=[handle readUInt32BE];
		NSData *data=[handle readDataOfLength:length];
		dict[key] = data;
	}
	return dict;
}

-(NSDictionary *)_parseMapFromHandle:(CSHandle *)handle withDataObjects:(NSMutableDictionary *)dataobjects
{
	[handle skipBytes:ResourceMapHeader];
	/*int forkattributes=*/[handle readUInt16BE];
	int typelistoffset=[handle readInt16BE];
	int namelistoffset=[handle readInt16BE];
	
	int typecount=[handle readInt16BE]+1;
	NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithCapacity:typecount];
	for(int i=0;i<typecount;i++)
	{
		[handle seekToFileOffset:typelistoffset+i*ResourceMapEntrySize+ResourceMapEntryHeader];
		uint32_t type=[handle readID];
		int count=[handle readInt16BE]+1;
		int offset=[handle readInt16BE];

		[handle seekToFileOffset:typelistoffset+offset];
		NSDictionary *references=[self _parseReferencesFromHandle:handle count:count];

		dict[@(type)] = references;
	}

	NSEnumerator *typeenumerator=[dict keyEnumerator];
	NSNumber *type;
	while(type=[typeenumerator nextObject])
	{
		NSDictionary *resourcesoftype=dict[type];
		NSEnumerator *identifierenumerator=[resourcesoftype keyEnumerator];
		NSNumber *identifier;
		while(identifier=[identifierenumerator nextObject])
		{
			NSMutableDictionary *resource=resourcesoftype[identifier];
			resource[@"Type"] = type;

			// Resolve the name (if any).
			NSNumber *nameoffset=resource[@"NameOffset"];
			if(nameoffset != nil)
			{
				// untested
				[handle seekToFileOffset:namelistoffset+nameoffset.intValue];
				int length=[handle readUInt8];
				NSData *namedata=[handle readDataOfLength:length];
				resource[@"NameData"] = namedata;
			}

			// Resolve the data.
			NSNumber *dataoffset=resource[@"DataOffset"];
			NSData *data=dataobjects[dataoffset];
			resource[@"Data"] = data;
		}
	}
	
	return dict;
}

-(NSDictionary *)_parseReferencesFromHandle:(CSHandle *)handle count:(int)count
{
	NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithCapacity:count];
	for(int i=0;i<count;i++)
	{
		int identifier=[handle readInt16BE];
		int nameoffset=[handle readInt16BE];
		uint32_t attrsandoffset=[handle readUInt32BE];
		int attrs=(attrsandoffset>>24)&0xff;
		off_t offset=attrsandoffset&0xffffff;
		/*reserved=*/[handle readUInt32BE];

		NSNumber *key=@(identifier);
		NSMutableDictionary *resource=[NSMutableDictionary dictionaryWithObjectsAndKeys:
			key,@"ID",
			@(attrs),@"Attributes",
			@(offset),@"DataOffset",
		nil];

		if(nameoffset!=-1) resource[@"NameOffset"] = @(nameoffset);

		dict[key] = resource;
	}
	return dict;
}

@end
