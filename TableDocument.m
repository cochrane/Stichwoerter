//
//  TableDocument.m
//  Stichwörter
//
//  Created by Torsten Kammer on 24.02.13.
//
//

#import "TableDocument.h"

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
	return nil;
}

@end
