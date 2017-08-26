//
//  HLSMedia.m
//  HLSDownloader
//
//  Created by Liu Junqi on 25/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import "HLSMedia.h"
#import "HLSConstants.h"

@implementation HLSMedia

- (instancetype)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (self) {
        self.name = attributes[HLSTagKeyName];
        self.groupID = attributes[HLSTagKeyGroupID];
        self.typeString = attributes[HLSTagKeyType];
        self.uri = attributes[HLSTagKeyURI];
        self.defaultString = attributes[HLSTagKeyDefault];
    }
    return self;
}

- (void)setTypeString:(NSString *)typeString {
    _typeString = typeString;
    if (typeString == nil) _type = HLSMediaTypeUndefined;
    else if ([typeString isEqualToString:HLSTagValueMediaTypeAudio]) _type = HLSMediaTypeAudio;
    else if ([typeString isEqualToString:HLSTagValueMediaTypeVideo]) _type = HLSMediaTypeVideo;
    else _type = HLSMediaTypeUnknown;
}

- (void)setDefaultString:(NSString *)defaultString {
    _defaultString = defaultString;
    if (defaultString == nil) _isDefault = NO;
    else if ([defaultString isEqualToString:HLSTagValueBooleanYES]) _isDefault = YES;
    else if ([defaultString isEqualToString:HLSTagValueBooleanNO]) _isDefault = NO;
    else _isDefault = NO;
}

@end
