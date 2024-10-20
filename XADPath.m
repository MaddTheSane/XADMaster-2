/*
 * XADPath.m
 *
 * Copyright (c) 2017-present, MacPaw Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */
#import "XADPath.h"
#import "XADPlatform.h"

XADPathSeparator const XADUnixPathSeparator = "/";
XADPathSeparator const XADWindowsPathSeparator = "\\";
XADPathSeparator const XADEitherPathSeparator = "/\\";
XADPathSeparator const XADNoPathSeparator = "";

#if !__has_feature(objc_arc)
#error this file needs to be compiled with Automatic Reference Counting (ARC)
#endif

static BOOL IsSeparator(char c,const char *separators);
static BOOL NextComponent(const char *bytes,NSInteger length,NSInteger *start,NSInteger *end,NSString *encoding,const char *separators);
static NSString *StringForComponent(const char *bytes,NSInteger start,NSInteger end,NSString *encoding,const char *separators);
static BOOL IsComponentLeadingSlash(const char *bytes,NSInteger start,NSInteger end,const char *separators);
static BOOL IsDataASCIIOrSeparator(NSData *data,const char *separators);

@implementation XADPath

+(XADPath *)emptyPath
{
	static XADPath *emptypath=nil;
	if(!emptypath) emptypath=[[XADPath alloc] init];
	return emptypath;
}

+(XADPath *)pathWithString:(NSString *)string
{
	/*if([string isEqual:@"."]) return [XADPath emptyPath];
	else*/ return [[XADStringPath alloc] initWithComponentString:string];
}

+(XADPath *)pathWithStringComponents:(NSArray *)components
{
	NSInteger count=components.count;

	XADPath *lastpath=nil;
	for(NSInteger i=0;i<count;i++)
	{
		NSString *component=components[i];

		//if(i==0 && [component isEqual:@"."]) continue; // Skip leading . paths.

		XADPath *path=[[XADStringPath alloc] initWithComponentString:component parent:lastpath];
		lastpath=path;
	}

	if(!lastpath) return [XADPath emptyPath];
	else return lastpath;
}

+(XADPath *)separatedPathWithString:(NSString *)string
{
	NSArray *components=string.pathComponents;
	NSInteger count=components.count;
	if(count>1&&[components.lastObject isEqual:@"/"]) count--; // ignore ending slashes, just like NSString does

	XADPath *lastpath=nil;
	for(int i=0;i<count;i++)
	{
		NSString *component=components[i];

		//if(i==0 && [component isEqual:@"."]) continue; // Skip leading . paths.

		XADPath *path=[[XADStringPath alloc] initWithComponentString:component parent:lastpath];
		lastpath=path;
	}

	if(!lastpath) return [XADPath emptyPath];
	else return lastpath;
}

+(XADPath *)decodedPathWithData:(NSData *)bytedata encodingName:(NSString *)encoding separators:(const char *)separators
{
	const char *bytes=bytedata.bytes;
	NSInteger length=bytedata.length;

	XADPath *lastpath=nil;
	NSInteger start=0,end=0;
	while(NextComponent(bytes,length,&start,&end,encoding,separators))
	{
		NSString *component=StringForComponent(bytes,start,end,encoding,separators);

		//if(start==0 && [component isEqual:@"."]) continue; // Skip leading . paths.

		XADPath *path=[[XADStringPath alloc] initWithComponentString:component parent:lastpath];
		lastpath=path;
	}

	if(!lastpath) return [XADPath emptyPath];
	else return lastpath;
}

+(XADPath *)analyzedPathWithData:(NSData *)bytedata source:(XADStringSource *)stringsource
separators:(const char *)pathseparators
{
	[stringsource analyzeData:bytedata];

	if(IsDataASCIIOrSeparator(bytedata,pathseparators))
	{
		return [self decodedPathWithData:bytedata encodingName:XADASCIIStringEncodingName separators:pathseparators];
	}
	else
	{
/*		const char *bytes=[bytedata bytes];
		int length=[bytedata length];

		// Skip leading . paths.
		if(length>=1 && bytes[0]=='.')
		{
			if(length==1) return [XADPath emptyPath];
			if(IsSeparator(bytes[1],pathseparators))
			{
				int start=2;
				while(start<length && IsSeparator(bytes[start],pathseparators)) start++;
				if(start==length) return [XADPath emptyPath];

				NSData *subdata=[bytedata subdataWithRange:NSMakeRange(start,length-start)];
				return [[[XADRawPath alloc] initWithData:subdata source:stringsource separators:pathseparators] autorelease];
			}
		}*/

		return [[XADRawPath alloc] initWithData:bytedata source:stringsource separators:pathseparators];
	}
}




-(instancetype)init
{
	if((self=[super init]))
	{
		parent=nil;
		cachedcanonicalcomponents=nil;
		cachedencoding=nil;
	}
	return self;
}

-(instancetype)initWithParent:(XADPath *)parentpath
{
	if((self=[super init]))
	{
		if(!parentpath || parentpath.empty) parent=nil;
		else parent=parentpath;

		cachedcanonicalcomponents=nil;
		cachedencoding=nil;
	}
	return self;
}

-(instancetype)initWithPath:(XADPath *)path parent:(XADPath *)parentpath
{
	return [self initWithParent:parentpath];
}




-(BOOL)isAbsolute
{
	if(parent) return parent.absolute;
	else return self._isPartAbsolute;
}

-(BOOL)isEmpty
{
	if(parent) return NO;
	else return self._isPartEmpty;
}



-(BOOL)isEqual:(id)other
{
	if(![other isKindOfClass:[XADPath class]]) return NO;

	XADPath *path=other;
	if(parent && path->parent) return [parent isEqual:path->parent];
	else if(parent && !path->parent) return NO;
	else if(!parent && path->parent) return NO;
	else return YES;
}

-(BOOL)isCanonicallyEqual:(id)other
{
	return [self isCanonicallyEqual:other encodingName:self.encodingName];
}

-(BOOL)isCanonicallyEqual:(id)other encodingName:(NSString *)encoding
{
	NSArray *components1=[self canonicalPathComponentsWithEncodingName:encoding];
	NSArray *components2=[other canonicalPathComponentsWithEncodingName:encoding];
	return [components1 isEqual:components2];
}

-(BOOL)hasPrefix:(XADPath *)other
{
	return [self hasCanonicalPrefix:other encodingName:self.encodingName];
}

-(BOOL)hasCanonicalPrefix:(XADPath *)other
{
	return [self hasCanonicalPrefix:other encodingName:self.encodingName];
}

-(BOOL)hasCanonicalPrefix:(XADPath *)other encodingName:(NSString *)encoding
{
	NSArray *components1=[self canonicalPathComponentsWithEncodingName:encoding];
	NSArray *components2=[other canonicalPathComponentsWithEncodingName:encoding];
	NSInteger count1=components1.count;
	NSInteger count2=components2.count;

	if(count2>count1) return NO;

	for(int i=0;i<count2;i++)
	{
		if(![components1[i] isEqual:components2[i]]) return NO;
	}

	return YES;
}




-(NSInteger)depth
{
	return [self depthWithEncodingName:self.encodingName];
}

-(NSInteger)depthWithEncodingName:(NSString *)encoding
{
	NSInteger depth=[self _depthOfPartWithEncodingName:encoding];
	if(parent) depth+=[parent depthWithEncodingName:encoding];
	return depth;
}

-(NSArray *)pathComponents
{
	return [self pathComponentsWithEncodingName:self.encodingName];
}

-(NSArray *)pathComponentsWithEncodingName:(NSString *)encoding
{
	// TODO: This could cache the result for a given encoding.
	NSMutableArray *components=[NSMutableArray array];
	[self _addPathComponentsToArray:components encodingName:encoding];
	return [NSArray arrayWithArray:components];
}

-(NSArray *)canonicalPathComponents
{
	return [self canonicalPathComponentsWithEncodingName:self.encodingName];
}

-(NSArray *)canonicalPathComponentsWithEncodingName:(NSString *)encoding
{
	// Return cached components if we have them.
	if(cachedencoding && [cachedencoding isEqual:encoding]) return cachedcanonicalcomponents;

	// Build full component array.
	NSMutableArray *components=[NSMutableArray array];
	[self _addPathComponentsToArray:components encodingName:encoding];

	// If there are no . or .. components, there is no need to do any further work.
	if([components indexOfObject:@"."]!=NSNotFound&&
	[components indexOfObject:@".."]!=NSNotFound) return components;

	// Drop . anywhere in the path
	for(int i=0;i<components.count;)
	{
		NSString *component=components[i];
		if([component isEqual:@"."]) [components removeObjectAtIndex:i];
		else i++;
	}

	// Drop all .. that can be dropped
	for(int i=1;i<components.count;)
	{
		NSString *component1=components[i-1];
		NSString *component2=components[i];
		if(![component1 isEqual:@".."]&&[component2 isEqual:@".."])
		{
			[components removeObjectAtIndex:i];
			[components removeObjectAtIndex:i-1];
			if(i>1) i--;
		}
		else i++;
	}

	cachedcanonicalcomponents=[[NSArray alloc] initWithArray:components];
	cachedencoding=encoding;

	return cachedcanonicalcomponents;
}

-(void)_addPathComponentsToArray:(NSMutableArray *)components encodingName:(NSString *)encoding
{
	if(parent) [parent _addPathComponentsToArray:components encodingName:encoding];
	[self _addPathComponentsOfPartToArray:components encodingName:encoding];
}




-(NSString *)lastPathComponent
{
	return [self lastPathComponentWithEncodingName:self.encodingName];
}

-(NSString *)lastPathComponentWithEncodingName:(NSString *)encoding
{
	return [self _lastPathComponentOfPartWithEncodingName:encoding];
}

-(NSString *)firstPathComponent
{
	return [self firstPathComponentWithEncodingName:self.encodingName];
}

-(NSString *)firstPathComponentWithEncodingName:(NSString *)encoding
{
	if(parent) return [parent firstPathComponentWithEncodingName:encoding];
	else return [self _firstPathComponentOfPartWithEncodingName:encoding];
}

-(NSString *)firstCanonicalPathComponent
{
	return [self firstCanonicalPathComponentWithEncodingName:self.encodingName];
}

-(NSString *)firstCanonicalPathComponentWithEncodingName:(NSString *)encoding
{
	NSArray *components=[self canonicalPathComponentsWithEncodingName:encoding];
	if(components.count==0) return @"";
	else return components[0];
}

-(XADPath *)pathByDeletingLastPathComponent
{
	return [self pathByDeletingLastPathComponentWithEncodingName:self.encodingName];
}

-(XADPath *)pathByDeletingLastPathComponentWithEncodingName:(NSString *)encoding
{
	XADPath *deleted=[self _pathByDeletingLastPathComponentOfPartWithEncodingName:encoding];
	if(deleted) return deleted;
	else if(parent) return parent;
	else return [XADPath emptyPath];
}

-(XADPath *)pathByDeletingFirstPathComponent
{
	return [self pathByDeletingFirstPathComponentWithEncodingName:self.encodingName];
}

-(XADPath *)pathByDeletingFirstPathComponentWithEncodingName:(NSString *)encoding
{
	if(parent)
	{
		XADPath *newparent=[parent pathByDeletingFirstPathComponentWithEncodingName:encoding];
		if(!newparent.empty) return [self _copyWithParent:newparent];
		else return [self _copyWithParent:nil];
	}
	else
	{
		XADPath *deleted=[self _pathByDeletingFirstPathComponentOfPartWithEncodingName:encoding];
		if(deleted) return deleted;
		else return [XADPath emptyPath];
	}
}





-(XADPath *)pathByAppendingXADStringComponent:(XADString *)component
{
	if(component.source)
	{
		return [[XADRawPath alloc] initWithData:component.data
										 source:component.source separators:XADNoPathSeparator parent:self];
	}
	else
	{
		return [[XADStringPath alloc] initWithComponentString:component.string parent:self];
	}
}

-(XADPath *)pathByAppendingPath:(XADPath *)path
{
	if(path && !path.empty)
	{
		XADPath *appended=[self pathByAppendingPath:path->parent];
		return [path _copyWithParent:appended];
	}
	else
	{
		return self;
	}
}

-(XADPath *)_copyWithParent:(XADPath *)newparent
{
	return [[[self class] alloc] initWithPath:self parent:newparent];
}




-(NSString *)sanitizedPathString
{
	return [self sanitizedPathStringWithEncodingName:self.encodingName];
}

-(NSString *)sanitizedPathStringWithEncodingName:(NSString *)encoding
{
	NSArray *components=[self canonicalPathComponentsWithEncodingName:encoding];
	NSInteger count=components.count;
	NSInteger first=0;

	// Drop "/" at the start of the path.
	if(count && [components[0] isEqual:@"/"]) first++;

	if(first==count) return @".";

	NSMutableString *string=[NSMutableString string];
	for(NSInteger i=first;i<count;i++)
	{
		if(i!=first) [string appendString:@"/"];

		NSString *component=components[i];

		// Replace ".." components with "__Parent__". ".." components in the middle
		// of the path have already been collapsed by canonicalPathComponents.
		if([component isEqual:@".."])
		{
			[string appendString:@"__Parent__"];
		}
		else
		{
			NSString *sanitized=[XADPlatform sanitizedPathComponent:component];
			[string appendString:sanitized];
		}
	}

	return string;
}




// XADString interface.

-(BOOL)canDecodeWithEncodingName:(NSString *)encoding
{
	if(parent && ![parent canDecodeWithEncodingName:encoding]) return NO;
	return [self _canDecodePartWithEncodingName:encoding];
}

-(NSString *)string
{
	return [self stringWithEncodingName:self.encodingName];
}

-(NSString *)stringWithEncodingName:(NSString *)encoding
{
	NSArray *components=[self pathComponentsWithEncodingName:encoding];
	NSInteger count=components.count;

	if(count==0) return @".";
	else if(count==1) return components[0];

	NSMutableString *string=[NSMutableString string];

	for(NSInteger i=0;i<count;i++)
	{
		NSString *component=components[i];

		if(i==0 && [component isEqual:@"/"]) continue;
		if(i!=0) [string appendString:@"/"];

		// TODO: Should this method really map / to :?
		if([component rangeOfString:@"/"].location==NSNotFound) [string appendString:component];
		else
		{
			NSMutableString *newstring=[NSMutableString stringWithString:component];
			[newstring replaceOccurrencesOfString:@"/" withString:@":" options:0 range:NSMakeRange(0,newstring.length)];
			
			[string appendString:newstring];
		}
	}

	return [NSString stringWithString:string];
}

-(NSData *)data
{
	// NOTE: Doesn't map '/' to ':'.
	NSMutableData *data=[NSMutableData data];
	[self _appendPathToData:data];
	return [NSData dataWithData:data];
}

-(void)_appendPathToData:(NSMutableData *)data
{
	if(parent)
	{
		[parent _appendPathToData:data];
		[data appendBytes:"/" length:1];
	}
	else
	{
		if(!self._isPartAbsolute) [self _appendPathForPartToData:data];
	}
}




-(BOOL)encodingIsKnown
{
	XADStringSource *source=self.source;
	if(!source) return YES;
	if(source.hasFixedEncoding) return YES;
	return NO;
}

-(NSString *)encodingName
{
	XADStringSource *source=self.source;
	if(!source) return XADUTF8StringEncodingName; // TODO: what should this really return?
	return source.encodingName;
}

-(float)confidence
{
	XADStringSource *source=self.source;
	if(!source) return 1;
	return source.confidence;
}

-(XADStringSource *)source
{
	XADStringSource *source=self._sourceForPart;
	if(source) return source;
	else return parent.source;
}

#ifdef __APPLE__

-(BOOL)canDecodeWithEncoding:(NSStringEncoding)encoding
{
	return [self canDecodeWithEncodingName:[XADString encodingNameForEncoding:encoding]];
}

-(NSString *)stringWithEncoding:(NSStringEncoding)encoding
{
	return [self stringWithEncodingName:[XADString encodingNameForEncoding:encoding]];
}

-(NSString *)sanitizedPathStringWithEncoding:(NSStringEncoding)encoding;
{
	return [self sanitizedPathStringWithEncodingName:[XADString encodingNameForEncoding:encoding]];
}

-(NSStringEncoding)encoding
{
	XADStringSource *source=self.source;
	if(!source) return NSUTF8StringEncoding; // TODO: what should this really return?
	else return source.encoding;
}

#endif




// Other interfaces.

-(NSString *)description
{
	// TODO: more info?
	return self.string;
}

-(NSString *)debugDescription
{
	// TODO: more info?
	return self.string;
}

-(NSUInteger)hash
{
	return 0;
}

-(id)copyWithZone:(NSZone *)zone { return self; } // Class is immutable, so just return self.




// Deprecated.

-(XADPath *)safePath
{
	NSLog(@"Warning: -[XADPath safePath] is deprecated. Use -[XADPath sanitizedPathStringWithEncodingName:] instead.");

	NSArray *components=[self canonicalPathComponentsWithEncodingName:self.encodingName];
	NSInteger count=components.count;
	int first=0;

	// Drop "/" and ".." components at the start of the path.
	// "." and ".." components have already been stripped earlier.
	while(first<count)
	{
		NSString *component=components[first];
		if(![component isEqual:@".."]&&![component isEqual:@"/"]) break;
		first++;
	}

	if(first==0) return self;

	XADPath *lastpath=nil;
	for(int i=first;i<count;i++)
	{
		NSString *component=components[i];
		XADPath *path=[[XADStringPath alloc] initWithComponentString:component parent:lastpath];
		lastpath=path;
	}

	return lastpath;
}



// Subclass methods.

-(BOOL)_isPartAbsolute { return NO; }
-(BOOL)_isPartEmpty { return YES; }
-(NSInteger)_depthOfPartWithEncodingName:(XADStringEncodingName)encoding { return 0; }
-(void)_addPathComponentsOfPartToArray:(NSMutableArray *)array encodingName:(NSString *)encoding {}
-(NSString *)_lastPathComponentOfPartWithEncodingName:(NSString *)encoding { return @""; }
-(NSString *)_firstPathComponentOfPartWithEncodingName:(NSString *)encoding { return @""; }
-(XADPath *)_pathByDeletingLastPathComponentOfPartWithEncodingName:(NSString *)encoding { return nil; }
-(XADPath *)_pathByDeletingFirstPathComponentOfPartWithEncodingName:(NSString *)encoding { return nil; }
-(BOOL)_canDecodePartWithEncodingName:(NSString *)encoding { return YES; }
-(void)_appendPathForPartToData:(NSMutableData *)data {}
-(XADStringSource *)_sourceForPart { return nil; }

@end



@implementation XADStringPath

-(instancetype)initWithParent:(XADPath *)parentpath
{
	if (self = [super initWithParent:parentpath]) {
		
	}
	return self;
}

-(instancetype)initWithComponentString:(NSString *)pathstring
{
	if((self=[super init]))
	{
		string=[pathstring copy];
	}
	return self;
}

-(instancetype)initWithComponentString:(NSString *)pathstring parent:(XADPath *)parentpath
{
	if((self=[super initWithParent:parentpath]))
	{
		string=[pathstring copy];
	}
	return self;
}

-(instancetype)initWithPath:(XADStringPath *)path parent:(XADPath *)parentpath
{
	return [self initWithComponentString:path->string parent:parentpath];
}

-(BOOL)_isPartAbsolute
{
	return [string isEqual:@"/"];
}

-(BOOL)_isPartEmpty
{
	return string.length==0;
}

-(NSInteger)_depthOfPartWithEncodingName:(NSString *)encoding
{
	return 1;
}

-(void)_addPathComponentsOfPartToArray:(NSMutableArray *)array encodingName:(NSString *)encoding
{
	[array addObject:string];
}

-(NSString *)_lastPathComponentOfPartWithEncodingName:(NSString *)encoding
{
	return string;
}

-(NSString *)_firstPathComponentOfPartWithEncodingName:(NSString *)encoding
{
	return string;
}

-(XADPath *)_pathByDeletingLastPathComponentOfPartWithEncodingName:(NSString *)encoding
{
	return nil;
}

-(XADPath *)_pathByDeletingFirstPathComponentOfPartWithEncodingName:(NSString *)encoding
{
	return nil;
}

-(BOOL)_canDecodePartWithEncodingName:(NSString *)encoding
{
	return YES;
}

-(void)_appendPathForPartToData:(NSMutableData *)data
{
	[data appendData:[XADString escapedASCIIDataForString:string]];
}

-(XADStringSource *)_sourceForPart
{
	return nil;
}

-(BOOL)isEqual:(id)other
{
	if(![other isKindOfClass:[XADStringPath class]]) return NO;
	
	XADStringPath *path=other;
	return [string isEqual:path->string] && [super isEqual:other];
}

-(NSUInteger)hash
{
	return string.hash^parent.hash; // TODO: Maybe the parent hash is not needed?
}

@end




@implementation XADRawPath

-(instancetype)initWithParent:(XADPath *)parentpath
{
	if (self = [super initWithParent:parentpath]) {
		
	}
	return self;
}

-(instancetype)initWithData:(NSData *)bytedata source:(XADStringSource *)stringsource
separators:(const char *)pathseparators
{
	if((self=[super init]))
	{
		data=[bytedata copy];
		source=stringsource;
		separators=pathseparators;
	}
	return self;
}

-(instancetype)initWithData:(NSData *)bytedata source:(XADStringSource *)stringsource
separators:(const char *)pathseparators parent:(XADPath *)parentpath
{
	if((self=[super initWithParent:parentpath]))
	{
		data=[bytedata copy];
		source=stringsource;
		separators=pathseparators;
	}
	return self;
}

-(instancetype)initWithPath:(XADRawPath *)path parent:(XADPath *)parentpath
{
	return [self initWithData:path->data source:path->source
	separators:path->separators parent:parentpath];
}




-(BOOL)_isPartAbsolute
{
	if(data.length==0) return NO;
	const char *bytes=data.bytes;
	return IsSeparator(bytes[0],separators);
}

-(BOOL)_isPartEmpty
{
	if(data.length==0) return YES;
	return NO;
}

-(NSInteger)_depthOfPartWithEncodingName:(NSString *)encoding
{
	const char *bytes=data.bytes;
	NSInteger length=data.length;

	NSInteger depth=0,start=0,end=0;
	while(NextComponent(bytes,length,&start,&end,encoding,separators)) depth++;

	return depth;
}

-(void)_addPathComponentsOfPartToArray:(NSMutableArray *)array encodingName:(NSString *)encoding
{
	const char *bytes=data.bytes;
	NSInteger length=data.length;

	NSInteger start=0,end=0;
	while(NextComponent(bytes,length,&start,&end,encoding,separators))
	{
		[array addObject:StringForComponent(bytes,start,end,encoding,separators)];
	}
}

-(NSString *)_lastPathComponentOfPartWithEncodingName:(NSString *)encoding
{
	const char *bytes=data.bytes;
	NSInteger length=data.length;

	NSInteger start=0,end=0,laststart=0,lastend=0;
	while(NextComponent(bytes,length,&start,&end,encoding,separators))
	{
		laststart=start;
		lastend=end;
	}

	if(!laststart&&!lastend) return @"";
	else return StringForComponent(bytes,laststart,lastend,encoding,separators);
}

-(NSString *)_firstPathComponentOfPartWithEncodingName:(NSString *)encoding
{
	const char *bytes=data.bytes;
	NSInteger length=data.length;

	NSInteger start=0,end=0;
	if(!NextComponent(bytes,length,&start,&end,encoding,separators)) return @"";
	else return StringForComponent(bytes,start,end,encoding,separators);
}

-(XADPath *)_pathByDeletingLastPathComponentOfPartWithEncodingName:(NSString *)encoding
{
	const char *bytes=data.bytes;
	NSInteger length=data.length;

	NSInteger start=0,end=0,laststart=0,lastend=0;
	while(NextComponent(bytes,length,&start,&end,encoding,separators))
	{
		laststart=start;
		lastend=end;
	}

	if(!laststart&&!lastend) return nil;

	NSInteger earliest=0;
	if(length>0 && IsSeparator(bytes[0],separators)) earliest=1; // Deal with leading slashes.

	while(start>earliest && IsSeparator(bytes[start-1],separators)) start--;
	if(start==0) return nil;

	return [[XADRawPath alloc] initWithData:[data subdataWithRange:NSMakeRange(0,start)]
									 source:source separators:separators parent:parent];
}

-(XADPath *)_pathByDeletingFirstPathComponentOfPartWithEncodingName:(NSString *)encoding
{
	const char *bytes=data.bytes;
	NSInteger length=data.length;

	NSInteger start=0,end=0;
	if(!NextComponent(bytes,length,&start,&end,encoding,separators)) return nil;

	while(end<length && IsSeparator(bytes[end],separators)) end++;
	if(end==length) return nil;

	return [[XADRawPath alloc] initWithData:[data subdataWithRange:NSMakeRange(end,length-end)]
									 source:source separators:separators parent:parent];
}

-(BOOL)_canDecodePartWithEncodingName:(NSString *)encoding
{
	return [XADString canDecodeData:data encodingName:encoding];
}

-(void)_appendPathForPartToData:(NSMutableData *)mutabledata
{
	[mutabledata appendData:data];
}

@synthesize _sourceForPart=source;

-(BOOL)isEqual:(id)other
{
	if(![other isKindOfClass:[XADRawPath class]]) return NO;

	XADRawPath *path=other;
	return [data isEqual:path->data] && source==path->source &&
	strcmp(separators,path->separators)==0 && [super isEqual:other];
}

-(NSUInteger)hash
{
	return data.hash^parent.hash; // TODO: Maybe the parent hash is not needed?
}

@end




static BOOL IsSeparator(char c,const char *separators)
{
	while(*separators)
	{
		if(c==*separators) return YES;
		separators++;
	}
	return NO;
}

static BOOL NextComponent(const char *bytes,NSInteger length,NSInteger *start,NSInteger *end,
NSString *encoding,const char *separators)
{
	NSInteger offs=*end;

	// Check for a slash at the start of the path.
	if(offs==0 && length>0 && IsSeparator(bytes[0],separators))
	{
		*start=0;
		*end=1;
		return YES;
	}

	// Skip separator characters.
	while(offs<length&&IsSeparator(bytes[offs],separators)) offs++;
	if(offs>=length) return NO;

	// Remember the start of the next component, and find the end.
	*start=offs;
	while(offs<length)
	{
		// If we encounter a separator, first check if it looks like
		// the current component string can be decoded. This is to avoid
		// spurious splits in encodings like Shift_JIS.
		if(IsSeparator(bytes[offs],separators))
		{
			if([XADString canDecodeBytes:&bytes[*start] length:offs-*start
			encodingName:encoding]) break;
		}
		offs++;
	}

	*end=offs;

	return YES;
}

static NSString *StringForComponent(const char *bytes,NSInteger start,NSInteger end,
NSString *encoding,const char *separators)
{
	if(IsComponentLeadingSlash(bytes,start,end,separators)) return @"/";
	else return [XADString escapedStringForBytes:&bytes[start]
	length:end-start encodingName:encoding];
}

static BOOL IsComponentLeadingSlash(const char *bytes,NSInteger start,NSInteger end,const char *separators)
{
	return start==0 && end==1 && IsSeparator(bytes[0],separators);
}

static BOOL IsDataASCIIOrSeparator(NSData *data,const char *separators)
{
	const char *bytes=data.bytes;
	NSInteger length=data.length;
	for(NSInteger i=0;i<length;i++) if(bytes[i]&0x80 && !IsSeparator(bytes[i],separators)) return NO;
	return YES;
}
