//
//  HLSStreamInfo.m
//  HLSDownloader
//
//  Created by Liu Junqi on 25/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import "HLSStreamInfo.h"
#import "HLSConstants.h"

@implementation HLSStreamInfo

- (instancetype)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (self) {
        self.uri = attributes[HLSTagKeyURI];
        self.codecs = attributes[HLSTagKeyCodecs];
        self.bandwidth = [attributes[HLSTagKeyBandwidth] integerValue];
        self.averageBandwidth = [attributes[HLSTagKeyAverageBandwidth] integerValue];
        self.videoGroupID = attributes[HLSTagKeyVideo];
        self.audioGroupID = attributes[HLSTagKeyAudio];
        self.resolutionString = attributes[HLSTagKeyResolution];
        self.programID = attributes[HLSTagKeyProgramID];
    }
    return self;
}

- (void)setResolutionString:(NSString *)resolutionString {
    _resolutionString = resolutionString;
    
    NSArray *a = [resolutionString componentsSeparatedByString:@"x"];
    if (a.count != 2) { self.resolution = CGSizeZero; return; }
    CGFloat w = [a[0] floatValue];
    CGFloat h = [a[1] floatValue];
    self.resolution = CGSizeMake(w, h);
}

@end
