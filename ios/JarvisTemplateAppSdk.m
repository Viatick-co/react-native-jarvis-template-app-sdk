#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(SipVideoCallPreviewManager, RCTViewManager)
@end

@interface RCT_EXTERN_MODULE(JarvisTemplateAppSdk, NSObject)

RCT_EXTERN_METHOD(multiply:(float)a withB:(float)b
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(startScanService:(NSString*)sdkKey
                  withLocatingRange:(nonnull NSNumber*)locatingRange
                  withNotificationIconName:(NSString*)notificationIconName
                  withNotificationTitle:(NSString*)notificationTitle
                  withNotificationDescription:(NSString*)notificationDescription
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(stopScanService:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getScanServiceStatus:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(initSipApplication:(NSString*)username
                withPassword:(NSString*)password
                withResolver:(RCTPromiseResolveBlock)resolve
                withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(answerIncomingCall)
                
+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end

