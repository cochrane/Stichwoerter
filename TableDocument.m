//
//  TableDocument.m
//  Stichwörter
//
//  Created by Torsten Kammer on 24.02.13.
//
//

#import "TableDocument.h"

#import "SimpleWordprocessingMLFile.h"

static NSString *wordprocessingNamespace = @"http://schemas.openxmlformats.org/wordprocessingml/2006/main";

@interface TableDocument ()
{
	NSMutableArray *rows;
}

@end

@implementation TableDocument

- (id)init
{
	if (!(self = [super init])) return nil;
	
	rows = [NSMutableArray array];
	
	return self;
}

- (void)addLine:(NSArray *)contents;
{
	[rows addObject:contents];
}

- (NSData *)htmlRepresentation;
{
	NSXMLElement *html = [NSXMLElement elementWithName:@"html"];
	
	// Head
	NSXMLElement *head = [NSXMLElement elementWithName:@"head"];
	[html addChild:head];
	NSXMLElement *title = [NSXMLElement elementWithName:@"title" stringValue:@""];
	[head addChild:title];
	NSXMLElement *metaCharset = [NSXMLElement elementWithName:@"meta"];
	[metaCharset addAttribute:[NSXMLNode attributeWithName:@"charset" stringValue:@"UTF-8"]];
	[head addChild:metaCharset];
	
	// Body
	NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
	[html addChild:body];
	
	NSXMLElement *table = [NSXMLElement elementWithName:@"table"];
	[body addChild:table];
	
	// Headers
	if (self.headers)
	{
		NSXMLElement *row = [NSXMLElement elementWithName:@"tr"];
		[table addChild:row];
		for (NSString *header in self.headers)
			[row addChild:[NSXMLElement elementWithName:@"th" stringValue:header]];
	}
	
	// Rows
	for (NSArray *rowContents in rows)
	{
		NSXMLElement *row = [NSXMLElement elementWithName:@"tr"];
		[table addChild:row];
		for (NSString *cell in rowContents)
			[row addChild:[NSXMLElement elementWithName:@"td" stringValue:cell]];
	}
	
	// Prepare for writing
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithRootElement:html];
	NSXMLDTD *dtd = [[NSXMLDTD alloc] init];
	dtd.name = @"html";
	document.DTD = dtd;
	document.characterEncoding = @"UTF-8";
	document.documentContentKind = NSXMLDocumentHTMLKind;
	
	return document.XMLData;
}
- (NSData *)docxRepresentation;
{
	NSXMLElement *root = [NSXMLElement elementWithName:@"document"];
	[root addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:wordprocessingNamespace]];
	NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
	[root addChild:body];
	
	NSXMLElement *tbl = [NSXMLElement elementWithName:@"tbl"];
	[body addChild:tbl];
	
	// Headers
	if (self.headers)
	{
		NSXMLElement *tr = [NSXMLElement elementWithName:@"tr"];
		[tbl addChild:tr];
		for (NSString *header in self.headers)
		{
			NSXMLElement *tc = [NSXMLElement elementWithName:@"tc"];
			[tr addChild:tc];
			NSXMLElement *p = [NSXMLElement elementWithName:@"p"];
			[tc addChild:p];
			NSXMLElement *r = [NSXMLElement elementWithName:@"r"];
			[p addChild:r];
			NSXMLElement *t = [NSXMLElement elementWithName:@"t" stringValue:header];
			[r addChild:t];
			
			// Make it bold
			NSXMLElement *rPr = [NSXMLElement elementWithName:@"rPr"];
			NSXMLElement *b = [NSXMLElement elementWithName:@"b"];
			NSXMLElement *bCs = [NSXMLElement elementWithName:@"bCs"];
			[rPr addChild:b];
			[rPr addChild:bCs];
			[r addChild:rPr];
		}
	}
	
	// Rows
	for (NSArray *rowContents in rows)
	{
		NSXMLElement *tr = [NSXMLElement elementWithName:@"tr"];
		[tbl addChild:tr];
		for (NSString *cell in rowContents)
		{
			NSXMLElement *tc = [NSXMLElement elementWithName:@"tc"];
			[tr addChild:tc];
			NSXMLElement *p = [NSXMLElement elementWithName:@"p"];
			[tc addChild:p];
			NSXMLElement *r = [NSXMLElement elementWithName:@"r"];
			[p addChild:r];
			NSXMLElement *t = [NSXMLElement elementWithName:@"t" stringValue:cell];
			[r addChild:t];
		}
	}
	
	// Prepare for writing
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithRootElement:root];
	document.characterEncoding = @"UTF-8";
	document.standalone = YES;
	
	// Create the whole stuff around it
	SimpleWordprocessingMLFile *file = [[SimpleWordprocessingMLFile alloc] init];
	file.document = document;
	
	return file.docxRepresentation;
}

@end
