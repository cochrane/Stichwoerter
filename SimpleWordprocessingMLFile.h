//
//  SimpleWordprocessingMLFile.h
//  Stichwörter
//
//  Created by Torsten Kammer on 24.02.13.
//
//

#import <Foundation/Foundation.h>

/*!
 * @abstract The most basic support for Office Open XML for text files.
 * @discussion This file is meant to write simple office open xml files. It does not support reading!
 */

@interface SimpleWordprocessingMLFile : NSObject

@property (nonatomic, retain) NSXMLDocument *document;
@property (nonatomic, readonly) NSData *docxRepresentation;

@end
