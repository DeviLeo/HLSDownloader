//
//  HLSConstants.h
//  HLSDownloader
//
//  Created by Liu Junqi on 01/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#ifndef HLSConstants_h
#define HLSConstants_h

#pragma mark - Basic Tag
#define HLSTagHeader                    @"#EXTM3U"
#define HLSTagVersion                   @"#EXT-X-VERSION"

#pragma mark - Master Playlist Tag
#define HLSTagMedia                     @"#EXT-X-MEDIA"
#define HLSTagStreamINF                 @"#EXT-X-STREAM-INF"
#define HLSTagIFrameStreamINF           @"#EXT-X-I-FRAME-STREAM-INF"
#define HLSTagSessionData               @"#EXT-X-SESSION-DATA"
#define HLSTagSessionKey                @"#EXT-X-SESSION-KEY"

#pragma mark - Media Playlist Tag
#define HLSTagTargetDuration            @"#EXT-X-TARGETDURATION"
#define HLSTagMediaSequence             @"#EXT-X-MEDIA-SEQUENCE"
#define HLSTagDiscontinuitySequence     @"#EXT-X-DISCONTINUITY-SEQUENCE"
#define HLSTagEndList                   @"#EXT-X-ENDLIST"
#define HLSTagPlaylistType              @"#EXT-X-PLAYLIST-TYPE"
#define HLSTagIFramesOnly               @"#EXT-X-I-FRAMES-ONLY"

#pragma mark - Media Segment Tag
#define HLSTagINF                       @"#EXTINF"
#define HLSTagByteRange                 @"#EXT-X-BYTERANGE"
#define HLSTagDiscontinuity             @"#EXT-X-DISCONTINUITY"
#define HLSTagKey                       @"#EXT-X-KEY"
#define HLSTagMap                       @"#EXT-X-MAP"
#define HLSTagProgramDateTime           @"#EXT-X-PROGRAM-DATE-TIME"
#define HLSTagDateRange                 @"#EXT-X-DATERANGE"
#define HLSTagGap                       @"#EXT-X-GAP"

#pragma mark - Master Playlist and Media Playlist Tag
#define HLSTagIndependentSegments       @"#EXT-X-INDEPENDENT-SEGMENTS"
#define HLSTagStart                     @"#EXT-X-START"
#define HLSTagDefine                    @"#EXT-X-DEFINE"


#pragma mark - Tag Key
#define HLSTagKeyAssociatedLanguage     @"ASSOC-LANGUAGE"
#define HLSTagKeyAudio                  @"AUDIO"
#define HLSTagKeyAutoSelect             @"AUTOSELECT"
#define HLSTagKeyAverageBandwidth       @"AVERAGE-BANDWIDTH"
#define HLSTagKeyBandwidth              @"BANDWIDTH"
#define HLSTagKeyClosedCaptions         @"CLOSED-CAPTIONS"
#define HLSTagKeyCodecs                 @"CODECS"
#define HLSTagKeyCharacteristics        @"CHARACTERISTICS"
#define HLSTagKeyChannels               @"CHANNELS"
#define HLSTagKeyDataID                 @"DATA-ID"
#define HLSTagKeyDefault                @"DEFAULT"
#define HLSTagKeyForced                 @"FORCED"
#define HLSTagKeyFrameRate              @"FRAME-RATE"
#define HLSTagKeyGroupID                @"GROUP-ID"
#define HLSTagKeyHDCPLevel              @"HDCP-LEVEL"
#define HLSTagKeyID                     @"ID"
#define HLSTagKeyInstreamID             @"INSTREAM-ID"
#define HLSTagKeyLanguage               @"LANGUAGE"
#define HLSTagKeyMethod                 @"METHOD"
#define HLSTagKeyName                   @"NAME"
#define HLSTagKeyPlannedDuration        @"PLANNED-DURATION"
#define HLSTagKeyProgramID              @"PROGRAM-ID"
#define HLSTagKeyResolution             @"RESOLUTION"
#define HLSTagKeySCTE35Cmd              @"SCTE35-CMD"
#define HLSTagKeySCTE35In               @"SCTE35-IN"
#define HLSTagKeySCTE35Out              @"SCTE35-OUT"
#define HLSTagKeyStartDate              @"START-DATE"
#define HLSTagKeySubtitles              @"SUBTITLES"
#define HLSTagKeyType                   @"TYPE"
#define HLSTagKeyURI                    @"URI"
#define HLSTagKeyValue                  @"VALUE"
#define HLSTagKeyVideo                  @"VIDEO"

#pragma mark - Tag Value
#define HLSTagValuePlaylistTypeEvent    @"EVENT"
#define HLSTagValuePlaylistTypeVOD      @"VOD"
#define HLSTagValueMediaTypeAudio       @"AUDIO"
#define HLSTagValueMediaTypeVideo       @"VIDEO"
#define HLSTagValueMediaTypeSubtitles   @"SUBTITLES"
#define HLSTagValueBooleanYES           @"YES"
#define HLSTagValueBooleanNO            @"NO"

#endif /* HLSConstants_h */
