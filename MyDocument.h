//
//  MyDocument.h
//  Stichwörter
//
//  Created by Torsten Kammer on 20.09.09.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MyDocument : NSPersistentDocument
{
	NSInteger currentEntryPage;
	NSString *currentEntryWord;
	
	IBOutlet NSArrayController *keywordListController;
	IBOutlet NSArrayController *dictionaryKeywordListController;
	IBOutlet NSArrayController *dictionaryEntryListController;
	IBOutlet NSTabView *tabView;
}

@property (assign) NSInteger currentEntryPage;
@property (copy) NSString *currentEntryWord;

- (IBAction)export:(id)sender;
- (IBAction)rebase:(id)sender;

- (IBAction)goToNextPage:(id)sender;
- (IBAction)saveEntry:(id)sender;

- (void)insertEntryWithWord:(NSString *)word date:(NSDate *)date page:(NSInteger)page;

@end
