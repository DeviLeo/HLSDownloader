//
//  HLSMediaPlaylist.m
//  HLSDownloader
//
//  Created by DeviLeo on 2017/8/26.
//  Copyright © 2017年 DeviLeo. All rights reserved.
//

#import "HLSMediaPlaylist.h"
#import "HLSConstants.h"
#import "HLSMediaSegment.h"

@implementation HLSMediaPlaylist

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initVars];
    }
    return self;
}

#pragma mark - Init
- (void)initVars {
    self.segments = [NSMutableArray arrayWithCapacity:8];
}

- (void)setMediaSequence:(NSInteger)mediaSequence {
    _mediaSequence = mediaSequence;
    self.currentMediaSequence = mediaSequence;
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
    } else if ([line hasPrefix:HLSTagVersion]) {
        self.version = [self parseDecimalInteger:line];
    } else if ([line isEqualToString:HLSTagDiscontinuity]) {
        self.discontinuity = YES;
    } else if ([line hasPrefix:HLSTagTargetDuration]) {
        self.targetDuration = [self parseDecimalInteger:line];
    } else if ([line hasPrefix:HLSTagMediaSequence]) {
        self.mediaSequence = [self parseDecimalInteger:line];
    } else if ([line hasPrefix:HLSTagDiscontinuitySequence]) {
        self.discontinuitySequence = [self parseDecimalInteger:line];
    } else if ([line hasPrefix:HLSTagINF]) {
        HLSMediaSegment *segment = [self parseMediaSegment:line moreLines:moreLines];
        segment.sequence = self.currentMediaSequence++;
        [self.segments addObject:segment];
        self.lastMediaSegmentDuration = segment.duration;
    } else if ([line isEqualToString:HLSTagEndList]) {
        self.endList = YES;
    } else if ([line hasPrefix:HLSTagPlaylistType]) {
        self.type = [self parseMediaPlaylistType:line];
    }
}

- (HLSMediaPlaylistType)parseMediaPlaylistType:(NSString *)line {
    NSUInteger colonIndex = [line rangeOfString:@":"].location;
    if (colonIndex == NSNotFound) return 0;
    if (colonIndex + 1 >= line.length) return 0;
    NSString *s = [[line substringFromIndex:colonIndex+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([s isEqualToString:HLSTagValuePlaylistTypeEvent]) {
        return HLSMediaPlaylistTypeEvent;
    } else if ([s isEqualToString:HLSTagValuePlaylistTypeVOD]) {
        return HLSMediaPlaylistTypeVOD;
    } else {
        return HLSMediaPlaylistTypeUndefined;
    }
}

- (HLSMediaSegment *)parseMediaSegment:(NSString *)line moreLines:(NSArray<NSString *> *)moreLines {
    NSCharacterSet *whiteAndNewline = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    line = [line stringByTrimmingCharactersInSet:whiteAndNewline];
    NSInteger commaIndex = [line rangeOfString:@","].location;
    if (commaIndex == NSNotFound) return nil;
    else if (commaIndex == line.length - 1 && moreLines.count == 0) return nil;
    
    NSString *durationString = [line substringToIndex:commaIndex];
    CGFloat duration = [self parseDecimalFloat:durationString];
    NSString *url = nil;
    // #EXTINF:4,http://...
    if (commaIndex < line.length - 1) {
        NSString *urlString = [line substringFromIndex:commaIndex + 1];
        url = [urlString stringByTrimmingCharactersInSet:whiteAndNewline];
    } else {
        url = [moreLines firstObject];
    }
    return [self createMediaSegment:duration url:url];
}

- (HLSMediaSegment *)createMediaSegment:(CGFloat)duration url:(NSString *)url {
    HLSMediaSegment *segment = [[HLSMediaSegment alloc] init];
    segment.duration = duration;
    segment.url = [self validURL:url withHLSURL:self.hlsURL];
    segment.downloadable = YES;
    return segment;
}

- (NSString *)validURL:(NSString *)segmentUrl withHLSURL:(NSString *)hslUrl {
    if (hslUrl == nil) return segmentUrl;
    NSURL *segUrl = [NSURL URLWithString:segmentUrl];
    if (segUrl.scheme == nil) {
        NSString *validUrl = segmentUrl;
        unichar firstChar = [segmentUrl characterAtIndex:0];
        if (firstChar == '/') {
            NSURLComponents *components = [NSURLComponents componentsWithString:hslUrl];
            if (components == nil) return segmentUrl;
            components.path = components.fragment = components.query = nil;
            NSURL *baseUrl = [components URL];
            validUrl = [[baseUrl URLByAppendingPathComponent:segmentUrl] absoluteString];
        } else {
            if (firstChar == '.') validUrl = [segmentUrl substringFromIndex:1];
            NSURL *hls = [NSURL URLWithString:hslUrl];
            NSURL *relativeUrl = [hls URLByDeletingLastPathComponent];
            validUrl = [[relativeUrl URLByAppendingPathComponent:validUrl] absoluteString];
        }
        return validUrl;
    } else {
        return segmentUrl;
    }
}

- (NSInteger)parseDecimalInteger:(NSString *)line {
    NSUInteger colonIndex = [line rangeOfString:@":"].location;
    if (colonIndex == NSNotFound) return 0;
    if (colonIndex + 1 >= line.length) return 0;
    NSString *s = [[line substringFromIndex:colonIndex+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSInteger value = [s integerValue];
    return value;
}

- (CGFloat)parseDecimalFloat:(NSString *)line {
    NSUInteger colonIndex = [line rangeOfString:@":"].location;
    if (colonIndex == NSNotFound) return 0;
    if (colonIndex + 1 >= line.length) return 0;
    NSString *s = [[line substringFromIndex:colonIndex+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    CGFloat value = [s floatValue];
    return value;
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
