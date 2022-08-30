import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-jarvis-template-app-sdk' doesn't seem to be linked. Make sure: \n\n` +
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

export const startScanService = async (
  sdkKey: string,
  locatingRange: number,
  notificationIconName: string,
  notificationTitle: string,
  notificationDescription: string
): Promise<boolean> => {
  return JarvisTemplateAppSdk.startScanService(
    sdkKey,
    locatingRange,
    notificationIconName,
    notificationTitle,
    notificationDescription
  );
};

export const stopScanService = async (): Promise<void> => {
  return JarvisTemplateAppSdk.stopScanService();
};
