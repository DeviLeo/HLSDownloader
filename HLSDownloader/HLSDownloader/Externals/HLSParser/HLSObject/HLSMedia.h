//
//  HLSMedia.h
//  HLSDownloader
//
//  Created by Liu Junqi on 25/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLSTypeDef.h"

@interface HLSMedia : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *groupID;
@property (nonatomic) NSString *typeString;
@property (nonatomic) HLSMediaType type;
@property (nonatomic) NSString *uri;
@property (nonatomic) NSString *defaultString;
@property (nonatomic) BOOL isDefault;
@property (nonatomic) NSString *forcedString;
@property (nonatomic) BOOL isForced;
@property (nonatomic) NSString *language;
@property (nonatomic) NSString *characteristics;
@property (nonatomic) NSString *autoSelectString;
@property (nonatomic) BOOL isAutoSelect;

- (instancetype)initWithAttributes:(NSDictionary *)attributes;

@end
