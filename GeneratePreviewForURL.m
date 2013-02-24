#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import "KeywordExporter.h"

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
	@autoreleasepool {
		NSError *error = nil;
		
		CFBundleRef myBundle = QLPreviewRequestGetGeneratorBundle(preview);
		CFURLRef bundleURL = CFBundleCopyBundleURL(myBundle);
		
		NSURL *modelURL = [NSURL URLWithString:@"../../../Resources/MyDocument.mom" relativeToURL:(__bridge NSURL *) bundleURL];
		
		CFRelease(bundleURL);
		
		NSManagedObjectContext *context = [KeywordExporter contextForURL:(__bridge NSURL *) url UTI:(__bridge NSString *) contentTypeUTI managedObjectModelLocation:modelURL error:&error];
		if (error != NULL)
			return noErr; // Apparently you're only supposed to return that
		
		NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"word" ascending:YES] ];
		NSArray *keywords = [KeywordExporter keywordsFromContext:context sortDescriptors:sortDescriptors error:&error];
		if (error != NULL)
			return noErr; // Apparently you're only supposed to return that
		
		NSDictionary *htmlOptions = @{ ExporterOptionIncludeHeading : @(YES) };
		
		NSData *htmlData = [KeywordExporter htmlDataForConvertingKeywords:keywords options:htmlOptions];
		NSDictionary *previewProperties = @{ (__bridge NSString *) kQLPreviewPropertyStringEncodingKey : @(kCFStringEncodingUTF8) };
		
		QLPreviewRequestSetDataRepresentation(preview, (__bridge CFDataRef) htmlData, (CFStringRef) @"public.html", (__bridge CFDictionaryRef) previewProperties);
	}
	return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
