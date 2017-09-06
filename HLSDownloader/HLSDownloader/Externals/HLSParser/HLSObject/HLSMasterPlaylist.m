//
//  HLSMasterPlaylist.m
//  HLSDownloader
//
//  Created by Liu Junqi on 25/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import "HLSMasterPlaylist.h"
#import "HLSConstants.h"
#import "HLSStreamInfo.h"
#import "HLSMedia.h"

@implementation HLSMasterPlaylist

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initVars];
    }
    return self;
}

#pragma mark - Init
- (void)initVars {
    self.iframes = [NSMutableArray arrayWithCapacity:8];
    self.streams = [NSMutableArray arrayWithCapacity:8];
    self.media = [NSMutableArray arrayWithCapacity:8];
}

#pragma mark - Parse
- (void)parse:(NSString *)content withHLSURL:(NSString *)hlsURL; {
    self.hlsURL = hlsURL;
    self.content = content;
    NSArray<NSString *> *allLines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    [self parseHLSContent:allLines];
}

- (void)parseHLSContent:(NSArray<NSString *> *)content {
    NSInteger count = content.count;
    NSMutableArray *moreLines = [NSMutableArray arrayWithCapacity:8];
    for (NSInteger i = 0; i < count; ++i) {
        NSString *line = content[i];
        NSLog(@"** [%zd]line: %@", i+1, line);
        if (line.length == 0) continue;
        BOOL readMore = NO;
        do {
            readMore = [self shouldReadMoreLines:content[i]];
            if (!readMore || ++i >= count) break;
            [moreLines addObject:content[i]];
            NSLog(@"** [%zd]line: %@", i+1, content[i]);
        } while(readMore);
        line = [self combineLine:line withMoreLines:moreLines];
        [self parseLine:line moreLines:moreLines];
        [moreLines removeAllObjects];
    }
}

- (BOOL)shouldReadMoreLines:(NSString *)line {
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmedLine = [line stringByTrimmingCharactersInSet:set];
    NSInteger lastCharIndex = trimmedLine.length - 1;
    NSString *lastCharString = [trimmedLine substringFromIndex:lastCharIndex];
    
    if ([lastCharString isEqualToString:@"\\"] ||
        [lastCharString isEqualToString:@","]) return YES;
    
    if ([line rangeOfString:HLSTagStreamINF].location == 0) return YES;
    
    return NO;
}

- (void)parseLine:(NSString *)line moreLines:(NSArray<NSString *> *)moreLines {
    if ([line isEqualToString:HLSTagHeader]) {
        return;
    } else if ([line hasPrefix:HLSTagStreamINF]) {
        HLSStreamInfo *stream = [self parseStreamInf:line moreLines:moreLines];
        [self.streams addObject:stream];
    } else if ([line hasPrefix:HLSTagIFrameStreamINF]) {
        HLSStreamInfo *stream = [self parseIFrameStreamInf:line];
        [self.iframes addObject:stream];
    } else if ([line hasPrefix:HLSTagMedia]) {
        HLSMedia *media = [self parseMedia:line];
        [self.media addObject:media];
    }
}

- (HLSMedia *)parseMedia:(NSString *)line {
    NSDictionary *attributes = [self parseAttributes:line];
    HLSMedia *media = [[HLSMedia alloc] initWithAttributes:attributes];
    return media;
}

- (HLSStreamInfo *)parseIFrameStreamInf:(NSString *)line {
    NSDictionary *attributes = [self parseAttributes:line];
    HLSStreamInfo *stream = [[HLSStreamInfo alloc] initWithAttributes:attributes];
    stream.isIFrame = YES;
    return stream;
}

- (HLSStreamInfo *)parseStreamInf:(NSString *)line moreLines:(NSArray<NSString *> *)moreLines {
    NSDictionary *attributes = [self parseAttributes:line];
    HLSStreamInfo *stream = [[HLSStreamInfo alloc] initWithAttributes:attributes];
    stream.isIFrame = NO;
    stream.uri = moreLines.count == 0 ? nil : [moreLines firstObject];
    return stream;
}

- (NSString *)combineLine:(NSString *)line withMoreLines:(NSMutableArray *)moreLines {
    if (moreLines.count == 0) return line;
    
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSMutableString *oneLine = [NSMutableString stringWithCapacity:256];
    NSString *str = line;
    BOOL shouldHandleMore = YES;
    do {
        NSString *trimmedString = [str stringByTrimmingCharactersInSet:set];
        NSInteger lastCharIndex = trimmedString.length - 1;
        NSString *lastCharString = [trimmedString substringFromIndex:lastCharIndex];
        if ([lastCharString isEqualToString:@"\\"]) { str = [trimmedString substringToIndex:lastCharIndex]; }
        else { shouldHandleMore = NO; }
        [oneLine appendString:str];
        if (!shouldHandleMore || moreLines.count == 0) break;
        str = [moreLines firstObject];
        [moreLines removeObjectAtIndex:0];
    } while (shouldHandleMore);
    return oneLine;
}

- (NSDictionary *)parseAttributes:(NSString *)line {
    NSUInteger colonIndex = [line rangeOfString:@":"].location;
    if (colonIndex == NSNotFound) return nil;
    if (colonIndex + 1 >= line.length) return nil;
    NSString *str = [line substringFromIndex:colonIndex+1];
    
    // Attributes
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];
    NSInteger index = 0;
    const NSInteger length = str.length;
    NSInteger len = length;
    do {
        // Find key
        NSRange r = [str rangeOfString:@"=" options:0 range:NSMakeRange(index, len)];
        if (r.location == NSNotFound) break;
        NSString *key = [str substringWithRange:NSMakeRange(index, r.location-index)];
        key = [key stringByTrimmingCharactersInSet:set];
        index = r.location + r.length;
        len = length - index;
        if (len <= 0) break;
        
        // Find value in key=value or key="value"
        // Determine double quote
        NSString *value = nil;
        NSString *quote = [str substringWithRange:NSMakeRange(index, 1)];
        if ([quote isEqualToString:@"\""]) { // quoted-string value
            // Find the next quote
            r = [str rangeOfString:@"\"" options:0 range:NSMakeRange(index+1, len-1)];
            if (r.location == NSNotFound) break;
            value = [str substringWithRange:NSMakeRange(index+1, r.location-index-1)];
            dict[key] = value;
            index = r.location + r.length;
            len = length - index;
            r = [str rangeOfString:@"," options:0 range:NSMakeRange(index, len)];
            if (r.location == NSNotFound) break; // No more attributes
        } else {
            r = [str rangeOfString:@"," options:0 range:NSMakeRange(index, len)];
            if (r.location == NSNotFound) value = [str substringFromIndex:index]; // The last attribute
            else value = [str substringWithRange:NSMakeRange(index, r.location-index)];
            value = [value stringByTrimmingCharactersInSet:set];
            dict[key] = value;
            if (r.location == NSNotFound) break; // No more attributes
        }
        index = r.location + r.length;
        len = length - index;
    } while (index < length);
    
    return dict;
}

@end
