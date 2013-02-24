//
//  RebaseSheetController.m
//  Stichwörter
//
//  Created by Torsten Kammer on 18.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "RebaseSheetController.h"


@implementation RebaseSheetController

@synthesize newStart;
@synthesize oldStart;

- (id)init
{
	if ((self = [super initWithWindowNibName:@"RebaseSheet"]) == nil) return nil;
	
	self.oldStart = 1;
	self.newStart = 1;
	
	return self;
}

- (void)runWithDocument:(NSDocument *)document endHandler:(void (^)(NSInteger, NSUInteger, NSUInteger))handler
{
	sheetEndHandler = [handler copy];
	
	[[NSApplication sharedApplication] beginSheet:self.window modalForWindow:document.windowForSheet modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)rebase:(id)sender;
{
	[self.window orderOut:sender];
	[[NSApplication sharedApplication] endSheet:self.window returnCode:0];
	
	sheetEndHandler(NSOKButton, self.oldStart, self.newStart);
}

- (IBAction)cancel:(id)sender;
{
	[self.window orderOut:sender];
	[[NSApplication sharedApplication] endSheet:self.window returnCode:0];
	
	sheetEndHandler(NSCancelButton, NSNotFound, NSNotFound);
}

@end
