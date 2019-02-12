//
//  HLSMediaSegment.h
//  HLSDownloader
//
//  Created by Liu Junqi on 02/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HLSMediaSegment : NSObject

@property (nonatomic) NSInteger sequence;
@property (nonatomic) CGFloat duration;
@property (nonatomic) NSString *url;
@property (nonatomic) BOOL downloadable;
@property (nonatomic) NSString *filepath;

@end
