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
- (NSData *)rawDeflatedData;
{
	z_stream stream;
	stream.avail_in = self.length;
	stream.next_in = (uint8_t *) self.bytes;
	stream.zalloc = Z_NULL;
	stream.zfree = Z_NULL;
	stream.opaque = Z_NULL;
	
	deflateInit2(&stream, 9, Z_DEFLATED, -15, 9, Z_DEFAULT_STRATEGY);
	
	NSUInteger maxSize = deflateBound(&stream, self.length);
	
	uint8_t *outputData = malloc(maxSize);
	stream.next_out = outputData;
	stream.avail_out = maxSize;

	while(stream.avail_out > 0)
	{
		int ret = deflate(&stream, Z_FINISH);
		if (ret != Z_OK)
			break;
	}
	
	deflateEnd(&stream);
	
	return [NSData dataWithBytesNoCopy:outputData length:maxSize - stream.avail_out];
}

@end
