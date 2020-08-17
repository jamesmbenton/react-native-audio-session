//
//  RNAudioSession.m
//  RNAudioSession
//
//  Created by Johan Kasperi (DN) on 2018-03-02.
//

#import "RNAudioSession.h"
#import <React/RCTLog.h>
#import <AVFoundation/AVFoundation.h>

@implementation RNAudioSession

static NSDictionary *_categories;
static NSDictionary *_options;
static NSDictionary *_modes;

+ (void)initialize {
    _categories = @{
        @"Ambient": AVAudioSessionCategoryAmbient,
        @"SoloAmbient": AVAudioSessionCategorySoloAmbient,
        @"Playback": AVAudioSessionCategoryPlayback,
        @"Record": AVAudioSessionCategoryRecord,
        @"PlayAndRecord": AVAudioSessionCategoryPlayAndRecord,
        @"MultiRoute": AVAudioSessionCategoryMultiRoute
   };
    _options = @{
        @"MixWithOthers": @(AVAudioSessionCategoryOptionMixWithOthers),
        @"DuckOthers": @(AVAudioSessionCategoryOptionDuckOthers),
        @"InterruptSpokenAudioAndMixWithOthers": @(AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers),
        @"AllowBluetooth": @(AVAudioSessionCategoryOptionAllowBluetooth),
        @"AllowBluetoothA2DP": @(AVAudioSessionCategoryOptionAllowBluetoothA2DP),
        @"AllowAirPlay": @(AVAudioSessionCategoryOptionAllowAirPlay),
        @"DefaultToSpeaker": @(AVAudioSessionCategoryOptionDefaultToSpeaker)
    };
    _modes = @{
        @"Default": AVAudioSessionModeDefault,
        @"VoiceChat": AVAudioSessionModeVoiceChat,
        @"VideoChat": AVAudioSessionModeVideoChat,
        @"GameChat": AVAudioSessionModeGameChat,
        @"VideoRecording": AVAudioSessionModeVideoRecording,
        @"Measurement": AVAudioSessionModeMeasurement,
        @"MoviePlayback": AVAudioSessionModeMoviePlayback,
        @"SpokenAudio": AVAudioSessionModeSpokenAudio
    };
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(category:(RCTResponseSenderBlock)callback)
{
    NSString *cat = [AVAudioSession sharedInstance].category;
    NSArray *temp = [_categories allKeysForObject:cat];
    NSString *key = [temp lastObject];
    if (key) {
        callback(@[key]);
    } else {
        callback(@[]);
    }
}

RCT_EXPORT_METHOD(options:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSUInteger options = [AVAudioSession sharedInstance].categoryOptions;
    NSLog(@"Current audio session options bitmask %lu", options);
    NSArray *optionsArray = [self convertOptionsBitmaskToArray: options];
    resolve(optionsArray);

}

RCT_EXPORT_METHOD(mode:(RCTResponseSenderBlock)callback)
{
    NSString *mode = [AVAudioSession sharedInstance].mode;
    NSArray *temp = [_modes allKeysForObject:mode];
    NSString *key = [temp lastObject];
    if (key) {
        callback(@[key]);
    } else {
        callback(@[]);
    }
}

RCT_EXPORT_METHOD(setActive:(BOOL)active resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setActive:active withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    if (error) {
        reject(@"setActive", @"Could not set active.", error);
    } else {
        resolve(@[]);
    }
}

RCT_EXPORT_METHOD(setCategory:(NSString *)category options:(NSArray *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString* cat = _categories[category];
    
    if (cat != nil && [[AVAudioSession sharedInstance].availableCategories containsObject:cat]) {
        NSError *error = nil;
        if (options != nil) {
            [[AVAudioSession sharedInstance] setCategory:cat withOptions: [self convertOptionsToBitmask: options] error:&error];
        } else {
            [[AVAudioSession sharedInstance] setCategory:cat error:&error];
        }
        if (error) {
            reject(@"setCategory", @"Could not set category.", error);
        } else {
            resolve(@[]);
        }
    } else {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: @"Could not set AVAudioSession category.",
                                   NSLocalizedFailureReasonErrorKey: @"The given category is not supported on this device.",
                                   NSLocalizedRecoverySuggestionErrorKey: @"Try another category."
                                   };
        NSError *error = [NSError errorWithDomain:@"RNAudioSession" code:-1 userInfo:userInfo];
        reject(@"setCategory", @"Could not set category.", error);
    }
}


RCT_EXPORT_METHOD(setMode:(NSString *)mode resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString* mod = _modes[mode];
    if (mod != nil && [[AVAudioSession sharedInstance].availableModes containsObject:mod]) {
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setMode:mod error:&error];
        if (error) {
            reject(@"setMode", @"Could not set mode.", error);
        } else {
            resolve(@[]);
        }
    } else {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: @"Could not set AVAudioSession mode.",
                                   NSLocalizedFailureReasonErrorKey: @"The given mode is not supported on this device.",
                                   NSLocalizedRecoverySuggestionErrorKey: @"Try another mode."
                                   };
        NSError *error = [NSError errorWithDomain:@"RNAudioSession" code:-1 userInfo:userInfo];
        reject(@"setMode", @"Could not set mode.", error);
    }
}

RCT_EXPORT_METHOD(setCategoryAndMode:(NSString *)category mode:(NSString *)mode options:(NSArray *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString* cat = _categories[category];
    NSString* mod = _modes[mode];
    if (cat != nil && mod != nil && options != nil && [[AVAudioSession sharedInstance].availableCategories containsObject:cat] && [[AVAudioSession sharedInstance].availableModes containsObject:mod]) {
        NSError *error = nil;
        NSUInteger optionsArg = [self convertOptionsToBitmask: options];
        [[AVAudioSession sharedInstance] setCategory:cat mode:mod options: optionsArg error:&error];
        
        if (error) {
            reject(@"setCategoryAndMode", @"Could not set category and mode.", error);
        } else {
            resolve(@[]);
        }
    } else {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: @"Could not set AVAudioSession category and mode.",
                                   NSLocalizedFailureReasonErrorKey: @"The given category or mode is not supported on this device.",
                                   NSLocalizedRecoverySuggestionErrorKey: @"Try another category or mode."
                                   };
        NSError *error = [NSError errorWithDomain:@"RNAudioSession" code:-1 userInfo:userInfo];
        reject(@"setCategoryAndMode", @"Could not set category and mode.", error);
    }
}

-(NSUInteger) convertOptionsToBitmask:(NSArray *) array  {
    
    NSUInteger bitmask = 0x0;
    
    for (int i = 0; i < [array count]; i++)
    {
        NSString *key = array[i];
        NSNumber *value = [_options objectForKey:key];
        if(value != nil) {
            bitmask = bitmask | [value unsignedIntegerValue];
        }
    }
    
    NSLog(@"Audio session options array to bitmask: %lu", bitmask);
    //NSLog(@"Test audio session options array to bitmask %lu", AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetoothA2DP);
    return bitmask;
}

-(NSArray *) convertOptionsBitmaskToArray:(NSUInteger) options  {
    
    NSMutableArray *array = [NSMutableArray array];
    
    for(id key in _options) {
        NSNumber *option = [_options objectForKey:key];
        NSUInteger optionInt = [option unsignedIntegerValue];
        
        if((optionInt & options) == optionInt) {
            [array addObject: key];
        }
    }
    return array;
}

@end
