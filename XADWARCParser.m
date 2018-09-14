#import "XADWARCParser.h"
#import "Scanning.h"

@implementation XADWARCParser

+(int)requiredHeaderSize { return 10; }

+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name
{
	const uint8_t *bytes=data.bytes;
	NSInteger length=data.length;

	if(length<10) return NO;
	return memcmp(bytes,"WARC/1.0\r\n",10)==0;
}

-(void)parse
{
	CSHandle *fh=self.handle;

	NSMutableArray *recordarray=[NSMutableArray array];
	NSMutableDictionary *records=[NSMutableDictionary dictionary];

	// Read all WARC records into memory, along with the HTTP headers
	// for application/http records.

	NSMutableDictionary *lastrecord=nil;
	while(!fh.atEndOfFile)
	{
		NSAutoreleasePool *pool=[NSAutoreleasePool new];

		NSString *marker=[fh readLineWithEncoding:NSUTF8StringEncoding];
		if(![marker isEqual:@"WARC/1.0"])
		{
			// The Content-Length record was wrong, so attempt to find the next
			// record and correct the previously recorded record.
			BOOL found=[fh scanForByteString:(const uint8_t *)"\r\n\r\nWARC/1.0\r\n" length:14];

			off_t realendofrecord=fh.offsetInFile;
			lastrecord[@"EndOfRecord"] = @(realendofrecord);

			if(!found) break;

			[fh skipBytes:14];
		}

		NSMutableDictionary *record=[self parseHTTPHeadersWithHandle:fh];
		lastrecord=record;

		off_t contentstart=fh.offsetInFile;

		NSString *recordid=record[@"WARC-Record-ID"];
		NSString *contentlength=record[@"Content-Length"];
		NSString *contenttype=record[@"Content-Type"];

		if(!contentlength) [XADException raiseIllegalDataException];
		NSScanner *scanner=[NSScanner scannerWithString:contentlength];
		long long length=0;
		[scanner scanLongLong:&length];

		off_t endofrecord=contentstart+length;

		record[@"ContentStart"] = @(contentstart);
		record[@"EndOfRecord"] = @(endofrecord);

		if([contenttype hasPrefix:@"application/http"])
		{
			NSArray *headers=[self readHTTPHeadersWithHandle:fh];
			off_t bodystart=fh.offsetInFile;

			record[@"HTTPHeaders"] = headers;
			record[@"HTTPBodyStart"] = @(bodystart);
		}

		[recordarray addObject:record];
		records[recordid] = record;

		[fh seekToFileOffset:endofrecord+4];

		[pool release];
	}

	// Find all response records with 200 status, and build a
	// directory tree of the file names.

	NSMutableArray *filerecords=[NSMutableArray array];
	NSMutableDictionary *root=[NSMutableDictionary dictionary];

	NSEnumerator *enumerator=[recordarray objectEnumerator];
	NSMutableDictionary *record;
	while((record=[enumerator nextObject]))
	{
		NSString *type=record[@"WARC-Type"];
		NSArray *headers=record[@"HTTPHeaders"];
		NSString *status=headers[0];

		if([type isEqual:@"response"])
		if([status matchedByPattern:@"^HTTP/[0-9]+\\.[0-9]+ 200"])
		{
			NSString *target=record[@"WARC-Target-URI"];

			NSArray *components=[self pathComponentsForURLString:target];
			if(components)
			{
				NSMutableDictionary *dir=root;

				NSUInteger count=components.count;
				for(NSUInteger i=0;i<count-1;i++)
				{
					NSString *component=components[i];
					dir=[self insertDirectory:component inDirectory:dir];
				}

				[self insertFile:components.lastObject record:record inDirectory:dir];

				[filerecords addObject:record];
			}
			else NSLog(@"Failed to parse URL \"%@\"",target);
		}
	}

	// Walk the finished directory tree to generate XADPaths for all files.
	[self buildXADPathsForFilesInDirectory:root parentPath:self.XADPath];

	// Iterate over the files, finding and loading the request
	// records and emit archive entries.

	enumerator=[filerecords objectEnumerator];
	while((record=[enumerator nextObject]))
	{
		NSString *target=record[@"WARC-Target-URI"];
		NSNumber *startnum=record[@"HTTPBodyStart"];
		NSNumber *endnum=record[@"EndOfRecord"];
		NSArray *responseheaders=record[@"HTTPHeaders"];
		XADPath *path=record[@"XADPath"];

		NSNumber *lengthnum=@(endnum.longLongValue-startnum.longLongValue);

		NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithObjectsAndKeys:
			path,XADFileNameKey,
			lengthnum,XADFileSizeKey,
			lengthnum,XADCompressedSizeKey,
			startnum,XADDataOffsetKey,
			lengthnum,XADDataLengthKey,
			target,@"WARCTargetURI",
			responseheaders,@"WARCResponseHeaders",
		nil];

		NSString *requestid=record[@"WARC-Concurrent-To"];
		NSDictionary *request=records[requestid];
		if(request)
		{
			NSArray *requestheaders=request[@"HTTPHeaders"];
			dict[@"WARCRequestHeaders"] = requestheaders;

			NSNumber *requeststartnum=request[@"HTTPBodyStart"];
			NSNumber *requestlengthnum=request[@"HTTPBodyLength"];
			off_t start=requeststartnum.longLongValue;
			off_t length=requestlengthnum.longLongValue;

			if(length)
			{
				[fh seekToFileOffset:start];
				NSData *requestbody=[fh readDataOfLength:(int)length];

				dict[@"WARCRequestBody"] = requestbody;
			}
		}

		[self addEntryWithDictionary:dict];
	}

	// TODO: Handle more record types, and store their contents as file and archive
	// metadata. Patches welcome!

}




-(NSMutableDictionary *)parseHTTPHeadersWithHandle:(CSHandle *)handle
{
	NSMutableDictionary *headers=[NSMutableDictionary dictionary];
	for(;;)
	{
		NSString *line=[handle readLineWithEncoding:NSUTF8StringEncoding];
		if(line.length==0) return headers;

		NSArray *matches=[line substringsCapturedByPattern:@"^([^:]+):[ \t]+(.*)$"];
		if(matches)
		{
			NSString *key=matches[1];
			NSString *value=matches[2];

			headers[key] = value;
		}
	}
}

-(NSArray *)readHTTPHeadersWithHandle:(CSHandle *)handle
{
	NSMutableArray *headers=[NSMutableArray array];
	for(;;)
	{
		NSString *line=[handle readLineWithEncoding:NSUTF8StringEncoding];
		if(line.length==0) return headers;
		[headers addObject:line];
	}
}




-(NSArray *)pathComponentsForURLString:(NSString *)urlstring
{
	NSArray *matches=[urlstring substringsCapturedByPattern:@"^https?://([^/]+)(/.*|())$"];
	if(!matches) return nil;
	NSString *host=matches[1];
	NSString *path=matches[2];

	if(path.length==0) return @[host];

	NSMutableArray *components=[[path.pathComponents mutableCopy] autorelease];
	components[0] = host;

	if([components.lastObject isEqual:@"/"]) [components removeLastObject];

	// TODO: Better processing of the path, handling escapes and such.

	return components;
}

-(NSMutableDictionary *)insertDirectory:(NSString *)name inDirectory:(NSMutableDictionary *)dir
{
	NSMutableDictionary *entry=dir[name];

	if(!entry)
	{
		// No such entry exists, so insert a new directory.
		NSMutableDictionary *newdir=[NSMutableDictionary dictionary];
		dir[name] = newdir;
		return newdir;
	}
	else if(entry[@"/"])
	{
		// A file with the same name exists. Remove the file, insert a new directory,
		// then insert the file in the new directory as "index.html".
		[[entry retain] autorelease];
		[dir removeObjectForKey:name];

		NSMutableDictionary *newdir=[NSMutableDictionary dictionary];
		dir[name] = newdir;

		[self insertFile:@"index.html" record:entry inDirectory:newdir];

		return newdir;
	}
	else
	{
		// This directory already exists. No need to do anything, just return it.
		return entry;
	}
}

-(void)insertFile:(NSString *)name record:(NSMutableDictionary *)record inDirectory:(NSMutableDictionary *)dir
{
	record[@"/"] = [NSNull null]; // Mark the record as a file.

	NSMutableDictionary *entry=dir[name];

	if(!entry)
	{
		// No such entry exists, so insert the file.
		dir[name] = record;
	}
	else if(entry[@"/"])
	{
		// A file with the same name already exists. Find an unused name to use instead.
		NSString *newname;
		int counter=1;
		do { newname=[NSString stringWithFormat:@"%@.%d",name,counter++]; }
		while(dir[newname]);

		dir[newname] = record;
	}
	else
	{
		// A directory with the same name exists. Attempt to insert the file
		// as "index.html" in that directory instead.
		[self insertFile:@"index.html" record:record inDirectory:entry];
	}
}

-(void)buildXADPathsForFilesInDirectory:(NSMutableDictionary *)dir parentPath:(XADPath *)parent
{
	NSEnumerator *enumerator=[dir keyEnumerator];
	NSString *name;
	while((name=[enumerator nextObject]))
	{
		NSMutableDictionary *entry=dir[name];
		XADString *xadname=[self XADStringWithString:name];
		XADPath *path=[parent pathByAppendingXADStringComponent:xadname];

		if(entry[@"/"])
		{
			entry[@"XADPath"] = path;
		}
		else
		{
			[self buildXADPathsForFilesInDirectory:entry parentPath:path];
		}
	}
}


-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum
{
	return [self handleAtDataOffsetForDictionary:dict];
}

-(NSString *)formatName { return @"WARC"; }

@end
