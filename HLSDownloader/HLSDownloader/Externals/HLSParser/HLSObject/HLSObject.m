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
        BOOL parsed = NO;
        do {
            parsed = [self parseLine:line moreLines:moreLines];
            if (parsed || ++i >= count) break;
            [moreLines addObject:content[i]];
            NSLog(@"** [%zd]line: %@", i+1, content[i]);
        } while(!parsed);
        [moreLines removeAllObjects];
    }
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
    }
    return parsed;
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

@end
