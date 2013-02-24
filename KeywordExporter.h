//
//  KeywordExporter.h
//  Stichwörter
//
//  Created by Torsten Kammer on 22.09.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Constants for use as options. Where it says BOOL, it means something that will
// respond to boolValue.

// Options for both
extern NSString *ExporterOptionIncludeHeading; // BOOL, defaults to YES
extern NSString *ExporterOptionCSSFileName; // NSString, defaults to None (no CSS reference included)
extern NSString *ExporterOptionFileTitle; // NSString, defaults to @""

// Options only for converting entries
extern NSString *ExporterOptionIncludeDate; // BOOL, Whether to include the date, defaults to NO
extern NSString *ExporterOptionIncludeWord; // BOOL, Whether to include the keyword, defaults to YES
extern NSString *ExporterOptionIncludePage; // BOOL, Whether to include the page, defaults to YES

// Options only for converting keywords
extern NSString *ExporterOptionPageNumberSeparator; // NSString, defaults to @", "

@interface KeywordExporter : NSObject
{

}

+ (NSManagedObjectContext *)contextForURL:(NSURL *)url UTI:(NSString *)uti managedObjectModelLocation:(NSURL *)modelLocation error:(NSError **)error;
+ (NSArray *)entriesFromContext:(NSManagedObjectContext *)context sortDescriptors:(NSArray *)sortDescriptors error:(NSError **)error;
+ (NSArray *)keywordsFromContext:(NSManagedObjectContext *)context sortDescriptors:(NSArray *)sortDescriptors error:(NSError **)error;

+ (NSData *)htmlDataForConvertingEntries:(NSArray *)entries options:(NSDictionary *)options;
+ (NSData *)htmlDataForConvertingKeywords:(NSArray *)keywords options:(NSDictionary *)options;
+ (NSData *)docxDataForConvertingEntries:(NSArray *)entries options:(NSDictionary *)options;
+ (NSData *)docxDataForConvertingKeywords:(NSArray *)keywords options:(NSDictionary *)options;

@end
