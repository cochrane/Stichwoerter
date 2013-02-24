//
//  NSData+CRC32.m
//  Stichwörter
//
//  Created by Torsten Kammer on 24.02.13.
//
//

#import "NSData+CRC32.h"

#include <zlib.h>

@implementation NSData (CRC32)

- (uint32_t)crc32;
{
	uLong crc = crc32(0, Z_NULL, 0);
	return crc32(crc, self.bytes, self.length);
}

@end
