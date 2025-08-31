//
//  AudioModules.m
//  TestApp
//
//  Created by Kusal Kalinga on 2025-08-31.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

// @interface RCT_EXTERN_MODULE(AudioPlayerModule, RCTEventEmitter)
// RCT_EXTERN_METHOD(playAudio:(NSString *)base64Audio)
// RCT_EXTERN_METHOD(stopAudio)
// @end

@interface RCT_EXTERN_MODULE(AudioManagerModule, RCTEventEmitter)
RCT_EXTERN_METHOD(start:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(stop:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(startRecording:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)


RCT_EXTERN_METHOD(playAudioChunk:(NSString *)base64)
RCT_EXTERN_METHOD(clearQueue)
RCT_EXTERN_METHOD(stopAudio)
RCT_EXTERN_METHOD(stopRecording)
@end
