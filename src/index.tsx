import {
  EmitterSubscription,
  NativeEventEmitter,
  NativeModules,
  Platform,
} from 'react-native';
import type { BeaconInfo, NotifcationInfo } from './types';

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
  const eventEmitter = new NativeEventEmitter(
    NativeModules.JarvisTemplateAppSdk
  );
  eventListener = eventEmitter.addListener('BeaconInformation', (event) => {
    const { uuid, minor, major, time, title, description } = event;
    const device: BeaconInfo = { uuid, minor, major };
    const notification: NotifcationInfo = { title, description };
    onProximityPush(device, notification, time);
  });

  return JarvisTemplateAppSdk.startScanService(
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
  return JarvisTemplateAppSdk.stopScanService();
};

export { startScanService, stopScanService, BeaconInfo, NotifcationInfo };
