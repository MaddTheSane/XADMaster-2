/*
 * XADMacBinaryParser.m
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
#import "XADMacBinaryParser.h"

@implementation XADMacBinaryParser

+(int)requiredHeaderSize
{
	return 128;
}

+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name
{
	return [XADMacArchiveParser macBinaryVersionForHeader:data]>0;
}

-(void)parseWithSeparateMacForks
{
	[self setIsMacArchive:YES];

	[properties removeObjectForKey:XADDisableMacForkExpansionKey];
	[self addEntryWithDictionary:[NSMutableDictionary dictionaryWithObjectsAndKeys:
		@YES,XADIsMacBinaryKey,
	nil]];
}

-(CSHandle *)rawHandleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum
{
	return self.handle;
}

-(void)inspectEntryDictionary:(NSMutableDictionary *)dict
{
	NSNumber *rsrc=dict[XADIsResourceForkKey];
	if(rsrc&&rsrc.boolValue) return;

	if([self.name matchedByPattern:@"\\.sea(\\.|$)" options:REG_ICASE]||
	[[dict[XADFileNameKey] string] matchedByPattern:@"\\.(sea|sit|cpt)$" options:REG_ICASE])
	dict[XADIsArchiveKey] = @YES;

	// TODO: Better detection of embedded archives. Also applies to BinHex!
//	if([[dict objectForKey:XADFileTypeKey] unsignedIntValue]=='APPL')...
}

-(NSString *)formatName
{
	return @"MacBinary";
}

@end
