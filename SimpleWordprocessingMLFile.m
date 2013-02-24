//
//  SimpleWordprocessingMLFile.m
//  Stichwörter
//
//  Created by Torsten Kammer on 24.02.13.
//
//

#import "SimpleWordprocessingMLFile.h"

#import "ZIPArchive.h"

static NSString *relsFilename = @"_rels/.rels";
static NSString *relsNamespace = @"http://schemas.openxmlformats.org/package/2006/relationships";
static NSString *documentRelationshipType = @"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument";

static NSString *contentTypesFilename = @"[Content_Types].xml";
static NSString *contentTypesNamespace = @"http://schemas.openxmlformats.org/package/2006/content-types";
static NSString *relsContentType = @"application/vnd.openxmlformats-package.relationships+xml";
static NSString *documentContentType = @"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml";

static NSString *documentFilename = @"word/document.xml";

@implementation SimpleWordprocessingMLFile

- (NSData *)docxRepresentation
{
	ZIPArchive *archive = [[ZIPArchive alloc] init];
	
	// Relationships
	NSXMLElement *relsRoot = [NSXMLElement elementWithName:@"Relationships"];
	[relsRoot addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:relsNamespace]];
	NSXMLElement *documentRelationship = [NSXMLElement elementWithName:@"Relationship"];
	[documentRelationship addAttribute:[NSXMLNode attributeWithName:@"Id" stringValue:@"rId1"]];
	[documentRelationship addAttribute:[NSXMLNode attributeWithName:@"Type" stringValue:documentRelationshipType]];
	[documentRelationship addAttribute:[NSXMLNode attributeWithName:@"Target" stringValue:documentFilename]];
	[relsRoot addChild:documentRelationship];
	NSXMLDocument *rels = [[NSXMLDocument alloc] initWithRootElement:relsRoot];
	rels.characterEncoding = @"UTF-8";
	[rels setStandalone:YES];
	
	[archive addFileNamed:relsFilename data:rels.XMLData];
	
	// Content types
	NSXMLElement *contentTypesRoot = [NSXMLElement elementWithName:@"Types" URI:contentTypesNamespace];
	[contentTypesRoot addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:contentTypesNamespace]];
	// - rels
	NSXMLElement *relsType = [NSXMLElement elementWithName:@"Override"];
	[relsType addAttribute:[NSXMLNode attributeWithName:@"PartName" stringValue:[@"/" stringByAppendingString:relsFilename]]];
	[relsType addAttribute:[NSXMLNode attributeWithName:@"ContentType" stringValue:relsContentType]];
	[contentTypesRoot addChild:relsType];
	// - document
	NSXMLElement *documentType = [NSXMLElement elementWithName:@"Override"];
	[documentType addAttribute:[NSXMLNode attributeWithName:@"PartName" stringValue:[@"/" stringByAppendingString:documentFilename]]];
	[documentType addAttribute:[NSXMLNode attributeWithName:@"ContentType" stringValue:documentContentType]];
	[contentTypesRoot addChild:documentType];
	
	NSXMLDocument *contentTypes = [[NSXMLDocument alloc] initWithRootElement:contentTypesRoot];
	contentTypes.characterEncoding = @"UTF-8";
	[contentTypes setStandalone:YES];
	
	[archive addFileNamed:contentTypesFilename data:contentTypes.XMLData];
	
	// Document
	[archive addFileNamed:documentFilename data:self.document.XMLData];
	
	// Write out
	NSData *data = [archive generateData];
	return data;
}

@end
