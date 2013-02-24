//
//  KeywordExporter.m
//  Stichwörter
//
//  Created by Torsten Kammer on 22.09.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "KeywordExporter.h"

#import "TableDocument.h"

// Options for both
NSString *ExporterOptionIncludeHeading = @"Include heading key";
NSString *ExporterOptionCSSFileName = @"CSS file name key";
NSString *ExporterOptionFileTitle = @"HTML document title key";

// Options only for converting entries
NSString *ExporterOptionIncludeDate = @"Date inclusion key";
NSString *ExporterOptionIncludeWord = @"Word inclusion key";
NSString *ExporterOptionIncludePage = @"Page inclusion key";

// Options only for converting keywords
NSString *ExporterOptionPageNumberSeparator = @"Number separator key";
NSString *ExporterOptionEmptyRowBeforeLetter = @"Empty Row before new letter";

@interface KeywordExporter()

+ (NSArray *)_entitiesNamed:(NSString *)name fromContext:(NSManagedObjectContext *)context sortDescriptors:(NSArray *)descriptors error:(NSError **)error;

+ (TableDocument *)_documentForEntries:(NSArray *)entries options:(NSDictionary *)options;
+ (TableDocument *)_documentForKeywords:(NSArray *)entries options:(NSDictionary *)options;

@end

@implementation KeywordExporter

#pragma mark -
#pragma mark Getting data

+ (NSManagedObjectContext *)contextForURL:(NSURL *)storeURL UTI:(NSString *)contentTypeUTI managedObjectModelLocation:(NSURL *)modelURL error:(NSError **)error;
{
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	if (!model)
	{
		if (error) *error = [NSError errorWithDomain:@"de.ferroequinologist.stw.errordomain" code:-2 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:storeURL, NSURLErrorKey, NSLocalizedString(@"Could not load Core Data model file", @"model not found"), NSLocalizedDescriptionKey, nil]];
		return nil;
	}
	
	NSDictionary *readOnlyOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSReadOnlyPersistentStoreOption];
	
	NSString *storeType = nil;
	if ([contentTypeUTI isEqual:@"de.ferroequinologist.stw.bin"])
		storeType = NSBinaryStoreType;
	else if ([contentTypeUTI isEqual:@"de.ferroequinologist.stw.sql"])
		storeType = NSSQLiteStoreType;
	else if ([contentTypeUTI isEqual:@"de.ferroequinologist.stw.xml"])
		storeType = NSXMLStoreType;
	else
	{
		if (error) *error = [NSError errorWithDomain:@"de.ferroequinologist.stw.errordomain" code:-3 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:storeURL, NSURLErrorKey, [NSString stringWithFormat:NSLocalizedString(@"Type %@ can not be processed", @"wrong UTI type"), contentTypeUTI], NSLocalizedDescriptionKey, nil]];
		return nil;
	}
	
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	
	if (![coordinator addPersistentStoreWithType:storeType configuration:nil URL:storeURL options:readOnlyOptions error:error])
		return nil;
    
	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
	[context setPersistentStoreCoordinator:coordinator];
	
	return context;
}

+ (NSArray *)_entitiesNamed:(NSString *)name fromContext:(NSManagedObjectContext *)context sortDescriptors:(NSArray *)descriptors error:(NSError **)error;
{
	NSEntityDescription *description = [NSEntityDescription entityForName:name inManagedObjectContext:context];
	if (!description)
	{
		if (error)
			*error = [NSError errorWithDomain:@"de.ferroequinologist.stw.errordomain" code:-4 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:NSLocalizedString(@"Entity type %@ does not exist", @"wrong entity name"), name], nil]];
		return nil;
	}
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:description];
	[fetchRequest setReturnsObjectsAsFaults:NO];
	[fetchRequest setSortDescriptors:descriptors];
	
	NSArray *result = [context executeFetchRequest:fetchRequest error:error];
	
	return result;
}

+ (NSArray *)entriesFromContext:(NSManagedObjectContext *)context sortDescriptors:(NSArray *)sortDescriptors error:(NSError **)error;
{
	return [self _entitiesNamed:@"Entry" fromContext:context sortDescriptors:sortDescriptors error:error];
}
+ (NSArray *)keywordsFromContext:(NSManagedObjectContext *)context sortDescriptors:(NSArray *)sortDescriptors error:(NSError **)error;
{
	return [self _entitiesNamed:@"Keyword" fromContext:context sortDescriptors:sortDescriptors error:error];
}

#pragma mark -
#pragma mark Exporting

+ (NSData *)htmlDataForConvertingEntries:(NSArray *)entries options:(NSDictionary *)options;
{
	return [[self _documentForEntries:entries options:options] htmlRepresentation];
}

+ (NSData *)htmlDataForConvertingKeywords:(NSArray *)keywords options:(NSDictionary *)options;
{
	return [[self _documentForKeywords:keywords options:options] htmlRepresentation];
}

+ (NSData *)docxDataForConvertingEntries:(NSArray *)entries options:(NSDictionary *)options;
{
	return [[self _documentForEntries:entries options:options] docxRepresentation];
}

+ (NSData *)docxDataForConvertingKeywords:(NSArray *)keywords options:(NSDictionary *)options;
{
	return [[self _documentForKeywords:keywords options:options] docxRepresentation];
}

+ (TableDocument *)_documentForEntries:(NSArray *)entries options:(NSDictionary *)options;
{
	TableDocument *document = [[TableDocument alloc] init];
	
	BOOL includeDate = [[options objectForKey:ExporterOptionIncludeDate] boolValue];
	BOOL includeWord = !options || ![options objectForKey:ExporterOptionIncludeWord] || [[options objectForKey:ExporterOptionIncludeWord] boolValue];
	BOOL includePage = !options || ![options objectForKey:ExporterOptionIncludePage] || [[options objectForKey:ExporterOptionIncludePage] boolValue];
	
	if (!options || ![options objectForKey:ExporterOptionIncludeHeading] || [[options objectForKey:ExporterOptionIncludeHeading] boolValue])
	{
		NSMutableArray *headers = [NSMutableArray array];
		if (includeDate) [headers addObject:NSLocalizedString(@"Entered on", @"Export date header")];
		if (includeWord) [headers addObject: NSLocalizedString(@"Keyword", @"Export keyword header")];
		if (includePage) [headers addObject:NSLocalizedString(@"On Page", @"Export page header")];
		document.headers = headers;
	}
	
	for (id entry in entries)
	{
		NSMutableArray *row = [NSMutableArray array];
		if (includeDate) [row addObject:[entry valueForKeyPath:@"enteredOn"]];
		if (includeWord) [row addObject:[entry valueForKeyPath:@"word.word"]];
		if (includePage) [row addObject:[entry valueForKeyPath:@"page"]];
		[document addLine:row];
	}

return document;
}

+ (TableDocument *)_documentForKeywords:(NSArray *)keywords options:(NSDictionary *)options;
{
	TableDocument *document = [[TableDocument alloc] init];
	
	if (!options || ![options objectForKey:ExporterOptionIncludeHeading] || [[options objectForKey:ExporterOptionIncludeHeading] boolValue])
	{
		document.headers = @[ NSLocalizedString(@"Keyword", @"Export keyword header"), NSLocalizedString(@"On Pages", @"Export page list header") ];
	}
	
	NSString *separator = [options objectForKey:ExporterOptionPageNumberSeparator];
	if (!separator) separator = @", ";
	
	NSString *lastWord = nil;
	BOOL emptyRowBeforeNewLetter = !options || ![options objectForKey:ExporterOptionEmptyRowBeforeLetter] || [[options objectForKey:ExporterOptionEmptyRowBeforeLetter] boolValue];
	
	for (id keyword in keywords)
	{
		NSString *word = [keyword valueForKeyPath:@"word"];
		
		if (emptyRowBeforeNewLetter && word.length > 0)
		{
			if (!lastWord) lastWord = word;
			else
			{
				if ([lastWord compare:[word substringToIndex:1] options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch range:NSMakeRange(0, 1) locale:[NSLocale currentLocale]] != NSOrderedSame)
				{
					[document addLine:@[ @"", @"" ]];
					lastWord = word;
				}
			}
		}
		
		
		NSArray *sortedPages = [[keyword valueForKeyPath:@"usedOn.page"] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
		
		[document addLine:@[ word, [sortedPages componentsJoinedByString:separator]] ];
	}
	
	return document;
}

@end
