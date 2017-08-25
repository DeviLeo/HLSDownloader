//
//  HLSObject.m
//  HLSDownloader
//
//  Created by Liu Junqi on 02/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import "HLSObject.h"
#import "HLSConstants.h"
#import "HLSMediaSegment.h"
#import "HLSMasterPlaylist.h"
#import "HLSStreamInfo.h"
#import "HLSMedia.h"

@interface HLSObject ()

@property (nonatomic) NSInteger currentMediaSequence;

@end

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
    self.version = 0;
    self.discontinuity = NO;
    self.targetDuration = 0;
    self.mediaSequence = 0;
    self.currentMediaSequence = 0;
    self.endList = NO;
    self.segments = [NSMutableArray arrayWithCapacity:8];
    self.masterPlaylist = [[HLSMasterPlaylist alloc] init];
}

#pragma mark - Parse
- (void)parse {
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:self.file encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"*** stringWithContentsOfFile: %@ error: %@", self.file, error);
        return;
    }
    
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

- (BOOL)parseLine:(NSString *)line moreLines:(NSArray<NSString *> *)moreLines {
    BOOL parsed = YES;
    if ([line isEqualToString:HLSTagHeader]) {
        return YES;
    } else if ([line hasPrefix:HLSTagVersion]) {
        self.version = [self parseDecimalInteger:line];
    } else if ([line isEqualToString:HLSTagDiscontinuity]) {
        self.discontinuity = YES;
    } else if ([line hasPrefix:HLSTagTargetDuration]) {
        self.targetDuration = [self parseDecimalInteger:line];
    } else if ([line hasPrefix:HLSTagMediaSequence]) {
        self.mediaSequence = [self parseDecimalInteger:line];
        self.currentMediaSequence = self.mediaSequence;
    } else if ([line hasPrefix:HLSTagDiscontinuitySequence]) {
        self.discontinuitySequence = [self parseDecimalInteger:line];
    } else if ([line hasPrefix:HLSTagINF]) {
        parsed = [self parseMediaSegment:line moreLines:moreLines];
    } else if ([line isEqualToString:HLSTagEndList]) {
        self.endList = YES;
    } else if ([line hasPrefix:HLSTagPlaylistType]) {
        self.playlistType = [self parsePlaylistType:line];
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
    return parsed;
}

- (HLSMedia *)parseMedia:(NSString *)line {
    NSDictionary *attributes = [self parseAttributes:line];
    HLSMedia *media = [[HLSMedia alloc] init];
    media.name = attributes[HLSTagKeyName];
    media.groupID = attributes[HLSTagKeyGroupID];
    media.typeString = attributes[HLSTagKeyType];
    media.uri = attributes[HLSTagKeyURI];
    media.defaultString = attributes[HLSTagKeyDefault];
    return media;
}

- (HLSStreamInfo *)parseIFrameStreamInf:(NSString *)line {
    NSDictionary *attributes = [self parseAttributes:line];
    HLSStreamInfo *stream = [[HLSStreamInfo alloc] init];
    stream.isIFrame = YES;
    stream.uri = attributes[HLSTagKeyURI];
    stream.codecs = attributes[HLSTagKeyCodecs];
    stream.bandwidth = [attributes[HLSTagKeyBandwidth] integerValue];
    stream.averageBandwidth = [attributes[HLSTagKeyAverageBandwidth] integerValue];
    stream.videoGroupID = attributes[HLSTagKeyVideo];
    stream.audioGroupID = attributes[HLSTagKeyAudio];
    return stream;
}

- (HLSStreamInfo *)parseStreamInf:(NSString *)line moreLines:(NSArray<NSString *> *)moreLines {
    NSDictionary *attributes = [self parseAttributes:line];
    HLSStreamInfo *stream = [[HLSStreamInfo alloc] init];
    stream.isIFrame = NO;
    stream.uri = moreLines.count == 0 ? nil : [moreLines firstObject];
    stream.codecs = attributes[HLSTagKeyCodecs];
    stream.bandwidth = [attributes[HLSTagKeyBandwidth] integerValue];
    stream.averageBandwidth = [attributes[HLSTagKeyAverageBandwidth] integerValue];
    stream.videoGroupID = attributes[HLSTagKeyVideo];
    stream.audioGroupID = attributes[HLSTagKeyAudio];
    return stream;
}

- (HLSPlaylistType)parsePlaylistType:(NSString *)line {
    NSUInteger colonIndex = [line rangeOfString:@":"].location;
    if (colonIndex == NSNotFound) return 0;
    if (colonIndex + 1 >= line.length) return 0;
    NSString *s = [[line substringFromIndex:colonIndex+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([s isEqualToString:HLSTagValuePlaylistTypeEvent]) {
        return HLSPlaylistTypeEvent;
    } else if ([s isEqualToString:HLSTagValuePlaylistTypeVOD]) {
        return HLSPlaylistTypeVOD;
    } else {
        return HLSPlaylistTypeUndefined;
    }
}

- (BOOL)parseMediaSegment:(NSString *)line moreLines:(NSArray<NSString *> *)moreLines {
    NSCharacterSet *whiteAndNewline = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    line = [line stringByTrimmingCharactersInSet:whiteAndNewline];
    NSInteger commaIndex = [line rangeOfString:@","].location;
    if (commaIndex == NSNotFound) return YES;
    else if (commaIndex == line.length - 1 && moreLines.count == 0) return NO;
    
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
    [self createMediaSegment:duration url:url];
    
    return YES;
}

- (void)createMediaSegment:(CGFloat)duration url:(NSString *)url {
    HLSMediaSegment *segment = [[HLSMediaSegment alloc] init];
    segment.sequence = self.currentMediaSequence++;
    segment.duration = duration;
    segment.url = [self validURL:url withHLSURL:self.url];
    segment.downloadable = YES;
    [self.segments addObject:segment];
    self.lastMediaSegmentDuration = duration;
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
    BOOL shouldHandleMore = NO;
    do {
        NSString *trimmedString = [str stringByTrimmingCharactersInSet:set];
        NSInteger lastCharIndex = trimmedString.length - 1;
        NSString *lastCharString = [trimmedString substringFromIndex:lastCharIndex];
        if ([lastCharString isEqualToString:@"\\"]) {
            str = [trimmedString substringToIndex:lastCharIndex];
        } else {
            shouldHandleMore = NO;
        }
        [oneLine appendString:str];
        if ([lastCharString isEqualToString:@","]) break;
        if (moreLines.count == 0) break;
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
        NSString *key = [str substringWithRange:NSMakeRange(index, r.location)];
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
            value = [str substringWithRange:NSMakeRange(index+1, r.location-index)];
            dict[key] = value;
            index = r.location + r.length;
            len = length - index;
        }
        
        dict[key] = value;
        r = [str rangeOfString:@"," options:0 range:NSMakeRange(index, len)];
        if (r.location == NSNotFound) break;
        if (value == nil) { // Not quoted-string value
            value = [str substringWithRange:NSMakeRange(index, r.location-index)];
            value = [value stringByTrimmingCharactersInSet:set];
            dict[key] = value;
        }
        index = r.location + r.length;
        len = length - index;
    } while (index < length);
    
    return dict;
}

@end
