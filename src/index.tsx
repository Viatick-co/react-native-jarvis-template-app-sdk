import {
  EmitterSubscription,
  NativeEventEmitter,
  NativeModules,
  Platform,
  requireNativeComponent,
} from 'react-native';
import {
  BeaconInfo,
  NotifcationInfo,
  JarvisServiceStatus,
  InitSipAppResult,
  SipCallState,
  SipRegistrationState,
} from './types';

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
let onCallStateListener: (state: number) => void;

const eventEmitter = new NativeEventEmitter(NativeModules.JarvisTemplateAppSdk);

let eventListener: EmitterSubscription;
eventEmitter.addListener('SipAppAccountState', (event) => {
  const { state } = event;

  !!onAccountRegistrationStateListener &&
    onAccountRegistrationStateListener(state);
});

eventEmitter.addListener('SipCallState', (event) => {
  const { state } = event;

  !!onCallStateListener && onCallStateListener(state);
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
  eventListener = eventEmitter.addListener('BeaconInformation', (event) => {
    const { uuid, minor, major, time, title, description } = event;
    const device: BeaconInfo = { uuid, minor, major };
    const notification: NotifcationInfo = { title, description };

    if (!!onProximityPush) {
      onProximityPush(device, notification, time);
    }
  });

  return await JarvisTemplateAppSdk.startScanService(
    sdkKey,
    locatingRange,
    notificationIconName,
    notificationTitle,
    notificationDescription
  );
};

const stopScanService = async (): Promise<void> => {
  if (eventListener) {
    eventListener.remove();
  }
  return await JarvisTemplateAppSdk.stopScanService();
};

const getServiceStatus = async (): Promise<JarvisServiceStatus> => {
  return await JarvisTemplateAppSdk.getScanServiceStatus();
};

const initSipApplication = async (
  username: string,
  password: string,
  onAccountRegistrationStateChange: (state: SipRegistrationState) => void,
  onCallStateChange: (state: SipCallState) => void
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

const SipVideoCallPreview = requireNativeComponent('SipVideoCallPreview');

export {
  startScanService,
  stopScanService,
  getServiceStatus,
  initSipApplication,
  stopSipApplication,
  answerIncomingCall,
  rejectIncomingCall,
  BeaconInfo,
  NotifcationInfo,
  SipVideoCallPreview,
  SipCallState,
  SipRegistrationState,
};
