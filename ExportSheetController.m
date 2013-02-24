//
//  ExportSheetController.m
//  Stichwörter
//
//  Created by Torsten Kammer on 20.09.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ExportSheetController.h"

static NSString *ExportDocFormatKey = @"doc";
static NSString *ExportHTMLFormatKey = @"HTML";
static NSString *ExportFormatKey = @"ExportFormat";
static NSString *ExportListTypeKey = @"list";
static NSString *ExportDirectoryTypeKey = @"directory";
static NSString *ExportTypeKey = @"ExportType";

static NSString *ExportIncludesDateKey = @"ExportIncludesDate";
static NSString *ExportIncludesWordKey = @"ExportIncludesKeyword";
static NSString *ExportIncludesPageKey = @"ExportIncludesPage";

static NSString *ExportDirectoryURLKey = @"ExportDirectoryURL";

@implementation ExportSheetController

@synthesize exportFormat;
@synthesize exportMode;
@synthesize includeDate;
@synthesize includeWord;
@synthesize includePage;

+ (NSSet *)keyPathsForValuesAffectingFieldOptionsEnabled;
{
	return [NSSet setWithObject:@"exportMode"];
}

- (BOOL)fieldOptionsEnabled;
{
	return (self.exportMode == 1);
}

- (id)init
{
	if ((self = [super initWithWindowNibName:@"ExportSheet"]) == nil) return nil;
	
	// Find documents directory
	NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
	
	NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:ExportDocFormatKey, ExportFormatKey,
							  ExportDirectoryTypeKey, ExportTypeKey,
							  [NSNumber numberWithBool:NO], ExportIncludesDateKey,
							  [NSNumber numberWithBool:YES], ExportIncludesWordKey,
							  [NSNumber numberWithBool:YES], ExportIncludesPageKey,
							  [url absoluteString], ExportDirectoryURLKey,
							  nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	self.includeDate = [[NSUserDefaults standardUserDefaults] boolForKey:ExportIncludesDateKey];
	self.includeWord = [[NSUserDefaults standardUserDefaults] boolForKey:ExportIncludesWordKey];
	self.includePage = [[NSUserDefaults standardUserDefaults] boolForKey:ExportIncludesPageKey];

	if ([[[NSUserDefaults standardUserDefaults] stringForKey:ExportFormatKey] isEqual:ExportHTMLFormatKey])
		self.exportFormat = 1;
	else
		self.exportFormat = 0;
	
	if ([[[NSUserDefaults standardUserDefaults] stringForKey:ExportTypeKey] isEqual:ExportListTypeKey])
		self.exportMode = 1;
	else
		self.exportMode = 0;
	
	return self;
}

- (void)runWithDocument:(NSDocument *)document endHandler:(void (^)(NSInteger, NSSavePanel *))handler;
{
	sheetEndBlock = [handler copy];
	parentDocument = document;
	parentWindow = [document windowForSheet];
	[[NSApplication sharedApplication] beginSheet:[self window] modalForWindow:parentWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)cancel:(id)sender;
{
	[[self window] orderOut:sender];
	sheetEndBlock(NSCancelButton, nil);
}

- (IBAction)export:(id)sender;
{
	[[self window] orderOut:sender];
	[[NSApplication sharedApplication] endSheet:[self window] returnCode:0];
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setCanCreateDirectories:YES];
	[savePanel setCanSelectHiddenExtension:YES];
	[savePanel setPrompt:NSLocalizedString(@"Export", @"Prompt for export save panel")];
	[savePanel setDirectoryURL:[[NSUserDefaults standardUserDefaults] URLForKey:ExportDirectoryURLKey]];
	
	if (self.exportFormat == 1)
	{
		[savePanel setNameFieldStringValue:[[[parentDocument displayName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"html"]];
		[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"public.html"]];
	}
	else
	{
		[savePanel setNameFieldStringValue:[[[parentDocument displayName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"doc"]];
		[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"com.microsoft.word.doc"]];
	}
	
	[savePanel beginSheetModalForWindow:parentWindow completionHandler:^(NSInteger result){
		if (result == NSCancelButton)
		{
			sheetEndBlock(NSCancelButton, nil);
			return;
		}
		
		[[NSUserDefaults standardUserDefaults] setBool:self.includeDate forKey:ExportIncludesDateKey];
		[[NSUserDefaults standardUserDefaults] setBool:self.includeWord forKey:ExportIncludesWordKey];
		[[NSUserDefaults standardUserDefaults] setBool:self.includePage forKey:ExportIncludesPageKey];
		
		if (self.exportFormat == 1)
			[[NSUserDefaults standardUserDefaults] setObject:ExportHTMLFormatKey forKey:ExportFormatKey];
		else 
			[[NSUserDefaults standardUserDefaults] setObject:ExportDocFormatKey forKey:ExportFormatKey];
		
		if (self.exportMode == 1)
			[[NSUserDefaults standardUserDefaults] setObject:ExportListTypeKey forKey:ExportTypeKey];
		else 
			[[NSUserDefaults standardUserDefaults] setObject:ExportDirectoryTypeKey forKey:ExportTypeKey];
		
		[[NSUserDefaults standardUserDefaults] setURL:[savePanel directoryURL] forKey:ExportDirectoryURLKey];
		sheetEndBlock(NSOKButton, savePanel);
	}];
}

@end
