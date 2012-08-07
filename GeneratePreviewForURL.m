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
    NSAutoreleasePool *pool  = [[NSAutoreleasePool alloc] init];
	NSError *error = nil;
	
	CFBundleRef myBundle = QLPreviewRequestGetGeneratorBundle(preview);
	CFURLRef bundleURL = CFBundleCopyBundleURL(myBundle);
	
	NSURL *modelURL = [NSURL URLWithString:@"../../../Resources/MyDocument.mom" relativeToURL:(NSURL *) bundleURL];
	
	CFRelease(bundleURL);
	
	NSManagedObjectContext *context = [KeywordExporter contextForURL:(NSURL *) url UTI:(NSString *) contentTypeUTI managedObjectModelLocation:modelURL error:&error];
	if (error != NULL)
	{
		[pool drain];
		return noErr; // Apparently you're only supposed to return that
	}
	
	NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"word" ascending:YES]];
	NSArray *keywords = [KeywordExporter keywordsFromContext:context sortDescriptors:sortDescriptors error:&error];
	if (error != NULL)
	{
		[pool drain];
		return noErr; // Apparently you're only supposed to return that
	}
	
	NSDictionary *htmlOptions = [NSDictionary dictionaryWithObjectsAndKeys:@"YES", ExporterOptionIncludeHeading, [NSString stringWithFormat:@"%@:styles.css", kQLPreviewContentIDScheme], ExporterOptionCSSFileName, nil];
	
	NSString *htmlString = [KeywordExporter htmlCodeForConvertingKeywords:keywords options:htmlOptions];
	NSData *htmlData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
	
	NSURL *cssFileURL = (NSURL *) CFBundleCopyResourceURL(myBundle, (CFStringRef) @"styles", (CFStringRef) @"css", NULL);
	NSData *cssFileData = [NSData dataWithContentsOfURL:cssFileURL];
	[cssFileURL release];
	NSLog(@"css file data: %@", cssFileData);
	NSDictionary *cssAttachement = [NSDictionary dictionaryWithObjectsAndKeys:@"text/css", kQLPreviewPropertyMIMETypeKey, [NSNumber numberWithUnsignedInteger:kCFStringEncodingUTF8], kQLPreviewPropertyStringEncodingKey, cssFileData, kQLPreviewPropertyAttachmentDataKey, nil];
	NSDictionary *previewProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:kCFStringEncodingUTF8], kQLPreviewPropertyStringEncodingKey, [NSDictionary dictionaryWithObject:cssAttachement forKey:@"styles.css"], kQLPreviewPropertyAttachmentsKey, nil];
	
	QLPreviewRequestSetDataRepresentation(preview, (CFDataRef) htmlData, (CFStringRef) @"public.html", (CFDictionaryRef) previewProperties);
	
	[pool drain];
	return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
