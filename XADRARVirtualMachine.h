/*
 * XADRARVirtualMachine.h
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
#import "CSInputBuffer.h"
#import "RARVirtualMachine.h"


uint32_t CSInputNextRARVMNumber(CSInputBuffer *input);



@class XADRARProgramCode,XADRARProgramInvocation;

@interface XADRARVirtualMachine:NSObject
{
	@public
	RARVirtualMachine vm;
}

-(instancetype)init;

-(uint8_t *)memory;

-(void)setRegisters:(uint32_t *)newregisters;

-(void)readMemoryAtAddress:(uint32_t)address length:(NSInteger)length toBuffer:(uint8_t *)buffer;
-(void)readMemoryAtAddress:(uint32_t)address length:(NSInteger)length toMutableData:(NSMutableData *)data;
-(void)writeMemoryAtAddress:(uint32_t)address length:(NSInteger)length fromBuffer:(const uint8_t *)buffer;
-(void)writeMemoryAtAddress:(uint32_t)address length:(NSInteger)length fromData:(NSData *)data;

-(uint32_t)readWordAtAddress:(uint32_t)address;
-(void)writeWordAtAddress:(uint32_t)address value:(uint32_t)value;

-(BOOL)executeProgramCode:(XADRARProgramCode *)code;

@end

static inline uint32_t XADRARVirtualMachineRead32(XADRARVirtualMachine *self,uint32_t address)
{
	return RARVirtualMachineRead32(&self->vm,address);
}

static inline void XADRARVirtualMachineWrite32(XADRARVirtualMachine *self,uint32_t address,uint32_t val)
{
	RARVirtualMachineWrite32(&self->vm,address,val);
}

static inline uint32_t XADRARVirtualMachineRead8(XADRARVirtualMachine *self,uint32_t address)
{
	return RARVirtualMachineRead8(&self->vm,address);
}

static inline void XADRARVirtualMachineWrite8(XADRARVirtualMachine *self,uint32_t address,uint32_t val)
{
	RARVirtualMachineWrite8(&self->vm,address,val);
}



@interface XADRARProgramCode:NSObject
{
	NSMutableData *opcodes;
	NSData *staticdata;
	NSMutableData *globalbackup;

	uint64_t fingerprint;
}

-(instancetype)initWithByteCode:(const uint8_t *)bytes length:(NSInteger)length;

-(BOOL)parseByteCode:(const uint8_t *)bytes length:(NSInteger)length;
-(void)parseOperandFromBuffer:(CSInputBuffer *)input addressingMode:(unsigned int *)modeptr
value:(uint32_t *)valueptr byteMode:(BOOL)bytemode isRelativeJump:(BOOL)isjump
currentInstructionOffset:(NSInteger)instructionoffset;

@property (readonly, assign) RAROpcode *opcodes NS_RETURNS_INNER_POINTER;
@property (readonly) NSInteger numberOfOpcodes;
@property (readonly, copy) NSData *staticData;
@property (readonly, retain) NSMutableData *globalBackup;
@property (readonly) uint64_t fingerprint;

-(NSString *)disassemble;

@end



@interface XADRARProgramInvocation:NSObject
{
	XADRARProgramCode *programcode;

	uint32_t initialregisters[8];
	NSMutableData *globaldata;
}

-(instancetype)initWithProgramCode:(XADRARProgramCode *)code globalData:(NSData *)data registers:(uint32_t *)registers;

@property (readonly, retain) XADRARProgramCode *programCode;
@property (readonly, copy) NSData *globalData;

-(uint32_t)initialRegisterState:(NSInteger)n;
-(void)setInitialRegisterState:(NSInteger)n toValue:(uint32_t)val;
-(void)setGlobalValueAtOffset:(NSInteger)offs toValue:(uint32_t)val;

-(void)backupGlobalData;
-(void)restoreGlobalDataIfAvailable;

-(BOOL)executeOnVitualMachine:(XADRARVirtualMachine *)vm;

@end
