//
//  ZIPArchive.m
//  Stichwörter
//
//  Created by Torsten Kammer on 24.02.13.
//
//

#import "ZIPArchive.h"

#import "NSData+CRC32.h"

struct ZipLocalFileHeader
{
	uint8_t signature[4];
	uint16_t versionNeededToExtract;
	uint16_t generalPurposeBitFlag;
	uint16_t compressionMethod;
	uint16_t lastModFileTime;
	uint16_t lastModFileDate;
	uint32_t crc32;
	uint32_t compressedSize;
	uint32_t uncompressedSize;
	uint16_t fileNameLength;
	uint16_t extraFieldLength;
	uint8_t filename[];
} __attribute((packed));

struct ZipCentralDirectoryFileHeader
{
	uint8_t signature[4];
	uint16_t versionMadeBy;
	uint16_t versionNeededToExtract;
	uint16_t generalPurposeBitFlag;
	uint16_t compressionMethod;
	uint16_t lastModFileTime;
	uint16_t lastModFileDate;
	uint32_t crc32;
	uint32_t compressedSize;
	uint32_t uncompressedSize;
	uint16_t fileNameLength;
	uint16_t extraFieldLnegth;
	uint16_t fileCommentLength;
	uint16_t diskNumberStart;
	uint16_t internalFileAttributes;
	uint32_t externalFileAttributes;
	uint32_t relativeOffsetOfLocalHeader;
	uint8_t filename[];
} __attribute((packed));

struct ZipEndOfCentralDirectoryRecord
{
	uint8_t signature[4];
	uint16_t numberOfThisDisk;
	uint16_t numberOfDiskWithStartOfCentralDirectory;
	uint16_t numberOfEntriesInCentralDirectoryOnThisDisk;
	uint16_t numberOfEntriesInCentralDirectory;
	uint32_t sizeOfCentralDirectory;
	uint32_t offsetOfStartOfCentralDirectoryWithRespectToStartingDiskNumber;
	uint16_t commentLength;
} __attribute((packed));

const uint8_t ZipLocalFileHeaderSignature[4] = { 0x50, 0x4b, 0x03, 0x04  };
const uint8_t ZipCentralDirectoryFileHeaderSignature[4] = { 0x50, 0x4b, 0x01, 0x02 };
const uint8_t ZipEndOfCentralDirectoryRecordSignature[4] = { 0x50, 0x4b,0x05, 0x06 };

@interface ZIPArchive ()

@property (nonatomic) NSMutableDictionary *files;

@end

@implementation ZIPArchive

- (id)init
{
	if (!(self = [super init])) return nil;
	
	self.files = [NSMutableDictionary dictionary];
	
	return self;
}

- (void)addFileNamed:(NSString *)localName data:(NSData *)data;
{
	[self.files setObject:data forKey:localName];
}

- (NSData *)generateData
{
	NSMutableData *archiveData = [NSMutableData data];
	NSMutableData *centralDirectory = [NSMutableData data];
	
	for (NSString *filename in self.files)
	{
		NSData *fileData = [self.files objectForKey:filename];
		NSData *compressed = fileData.rawDeflatedData;
		BOOL isCompressed = compressed.length < fileData.length;
		uint32_t crc32 = fileData.crc32;
		
		// Convert file name to UTF-8
		NSUInteger maximumNameLength = [filename maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];
		uint8_t *filenameData = malloc(maximumNameLength);
		NSUInteger actualNameLength;
		[filename getBytes:filenameData maxLength:maximumNameLength usedLength:&actualNameLength encoding:NSUTF8StringEncoding options:NSStringEncodingConversionExternalRepresentation range:NSMakeRange(0, filename.length) remainingRange:NULL];
		
		// Fill in local header
		NSUInteger localHeaderLength = sizeof(struct ZipLocalFileHeader) + actualNameLength;
		struct ZipLocalFileHeader *localHeader = calloc(1, localHeaderLength);
		memcpy(localHeader->signature, ZipLocalFileHeaderSignature, 4);
		localHeader->versionNeededToExtract = 20; // Default
		localHeader->generalPurposeBitFlag = isCompressed ? 6 : 0; // Max compression
		localHeader->compressionMethod = isCompressed ? 8 : 0; // Deflate
		localHeader->lastModFileTime = 0; // No date set
		localHeader->lastModFileDate = 0; // No date set
		localHeader->crc32 = crc32;
		localHeader->compressedSize = (uint32_t) (isCompressed ? compressed.length : fileData.length);
		localHeader->uncompressedSize = (uint32_t) fileData.length;
		localHeader->fileNameLength = (uint16_t) actualNameLength;
		localHeader->extraFieldLength = 0; // No extra field
		memcpy(localHeader->filename, filenameData, actualNameLength);
		
		// Fill in global header
		NSUInteger centralDirectoryHeaderLength = sizeof(struct ZipCentralDirectoryFileHeader) + actualNameLength;
		struct ZipCentralDirectoryFileHeader *centralDirectoryHeader = calloc(1, centralDirectoryHeaderLength);
		memcpy(centralDirectoryHeader->signature, ZipCentralDirectoryFileHeaderSignature, 4);
		centralDirectoryHeader->versionMadeBy = (45 << 8) | 19; // Version 4.5, which is what Word uses. On Mac OS X
		centralDirectoryHeader->versionNeededToExtract = 20; // Default
		centralDirectoryHeader->generalPurposeBitFlag = isCompressed ? 6 : 0; // Max compression
		centralDirectoryHeader->compressionMethod = isCompressed ? 8 : 0; // Deflate
		centralDirectoryHeader->lastModFileTime = 0; // No date set
		centralDirectoryHeader->lastModFileDate = 0; // No date set
		centralDirectoryHeader->crc32 = crc32;
		centralDirectoryHeader->compressedSize = (uint32_t) (isCompressed ? compressed.length : fileData.length);
		centralDirectoryHeader->uncompressedSize = (uint32_t) fileData.length;
		centralDirectoryHeader->fileNameLength = (uint16_t) actualNameLength;
		centralDirectoryHeader->extraFieldLnegth = 0; // No extra field
		centralDirectoryHeader->fileCommentLength = 0; // No extra field
		centralDirectoryHeader->diskNumberStart = 0; // Only one disc
		centralDirectoryHeader->internalFileAttributes = 0; // No attribs
		centralDirectoryHeader->externalFileAttributes = 0; // No attribs
		centralDirectoryHeader->relativeOffsetOfLocalHeader = (uint32_t) archiveData.length;
		memcpy(centralDirectoryHeader->filename, filenameData, actualNameLength);
		
		// Append data
		[archiveData appendBytes:localHeader length:localHeaderLength];
		[archiveData appendData:isCompressed ? compressed : fileData];
		[centralDirectory appendBytes:centralDirectoryHeader length:centralDirectoryHeaderLength];
		
		// Cleanup
		free(localHeader);
		free(centralDirectoryHeader);
		free(filenameData);
	}
	
	// Fill in end of central directory record
	struct ZipEndOfCentralDirectoryRecord endOfCentralDirectoryRecord;
	memcpy(endOfCentralDirectoryRecord.signature, ZipEndOfCentralDirectoryRecordSignature, 4);
	endOfCentralDirectoryRecord.numberOfThisDisk = 0;
	endOfCentralDirectoryRecord.numberOfDiskWithStartOfCentralDirectory = 0;
	endOfCentralDirectoryRecord.numberOfEntriesInCentralDirectoryOnThisDisk = (uint16_t) self.files.count;
	endOfCentralDirectoryRecord.numberOfEntriesInCentralDirectory = (uint16_t) self.files.count;
	endOfCentralDirectoryRecord.sizeOfCentralDirectory = (uint32_t) centralDirectory.length;
	endOfCentralDirectoryRecord.offsetOfStartOfCentralDirectoryWithRespectToStartingDiskNumber = (uint32_t) archiveData.length;
	endOfCentralDirectoryRecord.commentLength = 0;
	
	// Append it directory
	[centralDirectory appendBytes:&endOfCentralDirectoryRecord length:sizeof(endOfCentralDirectoryRecord)];
	
	// Assemble and return
	[archiveData appendData:centralDirectory];
	
	return archiveData;
}

@end
