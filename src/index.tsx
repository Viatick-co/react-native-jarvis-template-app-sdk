import {
  EmitterSubscription,
  NativeEventEmitter,
  NativeModules,
  Platform,
} from 'react-native';
import type { BeaconInfo, NotifcationInfo, JarvisServiceStatus } from './types';

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

const eventEmitter = new NativeEventEmitter(NativeModules.JarvisTemplateAppSdk);

let eventListener: EmitterSubscription;

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
      console.log('yes');
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

const stopScanService = (): void => {
  if (eventListener) {
    eventListener.remove();
  }
  return JarvisTemplateAppSdk.stopScanService();
};

const getServiceStatus = async (): Promise<JarvisServiceStatus> => {
  return await JarvisTemplateAppSdk.getScanServiceStatus();
};

export {
  startScanService,
  stopScanService,
  getServiceStatus,
  BeaconInfo,
  NotifcationInfo,
};
