//
//  HLSUtils.h
//  HLSDownloader
//
//  Created by Liu Junqi on 03/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HLSMediaPlaylist;

@interface HLSUtils : NSObject

+ (BOOL)determineHLSM3UFromData:(NSData *)data;
+ (BOOL)determineHLSM3UFromFile:(NSString *)file;
+ (BOOL)determineTheNewMediaSegment:(HLSMediaPlaylist *)theNewMediaPlaylist old:(HLSMediaPlaylist *)theOldMediaPlaylist;

+ (NSString *)computerSizeString:(CGFloat)size;
+ (NSString *)computerSizeString:(CGFloat)size specifiedUnit:(NSString **)specifiedUnit;
+ (NSString *)computerSizeString:(CGFloat)size
                   specifiedUnit:(NSString **)specifiedUnit
 allowUnitLowerThanSpecifiedUnit:(BOOL)allow;

+ (BOOL)createFolders:(NSString *)folderPath;
+ (NSString *)moveDownloadedFile:(NSString *)file toFolder:(NSString *)folder renameTo:(NSString *)filename;
+ (BOOL)deleteFile:(NSString *)file;
+ (BOOL)appendFile:(NSString *)inputFile toFile:(NSString *)outputFile;

@end
