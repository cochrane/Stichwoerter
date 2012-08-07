//
//  RebaseSheetController.h
//  Stichwörter
//
//  Created by Torsten Kammer on 18.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RebaseSheetController : NSWindowController
{
	void (^sheetEndHandler) (NSInteger result, NSUInteger oldStart, NSUInteger newStart);
	
	NSUInteger oldStart;
	NSUInteger newStart;
}

@property (assign) NSUInteger oldStart;
@property (assign) NSUInteger newStart;

- (void)runWithDocument:(NSDocument *)document endHandler:(void (^) (NSInteger result, NSUInteger oldStart, NSUInteger newStart))handler;

- (IBAction)cancel:(id)sender;
- (IBAction)rebase:(id)sender;

@end
