# Jarvis Template Sdk

Features:
- Locating proximity push

## Installation

---

```sh
yarn add react-native-jarvis-template-app-sdk
```

```sh
npm install react-native-jarvis-template-app-sdk
```

#### Auto linking when using React Native >= 0.60

## Setup

---

### Android

Steps to setup in Android

#### 1. Register permissions and Service in `AndroidManifest.xml`.

Example:

```js
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          package="com.jarvisappsdktest">

  <!-- Require android phone supports Bluetooth Low Energy -->
  <uses-feature
    android:name="android.hardware.bluetooth_le"
    android:required="true" />

  <!-- Required permissions -->
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
  <uses-permission android:name="android.permission.BLUETOOTH" />
  <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
  <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />

  <application
    android:name=".MainApplication">
    <!-- Your code -->

    <!-- Register SDK service here -->
    <service
      android:name="com.reactnativejarvistemplateappsdk.services.BleScannerService"
      android:exported="false"
      android:foregroundServiceType="location|dataSync" />
  </application>
</manifest>
```

#### 2. Request permissions in your app

This is just example to request permissions at first access. You can build as you wish but just make sure all
the following permissions is allowed before using SDK

```tsx
function App() {

  const requestPermission = async (): Promise<void> => {
    if (Platform.Version >= 31) {
      if (!(await PermissionsAndroid.check(PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN))) {
        await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN,
          {
            title: 'Bluetooth Scan Permission',
            message: 'To Run SDK',
            buttonNeutral: 'Ask Me Later',
            buttonNegative: 'Cancel',
            buttonPositive: 'OK',
          },
        );
      }
    }

    if (!(await PermissionsAndroid.check(PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION))) {
      await PermissionsAndroid.request(
        PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
        {
          title: 'Access Fine Location',
          message: 'To Run SDK',
          buttonNeutral: 'Ask Me Later',
          buttonNegative: 'Cancel',
          buttonPositive: 'OK',
        },
      );
    }

    if (!(await PermissionsAndroid.check(PermissionsAndroid.PERMISSIONS.ACCESS_COARSE_LOCATION))) {
      await PermissionsAndroid.request(
        PermissionsAndroid.PERMISSIONS.ACCESS_COARSE_LOCATION,
        {
          title: 'Access Coarse Location',
          message: 'To Run SDK',
          buttonNeutral: 'Ask Me Later',
          buttonNegative: 'Cancel',
          buttonPositive: 'OK',
        },
      );
    }

    if (!(await PermissionsAndroid.check(PermissionsAndroid.PERMISSIONS.ACCESS_BACKGROUND_LOCATION))) {
      await PermissionsAndroid.request(
        PermissionsAndroid.PERMISSIONS.ACCESS_BACKGROUND_LOCATION,
        {
          title: 'Access Background Location',
          message: 'To Run SDK',
          buttonNeutral: 'Ask Me Later',
          buttonNegative: 'Cancel',
          buttonPositive: 'OK',
        },
      );
    }
  };

  useEffect(() => {
    requestPermission();
  }, []);

  return (
    <SafeAreaView style={backgroundStyle}>
      /* Your Code Here */
    </SafeAreaView>
  )
}
```

#### 3. Start and Stop SDK

How to run SDK service:

```tsx
// import sdk functions
import {
  startScanService,
  stopScanService,
} from 'react-native-jarvis-template-app-sdk';

function App() {

  const startJarvisSdk = async (): Promise<void> => {
    // please check all permissions allowed before start sdk
    // for example:
    const locGranted = await PermissionsAndroid.check(
      PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
    );
    if (!locGranted) {
      return;
    }

    // Get SDK Key from your Jarvis Account
    // Note:
    // Don't expose your sdk key in the code as below. This is just example.
    // Retrieve it through your own api instead
    const SDK_KEY = 'xxx';

    // SDK configuration
    const locatingRange = 3;
    const notificationIconFileName = 'ic_launcher_round';
    const foregroundServiceNotificationTitle = 'Jarvis SDK';
    const foregroundServiceNotificationDescription = 'We are running foreground service...';

    // startScanService to start sdk service in foreground
    const success = await startScanService(
      SDK_KEY,
      locatingRange,
      notificationIconFileName,
      foregroundServiceNotificationTitle,
      foregroundServiceNotificationDescription,
    );

    console.log('startJarvisSdk', success);
  };

  const stopJarvisSdk = async (): Promise<void> => {
    // stopScanService to stop foreground service
    await stopScanService();
  };

  return (
    <SafeAreaView style={backgroundStyle}>
      <Button title="START" onPress={startJarvisSdk} />
      <Button title="STOP" onPress={stopJarvisSdk} />
    </SafeAreaView>
  )
}
```

## Methods

---

### startScanService(sdkKey, locatingRange, notificationIconResourceName, notificationTitle, notificationDescription)

To start sdk service in foreground. It will start only one service task in foreground even when you trigger this method multiple times.

#### Arguments

- `sdkKey` : `string` | Your account SDK Key
- `locatingRange` : `number` | Range threshold for locating beacon. If you set 3, it means only detect beacon within 3 meters
- `notificationIconResourceName` : `string` | Name of resource file for Foreground Notification Icon. The icon should be under mipmap type.
- `notificationTitle` : `string` | Set title for Foreground Notification
- `notificationDescription` : `string` | Set description for Foreground Notification

### stopScanService

To stop the running sdk service when no use.

Please remember to stop it when no longer use otherwise it causes your battery drain.


## License

---

MIT

