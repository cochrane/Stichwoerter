//
//  ZIPArchive.h
//  Stichwörter
//
//  Created by Torsten Kammer on 24.02.13.
//
//

#import <Foundation/Foundation.h>

@interface ZIPArchive : NSObject

- (void)addFileNamed:(NSString *)localName data:(NSData *)data;

- (NSData *)generateData;

@end
