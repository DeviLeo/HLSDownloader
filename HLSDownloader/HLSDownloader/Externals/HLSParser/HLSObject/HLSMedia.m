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
        self.forcedString = attributes[HLSTagKeyForced];
        self.autoSelectString = attributes[HLSTagKeyAutoSelect];
        self.language = attributes[HLSTagKeyLanguage];
        self.characteristics = attributes[HLSTagKeyCharacteristics];
    }
    return self;
}

- (void)setTypeString:(NSString *)typeString {
    _typeString = typeString;
    if (typeString == nil) _type = HLSMediaTypeUndefined;
    else if ([typeString isEqualToString:HLSTagValueMediaTypeAudio]) _type = HLSMediaTypeAudio;
    else if ([typeString isEqualToString:HLSTagValueMediaTypeVideo]) _type = HLSMediaTypeVideo;
    else if ([typeString isEqualToString:HLSTagValueMediaTypeSubtitles]) _type = HLSMediaTypeSubtitles;
    else _type = HLSMediaTypeUnknown;
}

- (void)setDefaultString:(NSString *)defaultString {
    _defaultString = defaultString;
    _isDefault = [self boolFromString:defaultString];
}

- (void)setForcedString:(NSString *)forcedString {
    _forcedString = forcedString;
    _isForced = [self boolFromString:forcedString];
}

- (void)setAutoSelectString:(NSString *)autoSelectString {
    _autoSelectString = autoSelectString;
    _isAutoSelect = [self boolFromString:autoSelectString];
}

- (BOOL)boolFromString:(NSString *)boolString {
    if (boolString == nil) return NO;
    else if ([boolString isEqualToString:HLSTagValueBooleanYES]) return YES;
    else if ([boolString isEqualToString:HLSTagValueBooleanNO]) return NO;
    else return NO;
}

@end
