/*
 * CRC.h
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
#ifndef __XADMASTER_CRC_H__
#define __XADMASTER_CRC_H__

#include <stdint.h>
#include "XADTypes.h"

XADEXTERN uint32_t XADCRC(uint32_t prevcrc,uint8_t byte,const uint32_t *table);
XADEXTERN uint32_t XADCalculateCRC(uint32_t prevcrc,const uint8_t *buffer,size_t length,const uint32_t *table);

XADEXTERN uint64_t XADCRC64(uint64_t prevcrc,uint8_t byte,const uint64_t *table);
XADEXTERN uint64_t XADCalculateCRC64(uint64_t prevcrc,const uint8_t *buffer,size_t length,const uint64_t *table);

XADEXTERN int XADUnReverseCRC16(int val);

XADEXTERN const uint32_t XADCRCTable_a001[256];
XADEXTERN const uint32_t XADCRCReverseTable_1021[256];
XADEXTERN const uint32_t XADCRCTable_edb88320[256];
XADEXTERN const uint64_t XADCRCTable_c96c5795d7870f42[256];

#endif
