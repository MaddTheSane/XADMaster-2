/*
 * CSMemoryHandle.m
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
#import "CSMemoryHandle.h"

#if !__has_feature(objc_arc)
#error this file needs to be compiled with Automatic Reference Counting (ARC)
#endif

@implementation CSMemoryHandle
@synthesize data = backingdata;


+(CSMemoryHandle *)memoryHandleForReadingData:(NSData *)data
{
	return [[CSMemoryHandle alloc] initWithData:data];
}

+(CSMemoryHandle *)memoryHandleForReadingBuffer:(const void *)buf length:(unsigned)len
{
	return [[CSMemoryHandle alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)buf length:len freeWhenDone:NO]];
}

+(CSMemoryHandle *)memoryHandleForReadingMappedFile:(NSString *)filename
{
	return [[CSMemoryHandle alloc] initWithData:[NSData dataWithContentsOfFile:filename options:NSDataReadingMappedIfSafe error:NULL]];
}

+(CSMemoryHandle *)memoryHandleForWriting
{
	return [[CSMemoryHandle alloc] initWithData:[NSMutableData data]];
}


-(id)initWithData:(NSData *)data
{
	if(self=[super init])
	{
		memorypos=0;
		backingdata=data;
	}
	return self;
}

-(id)initAsCopyOf:(CSMemoryHandle *)other
{
	if(self=[super initAsCopyOf:other])
	{
		memorypos=other->memorypos;
		backingdata=other->backingdata;
	}
	return self;
}

-(NSMutableData *)mutableData
{
	if(![backingdata isKindOfClass:[NSMutableData class]]) [self _raiseNotSupported:_cmd];
	return (NSMutableData *)backingdata;
}



-(off_t)fileSize { return backingdata.length; }

@synthesize offsetInFile = memorypos;

-(BOOL)atEndOfFile { return memorypos==backingdata.length; }



-(void)seekToFileOffset:(off_t)offs
{
	if(offs<0) [self _raiseNotSupported:_cmd];
	if(offs>backingdata.length) [self _raiseEOF];
	memorypos=offs;
}

-(void)seekToEndOfFile { memorypos=backingdata.length; }

//-(void)pushBackByte:(int)byte {}

-(int)readAtMost:(int)num toBuffer:(void *)buffer
{
	if(!num) return 0;

	unsigned long len=backingdata.length;
	if(memorypos==len) return 0;
	if(memorypos+num>len) num=(int)(len-memorypos);
	memcpy(buffer,(uint8_t *)[backingdata bytes]+memorypos,num);
	memorypos+=num;
	return num;
}

-(void)writeBytes:(int)num fromBuffer:(const void *)buffer
{
	if(![backingdata isKindOfClass:[NSMutableData class]]) [self _raiseNotSupported:_cmd];
	NSMutableData *mbackingdata=(NSMutableData *)backingdata;

	if(memorypos+num>mbackingdata.length) mbackingdata.length = (long)memorypos+num;
	memcpy((uint8_t *)[mbackingdata mutableBytes]+memorypos,buffer,num);
	memorypos+=num;
}


-(NSData *)fileContents { return backingdata; }

-(NSData *)remainingFileContents
{
	if(memorypos==0) return backingdata;
	else return [super remainingFileContents];
}

-(NSData *)readDataOfLength:(int)length
{
	unsigned long totallen=backingdata.length;
	if(memorypos+length>totallen) [self _raiseEOF];
	NSData *subbackingdata=[backingdata subdataWithRange:NSMakeRange((long)memorypos,length)];
	memorypos+=length;
	return subbackingdata;
}

-(NSData *)readDataOfLengthAtMost:(int)length;
{
	unsigned long totallen=backingdata.length;
	if(memorypos+length>totallen) length=(int)(totallen-memorypos);
	NSData *subbackingdata=[backingdata subdataWithRange:NSMakeRange((long)memorypos,length)];
	memorypos+=length;
	return subbackingdata;
}

-(NSData *)copyDataOfLength:(int)length { return [self readDataOfLength:length]; }

-(NSData *)copyDataOfLengthAtMost:(int)length { return [self readDataOfLengthAtMost:length]; }

-(NSString *)name
{
	return [NSString stringWithFormat:@"%@ at %p",[backingdata class],backingdata];
}

-(NSString *)name
{
	return [NSString stringWithFormat:@"%@ at %p",[backingdata class],backingdata];
}

@end
