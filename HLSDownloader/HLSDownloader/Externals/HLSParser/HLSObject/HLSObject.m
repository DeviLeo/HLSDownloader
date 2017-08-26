//
//  HLSObject.m
//  HLSDownloader
//
//  Created by Liu Junqi on 02/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import "HLSObject.h"
#import "HLSConstants.h"
#import "HLSMasterPlaylist.h"
#import "HLSStreamInfo.h"
#import "HLSMedia.h"
#import "HLSMediaPlaylist.h"
#import "HLSMediaSegment.h"
#import "HLSErrorDef.h"

@implementation HLSObject

- (instancetype)initWithFile:(NSString *)file {
    self = [super init];
    if (self) {
        self.file = file;
        [self initVars];
    }
    return self;
}

#pragma mark - Init
- (void)initVars {
    self.url = nil;
    self.mediaPlaylist = [[HLSMediaPlaylist alloc] init];
    self.masterPlaylist = [[HLSMasterPlaylist alloc] init];
}

#pragma mark - Parse
- (BOOL)parse {
    return [self parseWithError:nil];
}

- (BOOL)parseWithError:(NSError **)parseError {
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:self.file encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"*** stringWithContentsOfFile: %@ error: %@", self.file, error);
        if (parseError != nil) *parseError = error;
        return NO;
    }
    
    HLSPlaylistType type = [self determinePlaylistType:content];
    if (type == HLSPlaylistTypeUnknown || type == HLSPlaylistTypeUndefined) {
        NSString *errorMessage = @"The playlist is invalid.";
        NSLog(@"%@", errorMessage);
        if (parseError != nil) *parseError = [NSError errorWithDomain:HLSErrorDomain
                                                                 code:HLSErrorCodeInvalidPlaylist
                                                             userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
        return NO;
    }
    self.playlistType = type;
    
    NSArray<NSString *> *allLines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    [self parseHLSContent:allLines];
    return YES;
}

- (HLSPlaylistType)determinePlaylistType:(NSString *)content {
    HLSPlaylistType type = HLSPlaylistTypeUndefined;
    
    // Check "EXT-X-TARGETDURATION" tag to detemine the playlist whether is a media playlist or not.
    BOOL isMediaPlaylist = [content rangeOfString:HLSTagTargetDuration].location != NSNotFound;
    // Check "EXT-X-STREAM-INF" tag to detemine the playlist whether is a master playlist or not.
    BOOL isMasterPlaylist = [content rangeOfString:HLSTagStreamINF].location != NSNotFound;
    
    if (isMediaPlaylist && !isMasterPlaylist) type = HLSPlaylistTypeMedia;
    else if (!isMediaPlaylist && isMasterPlaylist) type = HLSPlaylistTypeMaster;
    else type = HLSPlaylistTypeUnknown;
    
    return type;
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
        self.mediaPlaylist.version = [self parseDecimalInteger:line];
    } else if ([line isEqualToString:HLSTagDiscontinuity]) {
        self.mediaPlaylist.discontinuity = YES;
    } else if ([line hasPrefix:HLSTagTargetDuration]) {
        self.mediaPlaylist.targetDuration = [self parseDecimalInteger:line];
    } else if ([line hasPrefix:HLSTagMediaSequence]) {
        self.mediaPlaylist.mediaSequence = [self parseDecimalInteger:line];
    } else if ([line hasPrefix:HLSTagDiscontinuitySequence]) {
        self.mediaPlaylist.discontinuitySequence = [self parseDecimalInteger:line];
    } else if ([line hasPrefix:HLSTagINF]) {
        HLSMediaSegment *segment = [self parseMediaSegment:line moreLines:moreLines];
        segment.sequence = self.mediaPlaylist.currentMediaSequence++;
        [self.mediaPlaylist.segments addObject:segment];
        self.mediaPlaylist.lastMediaSegmentDuration = segment.duration;
    } else if ([line isEqualToString:HLSTagEndList]) {
        self.mediaPlaylist.endList = YES;
    } else if ([line hasPrefix:HLSTagPlaylistType]) {
        self.mediaPlaylist.type = [self parseMediaPlaylistType:line];
    } else if ([line hasPrefix:HLSTagStreamINF]) {
        HLSStreamInfo *stream = [self parseStreamInf:line moreLines:moreLines];
        [self.masterPlaylist.streams addObject:stream];
    } else if ([line hasPrefix:HLSTagIFrameStreamINF]) {
        HLSStreamInfo *stream = [self parseIFrameStreamInf:line];
        [self.masterPlaylist.iframes addObject:stream];
    } else if ([line hasPrefix:HLSTagMedia]) {
        HLSMedia *media = [self parseMedia:line];
        [self.masterPlaylist.media addObject:media];
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
    segment.url = [self validURL:url withHLSURL:self.url];
    segment.downloadable = YES;
    return segment;
}

- (NSString *)validURL:(NSString *)segmentUrl withHLSURL:(NSString *)hslUrl {
    if (hslUrl == nil) return segmentUrl;
    NSURL *segUrl = [NSURL URLWithString:segmentUrl];
    if (segUrl.scheme == nil) {
        NSURLComponents *components = [NSURLComponents componentsWithString:hslUrl];
        if (components == nil) return segmentUrl;
        components.path = nil;
        components.fragment = nil;
        components.query = nil;
        NSURL *baseUrl = [components URL];
        NSString *validUrl = [[baseUrl absoluteString] stringByAppendingPathComponent:segmentUrl];
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
