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
		
		NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"word" ascending:YES]];
		NSArray *keywords = [KeywordExporter keywordsFromContext:context sortDescriptors:sortDescriptors error:&error];
		if (error != NULL)
			return noErr; // Apparently you're only supposed to return that
		
		NSDictionary *htmlOptions = [NSDictionary dictionaryWithObjectsAndKeys:@"YES", ExporterOptionIncludeHeading, [NSString stringWithFormat:@"%@:styles.css", kQLPreviewContentIDScheme], ExporterOptionCSSFileName, nil];
		
		NSData *htmlData = [KeywordExporter htmlDataForConvertingKeywords:keywords options:htmlOptions];
		
		NSURL *cssFileURL = (__bridge_transfer NSURL *) CFBundleCopyResourceURL(myBundle, (__bridge CFStringRef) @"styles", (__bridge CFStringRef) @"css", NULL);
		NSData *cssFileData = [NSData dataWithContentsOfURL:cssFileURL];
		NSLog(@"css file data: %@", cssFileData);
		NSDictionary *cssAttachement = [NSDictionary dictionaryWithObjectsAndKeys:@"text/css", kQLPreviewPropertyMIMETypeKey, [NSNumber numberWithUnsignedInteger:kCFStringEncodingUTF8], kQLPreviewPropertyStringEncodingKey, cssFileData, kQLPreviewPropertyAttachmentDataKey, nil];
		NSDictionary *previewProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:kCFStringEncodingUTF8], kQLPreviewPropertyStringEncodingKey, [NSDictionary dictionaryWithObject:cssAttachement forKey:@"styles.css"], kQLPreviewPropertyAttachmentsKey, nil];
		
		QLPreviewRequestSetDataRepresentation(preview, (__bridge CFDataRef) htmlData, (CFStringRef) @"public.html", (__bridge CFDictionaryRef) previewProperties);
	}
	return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
