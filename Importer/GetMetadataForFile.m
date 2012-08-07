//
//  GetMetadataForFile.c
//  Stichwörter Spotlight Importer
//
//  Created by Torsten Kammer on 20.09.09.
//  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#import <CoreData/CoreData.h>
#import "KeywordExporter.h"

//==============================================================================
//
//	Get metadata attributes from document files
//
//	The purpose of this function is to extract useful information from the
//	file formats for your document, and set the values into the attribute
//  dictionary for Spotlight to include.
//
//==============================================================================


Boolean GetMetadataForFile(void* thisInterface, 
			   CFMutableDictionaryRef attributes, 
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)
{
#pragma unused (thisInterface, contentTypeUTI)
    /* Pull any available metadata from the file at the specified path */
    /* Return the attribute keys and attribute values in the dict */
    /* Return TRUE if successful, FALSE if there was no data provided */

    NSAutoreleasePool *pool  = [[NSAutoreleasePool alloc] init];
    NSError *error = nil;
	
	CFBundleRef myBundle = CFBundleGetBundleWithIdentifier((CFStringRef) @"de.ferroequinologist.Stichw-rter.spotlightimporter");
	CFURLRef bundleURL = CFBundleCopyBundleURL(myBundle);
	
	NSURL *modelURL = [NSURL URLWithString:@"../../../Resources/MyDocument.mom" relativeToURL:(NSURL *) bundleURL];
	
	CFRelease(bundleURL);
	
	NSURL *fileURL = [NSURL fileURLWithPath:(NSString *)pathToFile];
	
	NSManagedObjectContext *context = [KeywordExporter contextForURL:fileURL UTI:(NSString *) contentTypeUTI managedObjectModelLocation:modelURL error:&error];
	if (error != NULL)
	{
		[pool drain];
		return FALSE;
	}
	
	NSArray *entries = [KeywordExporter keywordsFromContext:context sortDescriptors:nil error:&error];
	if (error != NULL)
	{
		[pool drain];
		return FALSE;
	}
	
	NSString *textContent = [[entries valueForKey:@"word"] componentsJoinedByString:@"\n"];
	[(NSMutableDictionary *) attributes setObject:textContent forKey:(NSString *) kMDItemTextContent];
	
	// Return the status
    [pool drain];
    return TRUE;
}
