//
//  ExportSheetController.h
//  Stichwörter
//
//  Created by Torsten Kammer on 20.09.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ExportSheetController : NSWindowController
{
	void (^sheetEndBlock) (NSInteger, NSSavePanel *);
	NSDocument *parentDocument;
	NSWindow *parentWindow;
	
	BOOL includeDate;
	BOOL includeWord;
	BOOL includePage;
	NSUInteger exportFormat;
	NSUInteger exportMode;
}

- (void)runWithDocument:(NSDocument *)document endHandler:(void (^)(NSInteger, NSSavePanel *))handler;

@property (readonly, assign) BOOL fieldOptionsEnabled;

@property (assign) NSUInteger exportFormat; // 0 - Microsoft Word, 1 - HTML
@property (assign) NSUInteger exportMode; // 0 - directory, 1 - list

@property (assign) BOOL includeDate;
@property (assign) BOOL includeWord;
@property (assign) BOOL includePage;

- (IBAction)cancel:(id)sender;
- (IBAction)export:(id)sender;

@end
