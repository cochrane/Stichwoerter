//
//  TableDocument.h
//  Stichwörter
//
//  Created by Torsten Kammer on 24.02.13.
//
//

#import <Foundation/Foundation.h>

@interface TableDocument : NSObject

@property (nonatomic, copy) NSArray *headers;
- (void)addLine:(NSArray *)contents;

- (NSData *)htmlRepresentation;
- (NSData *)docxRepresentation;

@end
