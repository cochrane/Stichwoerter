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
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Keyword"];
	fetchRequest.fetchLimit = 1;
	fetchRequest.includesPropertyValues = NO;
	fetchRequest.includesPendingChanges = YES;
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"word = %@", word];
	
	NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
	
	NSManagedObject *keyword = nil;
	if (result.count == 0)
	{
		keyword = [NSEntityDescription insertNewObjectForEntityForName:@"Keyword" inManagedObjectContext:self.managedObjectContext];
		[keyword setValue:word forKey:@"word"];
	}
	else
		keyword = [result objectAtIndex:0];
	
	// Enter entry
	NSManagedObject *entry = [NSEntityDescription insertNewObjectForEntityForName:@"Entry" inManagedObjectContext:self.managedObjectContext];
	[entry setValue:@(page) forKey:@"page"];
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
		
		NSFetchRequest *allHigherPagesRequest = [NSFetchRequest fetchRequestWithEntityName:@"Entry"];
		allHigherPagesRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"page" ascending:YES] ];
		allHigherPagesRequest.predicate = [NSPredicate predicateWithFormat:@"page >= %lu", oldStart];
		allHigherPagesRequest.includesPropertyValues = YES;
		allHigherPagesRequest.includesPendingChanges = YES;
		
		NSError *error = nil;
		NSArray *higherPages = [self.managedObjectContext executeFetchRequest:allHigherPagesRequest error:&error];
		if (!higherPages)
		{
			[self presentError:error];
			return;
		}
		
		NSInteger diff = newStart - oldStart;
		
		for (NSManagedObject *entry in higherPages)
		{
			NSUInteger oldPage = [[entry valueForKey:@"page"] unsignedIntegerValue];
			[entry setValue:@(oldPage + diff) forKey:@"page"];
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
		
		NSData *documentData = nil;
		NSError *error = nil;
		if (controller.exportMode == 1) // List
		{
			NSArray *sortDescriptors = @[ controller.includeDate ? [NSSortDescriptor sortDescriptorWithKey:@"enteredOn" ascending:NO] : [NSSortDescriptor sortDescriptorWithKey:@"page" ascending:YES] ];
			
			NSDictionary *exportOptions = @{
				ExporterOptionIncludeHeading : @(YES),
				ExporterOptionIncludeDate : @(controller.includeDate),
				ExporterOptionIncludePage : @(controller.includePage),
				ExporterOptionIncludeWord : @(controller.includeWord)
			};
			
			NSMutableArray *includedProperties = [NSMutableArray arrayWithCapacity:3];
			if (controller.includeDate)
				[includedProperties addObject:@"enteredOn"];
			if (controller.includeWord)
				[includedProperties addObject:@"word.word"];
			if (controller.includePage)
				[includedProperties addObject:@"page"];
			
			NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Entry"];
			fetchRequest.includesPropertyValues = YES;
			fetchRequest.includesPendingChanges = YES;
			fetchRequest.relationshipKeyPathsForPrefetching = includedProperties;
			fetchRequest.sortDescriptors = sortDescriptors;
			
			NSArray *entries = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
			if (!entries)
			{
				[self presentError:error];
				return;
			}
			
			if (controller.exportFormat == 1) // HTML
				documentData = [KeywordExporter htmlDataForConvertingEntries:entries options:exportOptions];
			else // Word
				documentData = [KeywordExporter docxDataForConvertingEntries:entries options:exportOptions];
		}
		else // Directory
		{
			NSDictionary *exportOptions = @{
								   ExporterOptionIncludeHeading : @(YES),
		   ExporterOptionEmptyRowBeforeLetter : @(controller.emptyRowBeforeLetter)
			};
						
			NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Keyword"];
			fetchRequest.includesPropertyValues = YES;
			fetchRequest.includesPendingChanges = YES;
			fetchRequest.relationshipKeyPathsForPrefetching = @[ @"usedOn" ];
			fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"word" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] ];
			
			NSArray *keywords = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
			if (!keywords)
			{
				[self presentError:error];
				return;
			}
			
			if (controller.exportFormat == 1) // HTML
				documentData = [KeywordExporter htmlDataForConvertingKeywords:keywords options:exportOptions];
			else // Word
				documentData = [KeywordExporter docxDataForConvertingKeywords:keywords options:exportOptions];
		}
		
		if (!documentData)
		{
			[self presentError:error];
			return;
		}
		
		if (![documentData writeToURL:savePanel.URL options:NSDataWritingAtomic error:&error])
			[self presentError:error];
		
		[savePanel.URL setResourceValue:@(savePanel.isExtensionHidden) forKey:NSURLHasHiddenExtensionKey error:NULL];
	}];
}

#pragma mark -
#pragma mark Copying and Pasting

- (void)writeEntries:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard
{
	NSLog(@"writing %@ to pasteboard", items);
	NSArray *pasteboardTypes = @[ StichwoerterPboardType, NSPasteboardTypeTabularText, NSPasteboardTypeHTML, NSPasteboardTypeRTF, NSPasteboardTypeRTFD, NSPasteboardTypeString ];
	[pasteboard declareTypes:pasteboardTypes owner:self];
	
	// Generate property list
	NSMutableArray *propertyList = [NSMutableArray arrayWithCapacity:items.count];
	for (NSManagedObject *entry in items)
	{
		// Slightly strange format, but allows direct reading by HTML conversion methods.
		[propertyList addObject:@{
		 @"enteredOn" : [entry valueForKey:@"enteredOn"],
		 @"page" : [entry valueForKey:@"page"],
		 @"word" : @{ @"word" : [entry valueForKeyPath:@"word.word"] }
		 }];
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
		NSDictionary *exportOptions = @{
			ExporterOptionIncludeHeading: @(NO),
			ExporterOptionIncludeDate: @(YES),
			ExporterOptionIncludeWord: @(YES),
			ExporterOptionIncludePage: @(YES)
		};
		NSData *htmlData = [KeywordExporter htmlDataForConvertingEntries:actualData options:exportOptions];
		
		if ([type isEqual:NSPasteboardTypeHTML])
		{
			NSString *htmlString = [[NSString alloc] initWithBytes:htmlData.bytes length:htmlData.length encoding:NSUTF8StringEncoding];
			[sender setString:htmlString forType:NSPasteboardTypeHTML];
		}
		else
		{
			NSAttributedString *attributedString = [[NSAttributedString alloc] initWithHTML:htmlData documentAttributes:NULL];
			
			if ([type isEqual:NSPasteboardTypeRTF])
			{
				NSData *pboardData = [attributedString RTFFromRange:NSMakeRange(0, attributedString.length) documentAttributes:nil];
				[sender setData:pboardData forType:NSPasteboardTypeRTF];
			}
			else if ([type isEqual:NSPasteboardTypeRTFD])
			{
				NSData *pboardData = [attributedString RTFDFromRange:NSMakeRange(0, attributedString.length) documentAttributes:nil];
				[sender setData:pboardData forType:NSPasteboardTypeRTF];
			}
		}
	}
}

- (void)readEntriesFromPasteboard:(NSPasteboard *)pasteboard
{
	NSArray *pasteboardTypes = @[ StichwoerterPboardType, NSPasteboardTypeString ];
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
		[self.managedObjectContext deleteObject:object];
	
	NSFetchRequest *unusedWordsFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Keyword"];
	unusedWordsFetchRequest.includesPendingChanges = YES;
	unusedWordsFetchRequest.predicate = [NSPredicate predicateWithFormat:@"usedOn.@count == 0"];
	
	NSError *error;
	NSArray *unusedWords = [self.managedObjectContext executeFetchRequest:unusedWordsFetchRequest error:&error];
	if (!unusedWords)
	{
		[self presentError:error];
		return;
	}
	
	for (NSManagedObject *object in unusedWords)
		[self.managedObjectContext deleteObject:object];
}

#pragma mark -
#pragma mark Internal utilities

- (NSArray *)_selectedEntries;
{
	if ([tabView indexOfTabViewItem:tabView.selectedTabViewItem] == 0)
	{
		// Long list
		return keywordListController.selectedObjects;
	}
	else
	{
		// Directory list
		if (dictionaryEntryListController.selectedObjects.count != 0)
		{
			// Single entries selected
			return dictionaryEntryListController.selectedObjects;
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
