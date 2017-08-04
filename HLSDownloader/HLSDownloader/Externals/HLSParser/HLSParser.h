//
//  HLSParser.h
//  HLSDownloader
//
//  Created by Liu Junqi on 01/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLSParserDelegate.h"

@interface HLSParser : NSObject

@property (nonatomic, weak) id<HLSParserDelegate> delegate;
@property (nonatomic) NSString *urlString;
@property (nonatomic) BOOL isHLSFile;

- (instancetype)initWithURL:(NSString *)urlString;
- (void)startDownloadFile;
- (void)cancelDownloadFile;

@end
