//
//  HLSUtils.m
//  HLSDownloader
//
//  Created by Liu Junqi on 03/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import "HLSUtils.h"
#import "HLSObject.h"
#import "HLSMediaPlaylist.h"
#import "HLSMediaSegment.h"
#import "HLSConstants.h"

@implementation HLSUtils

+ (BOOL)determineHLSM3UFromData:(NSData *)data {
    NSInteger headerLength = HLSTagHeader.length;
    if (data.length > headerLength) data = [data subdataWithRange:NSMakeRange(0, headerLength)];
    NSString *header = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (header == nil) return NO;
    if ([header isEqualToString:HLSTagHeader]) return YES;
    return NO;
}

+ (BOOL)determineHLSM3UFromFile:(NSString *)file {
    if (file.length == 0) return NO;
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDirectory = YES;
    if (![fm fileExistsAtPath:file isDirectory:&isDirectory]) return NO;
    if (isDirectory) return NO;
    
    NSFileHandle *h = [NSFileHandle fileHandleForReadingAtPath:file];
    NSData *data = [h readDataOfLength:HLSTagHeader.length];
    return [HLSUtils determineHLSM3UFromData:data];
}

+ (BOOL)determineTheNewMediaSegment:(HLSMediaPlaylist *)theNewMediaPlaylist old:(HLSMediaPlaylist *)theOldMediaPlaylist {
    for (HLSMediaSegment *theOldSegment in theOldMediaPlaylist.segments) {
        for (HLSMediaSegment *theNewSegment in theNewMediaPlaylist.segments) {
            if ([theOldSegment.url isEqualToString:theNewSegment.url]) {
                theNewSegment.downloadable = NO;
            }
        }
    }
    BOOL hasNewSegment = NO;
    for (HLSMediaSegment *theNewSegment in theNewMediaPlaylist.segments) {
        if (theNewSegment.downloadable) {
            hasNewSegment = YES;
            break;
        }
    }
    return hasNewSegment;
}

+ (NSString *)computerSizeString:(CGFloat)size {
    return [HLSUtils computerSizeString:size specifiedUnit:nil];
}

+ (NSString *)computerSizeString:(CGFloat)size specifiedUnit:(NSString **)specifiedUnit {
    return [HLSUtils computerSizeString:size specifiedUnit:specifiedUnit allowUnitLowerThanSpecifiedUnit:YES];
}

+ (NSString *)computerSizeString:(CGFloat)size
                   specifiedUnit:(NSString **)specifiedUnit
 allowUnitLowerThanSpecifiedUnit:(BOOL)allow {
    NSArray *units = @[@"B", @"KB", @"MB",
                       @"GB", @"TB", @"PB",
                       @"EB", @"ZB", @"YB",
                       @"XB", @"SB", @"DB"];
    NSString *unit = [units firstObject];
    CGFloat sizeInUnit = size;
    BOOL specifiedUnitIsNil = specifiedUnit == nil || *specifiedUnit == nil;
    if (specifiedUnitIsNil || ![*specifiedUnit isEqualToString:unit]) {
        for (NSInteger i = 1; i < units.count; ++i) {
            if ((allow || specifiedUnitIsNil) && sizeInUnit <= 1024) break;
            sizeInUnit /= 1024.0f;
            unit = units[i];
            if (!specifiedUnitIsNil && [*specifiedUnit isEqualToString:unit]) break;
        }
    }
    if (specifiedUnit != nil && *specifiedUnit == nil) *specifiedUnit = unit;
    NSString *speedString = [NSString stringWithFormat:@"%0.2f%@", sizeInUnit, unit];
    return speedString;
}

+ (BOOL)createFolders:(NSString *)folderPath {
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    if ([fm fileExistsAtPath:folderPath isDirectory:&isDirectory]) {
        if (isDirectory) return YES;
        if (![fm removeItemAtPath:folderPath error:&error]) {
            NSLog(@"*** removeItemAtPath: %@ error: %@", folderPath, error);
            return NO;
        }
    }
    
    BOOL created = [fm createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (!created) NSLog(@"*** createDirectoryAtPath: %@ error: %@", folderPath, error);
    
    return created;
}

+ (NSString *)moveDownloadedFile:(NSString *)file toFolder:(NSString *)folder renameTo:(NSString *)filename {
    return [HLSUtils moveDownloadedFile:file toFolder:folder renameTo:filename overwrite:YES];
}

+ (NSString *)moveDownloadedFile:(NSString *)file toFolder:(NSString *)folder renameTo:(NSString *)filename overwrite:(BOOL)overwrite {
    if (folder.length == 0) return nil;
    [self createFolders:folder];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if (filename == nil) filename = [file lastPathComponent];
    NSString *theNewFile = [folder stringByAppendingPathComponent:filename];
    NSError *error = nil;
    
    if (overwrite && [fm fileExistsAtPath:theNewFile]) {
        if (![fm removeItemAtPath:theNewFile error:&error]) {
            NSLog(@"Failed to removeItemAtPath: %@ error: %@", file, error);
            return nil;
        }
    }
    
    if (![fm moveItemAtPath:file toPath:theNewFile error:&error]) {
        NSLog(@"Failed to move file to %@, error: %@", theNewFile, error);
        return nil;
    }
    
    return theNewFile;
}

+ (BOOL)deleteFile:(NSString *)file {
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL deleted = [fm removeItemAtPath:file error:&error];
    if (!deleted) {
        NSLog(@"Failed to removeItemAtPath: %@ error: %@", file, error);
    }
    return deleted;
}

+ (BOOL)appendFile:(NSString *)inputFile toFile:(NSString *)outputFile {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    BOOL exists = [fm fileExistsAtPath:inputFile isDirectory:&isDirectory];
    if (!exists || isDirectory) return NO;
    exists = [fm fileExistsAtPath:outputFile isDirectory:&isDirectory];
    if (isDirectory) return NO;
    if (!exists) {
        if (![fm createFileAtPath:outputFile contents:nil attributes:nil]) {
            NSLog(@"*** createFileAtPath: %@", outputFile);
            return NO;
        }
    }
    
    NSFileHandle *input = [NSFileHandle fileHandleForReadingAtPath:inputFile];
    NSFileHandle *output = [NSFileHandle fileHandleForWritingAtPath:outputFile];
    [output seekToEndOfFile];
    NSInteger dataLength = 8 * 1024 * 1024;
    NSData *data = [input readDataOfLength:dataLength];
    while (data != nil && data.length > 0) {
        [output writeData:data];
        data = [input readDataOfLength:dataLength];
    }
    return YES;
}

@end
