//
//  HLSMasterPlaylist.m
//  HLSDownloader
//
//  Created by Liu Junqi on 25/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import "HLSMasterPlaylist.h"

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

@end
