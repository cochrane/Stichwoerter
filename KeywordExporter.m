//
//  KeywordExporter.m
//  Stichwörter
//
//  Created by Torsten Kammer on 22.09.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "KeywordExporter.h"

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

@interface KeywordExporter()

+ (NSMutableString *)_createBeginningWithOptions:(NSDictionary *)options;
+ (NSArray *)_entitiesNamed:(NSString *)name fromContext:(NSManagedObjectContext *)context sortDescriptors:(NSArray *)descriptors error:(NSError **)error;

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
		[model release];
		if (error) *error = [NSError errorWithDomain:@"de.ferroequinologist.stw.errordomain" code:-3 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:storeURL, NSURLErrorKey, [NSString stringWithFormat:NSLocalizedString(@"Type %@ can not be processed", @"wrong UTI type"), contentTypeUTI], NSLocalizedDescriptionKey, nil]];
		return nil;
	}
	
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	[model release];
	
	if (![coordinator addPersistentStoreWithType:storeType configuration:nil URL:storeURL options:readOnlyOptions error:error])
	{
		[coordinator release];
		return nil;
	}
    
	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
	[context setPersistentStoreCoordinator:coordinator];
	[coordinator release];
	
	return [context autorelease];
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
	[fetchRequest release];
	
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

+ (NSMutableString *)_createBeginningWithOptions:(NSDictionary *)options;
{
	NSMutableString *resultString = [NSMutableString stringWithString:@"<!DOCTYPE html>\n<html><head>"];
	if ([options objectForKey:ExporterOptionFileTitle])
		[resultString appendFormat:@"<title>%@</title>", [options objectForKey:ExporterOptionFileTitle]];
	else
		[resultString appendString:@"<title></title>"];
	
	[resultString appendString:@"<meta http-equiv=\"content-type\" content=\"text/html; charset=UTF-8\">"];
	if ([options objectForKey:ExporterOptionCSSFileName])
		[resultString appendFormat:@"<link rel=\"stylesheet\" type=\"text/css\" href=\"%@\">", [options objectForKey:ExporterOptionCSSFileName]];
	
	[resultString appendString:@"</head><body><table>"];
	
	return resultString;
}

+ (NSString *)htmlCodeForConvertingEntries:(NSArray *)entries options:(NSDictionary *)options;
{
	NSMutableString *resultString = [self _createBeginningWithOptions:options];
	
	BOOL includeDate = [[options objectForKey:ExporterOptionIncludeDate] boolValue];
	BOOL includeWord = !options || ![options objectForKey:ExporterOptionIncludeWord] || [[options objectForKey:ExporterOptionIncludeWord] boolValue];
	BOOL includePage = !options || ![options objectForKey:ExporterOptionIncludePage] || [[options objectForKey:ExporterOptionIncludePage] boolValue];
	
	if (!options || ![options objectForKey:ExporterOptionIncludeHeading] || [[options objectForKey:ExporterOptionIncludeHeading] boolValue])
	{
		[resultString appendString:@"<tr>"];
		if (includeDate) [resultString appendFormat:@"<th>%@</th>", NSLocalizedString(@"Entered on", @"Export date header")];
		if (includeWord) [resultString appendFormat:@"<th>%@</th>", NSLocalizedString(@"Keyword", @"Export keyword header")];
		if (includePage) [resultString appendFormat:@"<th>%@</th>", NSLocalizedString(@"On Page", @"Export page header")];
		[resultString appendString:@"</tr>"];
	}
	
	for (id entry in entries)
	{
		[resultString appendString:@"<tr>"];
		if (includeDate) [resultString appendFormat:@"<td>%@</td>", [entry valueForKey:@"enteredOn"]];
		if (includeWord) [resultString appendFormat:@"<td>%@</td>", [entry valueForKey:@"word.word"]];
		if (includePage) [resultString appendFormat:@"<td>%@</td>", [entry valueForKey:@"page"]];
		[resultString appendString:@"</tr>"];
	}
	
	[resultString appendString:@"</table></body></html>"];
	
	return [[resultString copy] autorelease];
}

+ (NSString *)htmlCodeForConvertingKeywords:(NSArray *)keywords options:(NSDictionary *)options;
{
	NSMutableString *resultString = [self _createBeginningWithOptions:options];
	
	if (!options || ![options objectForKey:ExporterOptionIncludeHeading] || [[options objectForKey:ExporterOptionIncludeHeading] boolValue])
	{
		[resultString appendString:@"<tr>"];
		[resultString appendFormat:@"<th>%@</th>", NSLocalizedString(@"Keyword", @"Export keyword header")];
		[resultString appendFormat:@"<th>%@</th>", NSLocalizedString(@"On Pages", @"Export page list header")];
		[resultString appendString:@"</tr>"];
	}
	
	NSString *separator = [options objectForKey:ExporterOptionPageNumberSeparator];
	if (!separator) separator = @", ";
	
	for (id keyword in keywords)
	{
		[resultString appendFormat:@"<tr><td>%@</td>", [keyword valueForKey:@"word"]];
		
		NSArray *sortedPages = [[keyword valueForKeyPath:@"usedOn.page"] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
		[resultString appendFormat:@"<td>%@</td>", [sortedPages componentsJoinedByString:separator]];
		
		[resultString appendString:@"</tr>"];
	}
	
	[resultString appendString:@"</table></body></html>"];
	
	return [[resultString copy] autorelease];
}

@end
