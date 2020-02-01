/*
 * XADSWFTagParser.m
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
#import "XADSWFTagParser.h"
#import "CSFileHandle.h"
#import "CSZlibHandle.h"


NSString *const SWFWrongMagicException=@"SWFWrongMagicException";
NSString *const SWFNoMoreTagsException=@"SWFNoMoreTagsException";


@implementation XADSWFTagParser
@synthesize version;
@synthesize compressed;
@synthesize rect;
@synthesize frames;
@synthesize framesPerSecond = fps;
@synthesize tag = currtag;
@synthesize tagLength = currlen;
@synthesize frame = currframe;
@synthesize handle = fh;
@synthesize spriteID = spriteid;
@synthesize subFrames = subframes;
@synthesize subTag = subtag;
@synthesize subTagLength = sublen;
@synthesize subFrame = subframe;

+(XADSWFTagParser *)parserWithHandle:(CSHandle *)handle
{
	return [[XADSWFTagParser alloc] initWithHandle:handle];
}

+(XADSWFTagParser *)parserForPath:(NSString *)path
{
	CSFileHandle *handle=[CSFileHandle fileHandleForReadingAtPath:path];
	return [[XADSWFTagParser alloc] initWithHandle:handle];
}

-(instancetype)initWithHandle:(CSHandle *)handle
{
	if((self=[super init]))
	{
		fh=handle;
	}
	return self;
}

-(void)parseHeader
{
	uint8_t magic[4];
	[fh readBytes:4 toBuffer:magic];

	version=magic[3];
	totallen=[fh readUInt32LE];

	if((magic[0]!='F'&&magic[0]!='C')||magic[1]!='W'||magic[2]!='S')
	[NSException raise:SWFWrongMagicException format:@"Not a Shockwave Flash file."];

	if(magic[0]=='C')
	{
		CSZlibHandle *zh=[CSZlibHandle zlibHandleWithHandle:fh];
		fh=zh;
		compressed=YES;
	}
	else
	{
		compressed=NO;
	}

	rect=SWFParseRect(fh);
	fps=[fh readUInt16LE];
	frames=[fh readUInt16LE];

	nexttag=fh.offsetInFile;

	currtag=0;
	currlen=0;
	currframe=0;
}


-(int)nextTag
{
	if(!nexttag) [NSException raise:SWFNoMoreTagsException format:@"No more tags available in the SWF file."];
	if(currtag==SWFShowFrameTag) currframe++;

	[fh seekToFileOffset:nexttag];

	int tagval=[fh readUInt16LE];

	currtag=tagval>>6;
	if(currtag==0)
	{
		nexttag=0;
		return 0;
	}

	currlen=tagval&0x3f;
	if(currlen==0x3f) currlen=[fh readUInt32LE];

	nexttag=fh.offsetInFile+currlen;

	return currtag;
}

-(int)tagBytesLeft { return (int)(nexttag-fh.offsetInFile); }
-(double)time { return (double)currframe/((double)fps/256.0); }

-(CSHandle *)tagHandle { return [fh subHandleOfLength:self.tagBytesLeft]; }
-(NSData *)tagContents { return [fh readDataOfLength:self.tagBytesLeft]; }



-(void)parseDefineSpriteTag
{
	spriteid=[fh readUInt16LE];
	subframes=[fh readUInt16LE];

	nextsubtag=fh.offsetInFile;

	subtag=0;
	sublen=0;
	subframe=0;
}

-(int)nextSubTag
{
	if(!nextsubtag) [NSException raise:SWFNoMoreTagsException format:@"No more subtags available in the SWF file."];
	if(subtag==SWFShowFrameTag) subframe++;

	[fh seekToFileOffset:nextsubtag];

	int tagval=[fh readUInt16LE];

	subtag=tagval>>6;
	if(subtag==0)
	{
		nextsubtag=0;
		return 0;
	}

	sublen=tagval&0x3f;
	if(sublen==0x3f) sublen=[fh readUInt32LE];

	nextsubtag=fh.offsetInFile+sublen;

	return subtag;
}

-(int)subTagBytesLeft { return (int)(nextsubtag-fh.offsetInFile); }
-(double)subTime { return (double)subframe/((double)fps/256.0); }

@end
