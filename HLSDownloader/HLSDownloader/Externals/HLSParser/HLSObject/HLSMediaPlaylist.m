//
//  HLSMediaPlaylist.m
//  HLSDownloader
//
//  Created by DeviLeo on 2017/8/26.
//  Copyright © 2017年 DeviLeo. All rights reserved.
//

#import "HLSMediaPlaylist.h"

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

@end
