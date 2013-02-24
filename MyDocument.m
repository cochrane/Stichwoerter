//
//  MyDocument.m
//  Stichwörter
//
//  Created by Torsten Kammer on 20.09.09.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//

#import "MyDocument.h"

#import "ExportSheetController.h"
#import "KeywordExporter.h"
#import "RebaseSheetController.h"

static NSString *StichwoerterPboardType = @"de.ferroequinologist.stw.pboardtype";

@interface MyDocument ()

- (NSArray *)_selectedEntries;

- (void)cut:(id)sender;
- (void)copy:(id)sender;
- (void)paste:(id)sender;
- (void)delete:(id)sender;

@end

@implementation MyDocument

@synthesize currentEntryPage;
@synthesize currentEntryWord;

- (id)init 
{
    self = [super init];
    if (self != nil) {
        // initialization code
		self.currentEntryPage = 1;
		self.currentEntryWord = @"";
    }
    return self;
}

- (NSString *)windowNibName 
{
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController 
{
    [super windowControllerDidLoadNib:windowController];
    // user interface preparation code
}

- (IBAction)goToNextPage:(id)sender;
{
#pragma unused(sender)
	self.currentEntryPage += 1;
}

- (IBAction)saveEntry:(id)sender;
{
#pragma unused(sender)
	if (!self.currentEntryWord || [self.currentEntryWord isEqual:@""])
	{
		NSBeep();
		return;
	}
	
	[self insertEntryWithWord:self.currentEntryWord date:[NSDate date] page:self.currentEntryPage];
	
	self.currentEntryWord = @"";
}

- (void)insertEntryWithWord:(NSString *)word date:(NSDate *)date page:(NSInteger)page;
{
	// First step: Find if word already exists.
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Keyword" inManagedObjectContext:[self managedObjectContext]]];
	[fetchRequest setFetchLimit:1];
	[fetchRequest setIncludesPropertyValues:NO];
	[fetchRequest setIncludesPendingChanges:YES];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"word = %@", word]];
	
	NSArray *result = [[self managedObjectContext] executeFetchRequest:fetchRequest error:NULL];
	
	NSManagedObject *keyword = nil;
	if ([result count] == 0)
	{
		keyword = [NSEntityDescription insertNewObjectForEntityForName:@"Keyword" inManagedObjectContext:[self managedObjectContext]];
		[keyword setValue:word forKey:@"word"];
	}
	else
		keyword = [result objectAtIndex:0];
	
	// Enter entry
	NSManagedObject *entry = [NSEntityDescription insertNewObjectForEntityForName:@"Entry" inManagedObjectContext:[self managedObjectContext]];
	[entry setValue:[NSNumber numberWithInteger:page] forKey:@"page"];
	[entry setValue:keyword forKey:@"word"];
	[entry setValue:date forKey:@"enteredOn"];
}

#pragma mark -
#pragma mark General Management

- (IBAction)rebase:(id)sender
{
	RebaseSheetController *controller = [[RebaseSheetController alloc] init];
	[controller runWithDocument:self endHandler:^(NSInteger result, NSUInteger oldStart, NSUInteger newStart){
		if (result == NSCancelButton) return;
		
		NSFetchRequest *allHigherPagesRequest = [[NSFetchRequest alloc] init];
		[allHigherPagesRequest setEntity:[NSEntityDescription entityForName:@"Entry" inManagedObjectContext:[self managedObjectContext]]];
		[allHigherPagesRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"page" ascending:YES]]];
		[allHigherPagesRequest setPredicate:[NSPredicate predicateWithFormat:@"page >= %@", [NSNumber numberWithUnsignedInteger:oldStart]]];
		[allHigherPagesRequest setIncludesPropertyValues:YES];
		[allHigherPagesRequest setIncludesPendingChanges:YES];
		
		NSError *error = nil;
		NSArray *higherPages = [[self managedObjectContext] executeFetchRequest:allHigherPagesRequest error:&error];
		if (!higherPages)
		{
			[self presentError:error];
			return;
		}
		
		NSInteger diff = newStart - oldStart;
		
		for (NSManagedObject *entry in higherPages)
		{
			NSUInteger oldPage = [[entry valueForKey:@"page"] unsignedIntegerValue];
			[entry setValue:[NSNumber numberWithUnsignedInteger:oldPage + diff] forKey:@"page"];
		}
	}];
}

#pragma mark -
#pragma mark Exporting

- (IBAction)export:(id)sender
{
#pragma unused(sender)
	ExportSheetController *controller = [[ExportSheetController alloc] init];
	[controller runWithDocument:self endHandler:^(NSInteger result, NSSavePanel *savePanel) {
		if (result == NSCancelButton)
			return;
		
		NSData *htmlData = nil;
		NSError *error = nil;
		if (controller.exportMode == 1) // List
		{
			NSArray *sortDescriptors;
			if (controller.includeDate)
				sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"enteredOn" ascending:NO]];
			else
				sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"page" ascending:YES]];
			
			NSDictionary *exportOptions = [NSDictionary dictionaryWithObjectsAndKeys:@"YES", ExporterOptionIncludeHeading, [NSNumber numberWithBool:controller.includeDate], ExporterOptionIncludeDate, [NSNumber numberWithBool:controller.includePage], ExporterOptionIncludePage, [NSNumber numberWithBool:controller.includeWord], ExporterOptionIncludeWord, nil];
			
			NSEntityDescription *description = [NSEntityDescription entityForName:@"Entry" inManagedObjectContext:[self managedObjectContext]];
			NSMutableArray *includedProperties = [NSMutableArray arrayWithCapacity:3];
			if (controller.includeDate)
				[includedProperties addObject:@"enteredOn"];
			if (controller.includeWord)
				[includedProperties addObject:@"word.word"];
			if (controller.includePage)
				[includedProperties addObject:@"page"];
			
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			[fetchRequest setEntity:description];
			[fetchRequest setIncludesPropertyValues:YES];
			[fetchRequest setIncludesPendingChanges:YES];
			[fetchRequest setRelationshipKeyPathsForPrefetching:includedProperties];
			[fetchRequest setSortDescriptors:sortDescriptors];
			
			NSArray *entries = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
			if (!entries)
			{
				[self presentError:error];
				return;
			}
			
			htmlData = [KeywordExporter htmlCodeForConvertingEntries:entries options:exportOptions];
		}
		else // Directory
		{
			NSDictionary *exportOptions = [NSDictionary dictionaryWithObject:@"YES" forKey:ExporterOptionIncludeHeading];
			
			NSEntityDescription *description = [NSEntityDescription entityForName:@"Keyword" inManagedObjectContext:[self managedObjectContext]];
			
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			[fetchRequest setEntity:description];
			[fetchRequest setIncludesPropertyValues:YES];
			[fetchRequest setIncludesPendingChanges:YES];
			[fetchRequest setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"usedOn"]];
			[fetchRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"word" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
			
			NSArray *keywords = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
			if (!keywords)
			{
				[self presentError:error];
				return;
			}
			
			htmlData = [KeywordExporter htmlCodeForConvertingKeywords:keywords options:exportOptions];
		}
		
		if (!htmlData)
		{
			[self presentError:error];
			return;
		}
		if (controller.exportFormat == 1)
		{
			// HTML. Write it to disk directly.
			BOOL result = [htmlData writeToURL:[savePanel URL] atomically:YES];
			
			if (!result) [self presentError:error];
		}
		else
		{
			// Doc			
			NSAttributedString *attributedString = [[NSAttributedString alloc] initWithHTML:htmlData documentAttributes:NULL];
			
			NSData *docData = [attributedString docFormatFromRange:NSMakeRange(0, [attributedString length]) documentAttributes:nil];
			[docData writeToURL:[savePanel URL] atomically:YES];
		}
		[[savePanel URL] setResourceValue:[NSNumber numberWithBool:[savePanel isExtensionHidden]] forKey:NSURLHasHiddenExtensionKey error:NULL];
	}];
}

#pragma mark -
#pragma mark Copying and Pasting

- (void)writeEntries:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard
{
	NSLog(@"writing %@ to pasteboard", items);
	NSArray *pasteboardTypes = [NSArray arrayWithObjects:StichwoerterPboardType, NSPasteboardTypeTabularText, NSPasteboardTypeHTML, NSPasteboardTypeRTF, NSPasteboardTypeRTF, NSPasteboardTypeRTFD, NSPasteboardTypeString, nil];
	[pasteboard declareTypes:pasteboardTypes owner:self];
	
	// Generate property list
	NSMutableArray *propertyList = [NSMutableArray arrayWithCapacity:[items count]];
	for (NSManagedObject *entry in items)
	{
		// Slightly strange format, but allows direct reading by HTML conversion methods.
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[entry valueForKey:@"enteredOn"], @"enteredOn", [entry valueForKey:@"page"], @"page", [NSDictionary dictionaryWithObject:[entry valueForKeyPath:@"word.word"] forKey:@"word"], @"word", nil];
		[propertyList addObject:dict];
	}
	
	[pasteboard setPropertyList:propertyList forType:StichwoerterPboardType];
}

- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type;
{
	NSArray *actualData = [sender propertyListForType:StichwoerterPboardType];
	if (!actualData) return;
	
	if ([type isEqual:NSPasteboardTypeTabularText] || [type isEqual:NSPasteboardTypeString])
	{
		NSMutableString *result = [NSMutableString string];
		for (NSDictionary *word in actualData)
			[result appendFormat:@"%@\t%@\t%@\n", [word valueForKeyPath:@"enteredOn"], [word valueForKeyPath:@"word.word"], [word valueForKeyPath:@"page"]];
		
		[sender setString:result forType:type];
	}
	else if ([type isEqual:NSPasteboardTypeHTML] || [type isEqual:NSPasteboardTypeRTF] || [type isEqual:NSPasteboardTypeRTFD])
	{
		NSDictionary *exportOptions = [NSDictionary dictionaryWithObjectsAndKeys:@"NO", ExporterOptionIncludeHeading, @"YES", ExporterOptionIncludeDate, @"YES", ExporterOptionIncludeWord, @"YES", ExporterOptionIncludePage, nil];
		NSString *htmlSource = [KeywordExporter htmlCodeForConvertingEntries:actualData options:exportOptions];
		
		if ([type isEqual:NSPasteboardTypeHTML])
			[sender setString:htmlSource forType:NSPasteboardTypeHTML];
		else
		{
			NSData *utf8HTMLData = [htmlSource dataUsingEncoding:NSUTF8StringEncoding];
			NSAttributedString *attributedString = [[NSAttributedString alloc] initWithHTML:utf8HTMLData documentAttributes:NULL];
			
			if ([type isEqual:NSPasteboardTypeRTF])
			{
				NSData *pboardData = [attributedString RTFFromRange:NSMakeRange(0, [attributedString length]) documentAttributes:nil];
				[sender setData:pboardData forType:NSPasteboardTypeRTF];
			}
			else if ([type isEqual:NSPasteboardTypeRTFD])
			{
				NSData *pboardData = [attributedString RTFDFromRange:NSMakeRange(0, [attributedString length]) documentAttributes:nil];
				[sender setData:pboardData forType:NSPasteboardTypeRTF];
			}
		}
	}
}

- (void)readEntriesFromPasteboard:(NSPasteboard *)pasteboard
{
	NSArray *pasteboardTypes = [NSArray arrayWithObjects:StichwoerterPboardType, NSPasteboardTypeString, nil];
	NSString *preferredType = [pasteboard availableTypeFromArray:pasteboardTypes];
	if (!preferredType) return;
	
	if ([preferredType isEqual:StichwoerterPboardType])
	{
		NSArray *pboardData = [pasteboard propertyListForType:StichwoerterPboardType];
		for (NSDictionary *entry in pboardData)
		{
			[self insertEntryWithWord:[entry valueForKeyPath:@"word.word"] date:[entry valueForKeyPath:@"enteredOn"] page:[[entry valueForKeyPath:@"page"] integerValue]];
		}
	}
	else if ([preferredType isEqual:NSPasteboardTypeString])
	{
		[self insertEntryWithWord:[pasteboard stringForType:NSPasteboardTypeString] date:[NSDate date] page:self.currentEntryPage];
	}
}

- (void)copy:(id)sender;
{
#pragma unused(sender)
	NSArray *selectedEntries = [self _selectedEntries];
	[self writeEntries:selectedEntries toPasteboard:[NSPasteboard generalPasteboard]];
}

- (void)cut:(id)sender;
{
	NSArray *selectedEntries = [self _selectedEntries];
	[self writeEntries:selectedEntries toPasteboard:[NSPasteboard generalPasteboard]];
	[self delete:sender];
}

- (void)paste:(id)sender;
{
#pragma unused(sender)
	[self readEntriesFromPasteboard:[NSPasteboard generalPasteboard]];
}

- (void)delete:(id)sender;
{
#pragma unused(sender)
	NSLog(@"deleting something");
	NSArray *selectedEntries = [self _selectedEntries];
	
	for (NSManagedObject *object in selectedEntries)
		[[self managedObjectContext] deleteObject:object];
	
	NSFetchRequest *unusedWordsFetchRequest = [[NSFetchRequest alloc] init];
	[unusedWordsFetchRequest setEntity:[NSEntityDescription entityForName:@"Keyword" inManagedObjectContext:[self managedObjectContext]]];
	[unusedWordsFetchRequest setIncludesPendingChanges:YES];
	[unusedWordsFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"usedOn.@count == 0"]];
	
	NSError *error;
	NSArray *unusedWords = [[self managedObjectContext] executeFetchRequest:unusedWordsFetchRequest error:&error];
	if (!unusedWords)
	{
		[self presentError:error];
		return;
	}
	
	for (NSManagedObject *object in unusedWords)
		[[self managedObjectContext] deleteObject:object];
}

#pragma mark -
#pragma mark Internal utilities

- (NSArray *)_selectedEntries;
{
	if ([tabView indexOfTabViewItem:[tabView selectedTabViewItem]] == 0)
	{
		// Long list
		return [keywordListController selectedObjects];
	}
	else
	{
		// Directory list
		if ([[dictionaryEntryListController selectedObjects] count] != 0)
		{
			// Single entries selected
			return [dictionaryEntryListController selectedObjects];
		}
		else
		{
			// Whole pages selected
			return [dictionaryKeywordListController valueForKeyPath:@"selectedObjects.@distinctUnionOfSets.usedOn"];
		}
		return nil;
	}
}

@end
