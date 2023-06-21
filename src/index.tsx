import {
  NativeEventEmitter,
  NativeModules,
  Platform,
  requireNativeComponent,
  ViewStyle,
} from 'react-native';
import {
  BeaconInfo,
  NotifcationInfo,
  JarvisServiceStatus,
  InitSipAppResult,
  SipCallState,
  SipRegistrationState,
} from './types';
import React from 'react';

const LINKING_ERROR =
  "The package 'react-native-jarvis-template-app-sdk' doesn't seem to be linked. Make sure: \n\n" +
  Platform.select({
    ios: "- You have run 'pod install'\n",
    default: '',
  }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

const JarvisTemplateAppSdk = NativeModules.JarvisTemplateAppSdk
  ? NativeModules.JarvisTemplateAppSdk
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

let onAccountRegistrationStateListener: (state: number) => void;
let onCallStateListener: (state: number, remoteAddress: string) => void;

const eventEmitter = new NativeEventEmitter(NativeModules.JarvisTemplateAppSdk);

let proximityPushCallback: (
  device: BeaconInfo,
  notification: NotifcationInfo,
  time: string
) => void;

let gpsLocatingCallback: (
  device: BeaconInfo,
  userId: string,
  lat: string,
  lng: string,
  time: string
) => void;

eventEmitter.addListener('BeaconInformation', (event) => {
  const { uuid, minor, major, time, title, description } = event;
  const device: BeaconInfo = { uuid, minor, major };
  const notification: NotifcationInfo = { title, description };

  if (proximityPushCallback) {
    proximityPushCallback(device, notification, time);
  }
});

eventEmitter.addListener('GpsInformation', (event) => {
  const { uuid, minor, major, time, userId, lat, lng } = event;

  const device: BeaconInfo = { uuid, minor, major };
  if (gpsLocatingCallback) {
    gpsLocatingCallback(device, userId, lat, lng, time);
  }
});

eventEmitter.addListener('SipAppAccountState', (event) => {
  const { state } = event;

  !!onAccountRegistrationStateListener &&
    onAccountRegistrationStateListener(state);
});

eventEmitter.addListener('SipCallState', (event) => {
  const { state, remoteAddress } = event;

  !!onCallStateListener && onCallStateListener(state, remoteAddress);
});

const startScanService = async (
  sdkKey: string,
  locatingRange: number,
  notificationIconName: string,
  notificationTitle: string,
  notificationDescription: string,
  onProximityPush: (
    device: BeaconInfo,
    notification: NotifcationInfo,
    time: string
  ) => void
): Promise<boolean> => {
  proximityPushCallback = onProximityPush;
  return await JarvisTemplateAppSdk.startScanService(
    sdkKey,
    locatingRange,
    notificationIconName,
    notificationTitle,
    notificationDescription
  );
};

const stopScanService = async (): Promise<void> => {
  // @ts-ignore
  proximityPushCallback = null;
  return await JarvisTemplateAppSdk.stopScanService();
};

const getServiceStatus = async (): Promise<JarvisServiceStatus> => {
  return await JarvisTemplateAppSdk.getScanServiceStatus();
};

const startLocatingService = async (
  sdkKey: string,
  locatingRange: number,
  notificationIconName: string,
  notificationTitle: string,
  notificationDescription: string,
  onGpsFound: (
    device: BeaconInfo,
    userId: string,
    lat: string,
    lng: string,
    time: string
  ) => void
): Promise<boolean> => {
  gpsLocatingCallback = onGpsFound;
  return await JarvisTemplateAppSdk.startLocatingService(
    sdkKey,
    locatingRange,
    notificationIconName,
    notificationTitle,
    notificationDescription
  );
};

const stopLocatingService = async (): Promise<void> => {
  // @ts-ignore
  gpsLocatingCallback = null;
  return await JarvisTemplateAppSdk.stopLocatingService();
};

const initSipApplication = async (
  username: string,
  password: string,
  onAccountRegistrationStateChange: (state: SipRegistrationState) => void,
  onCallStateChange: (state: SipCallState, remoteAddress: string) => void
): Promise<InitSipAppResult> => {
  onAccountRegistrationStateListener = onAccountRegistrationStateChange;
  onCallStateListener = onCallStateChange;
  return await JarvisTemplateAppSdk.initSipApplication(username, password);
};

const stopSipApplication = (): void => {
  // @ts-ignore
  onAccountRegistrationStateListener = null;
  // @ts-ignore
  onCallStateListener = null;

  JarvisTemplateAppSdk.stopSipApplication();
};

const answerIncomingCall = (): void => {
  JarvisTemplateAppSdk.answerIncomingCall();
};

const rejectIncomingCall = (): void => {
  JarvisTemplateAppSdk.rejectIncomingCall();
};

const toggleMute = (): void => {
  JarvisTemplateAppSdk.toggleMute();
};

const toggleSpeaker = (): void => {
  JarvisTemplateAppSdk.toggleSpeaker();
};

const toggleVideo = (): void => {
  JarvisTemplateAppSdk.toggleVideo();
};

const toggleCamera = (): void => {
  JarvisTemplateAppSdk.toggleCamera();
};

const SipVideoCallPreviewRaw = requireNativeComponent('SipVideoCallPreview');

const SipVideoCallPreview: React.FC<{
  style?: ViewStyle;
}> = (props) => {
  return <SipVideoCallPreviewRaw {...props} />;
};

export {
  startScanService,
  stopScanService,
  getServiceStatus,
  startLocatingService,
  stopLocatingService,
  initSipApplication,
  stopSipApplication,
  answerIncomingCall,
  rejectIncomingCall,
  toggleMute,
  toggleSpeaker,
  toggleVideo,
  toggleCamera,
  BeaconInfo,
  NotifcationInfo,
  SipVideoCallPreview,
  SipCallState,
  SipRegistrationState,
};
