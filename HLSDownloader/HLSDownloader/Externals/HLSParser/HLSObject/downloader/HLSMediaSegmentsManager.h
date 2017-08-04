//
//  HLSMediaSegmentsManager.h
//  HLSDownloader
//
//  Created by Liu Junqi on 02/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLSMediaSegmentsManagerDelegate.h"

@class HLSMediaSegment;

@interface HLSMediaSegmentsManager : NSObject

@property (nonatomic, weak) id<HLSMediaSegmentsManagerDelegate> delegate;

- (void)addSegment:(HLSMediaSegment *)segment;
- (void)startDownloading;
- (void)cancelAllDownloads;

@end
