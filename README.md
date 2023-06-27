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
      android:name="com.viatick.jarvissdk.services.GpsLocatingService"
      android:exported="false"
      android:foregroundServiceType="location|dataSync" />

    <service
      android:name="com.viatick.jarvissdk.services.BleScannerService"
      android:exported="false"
      android:foregroundServiceType="location|dataSync" />
  </application>
</manifest>
```

#### 2. Update android/app/build.gradle
under dependencies => insert
```gradle
dependencies {
 ...
 implementation 'org.linphone:linphone-sdk-android:5.0.71@aar'
 implementation 'androidx.media:media:1.6.0'
}
```

#### 3. Upadte android/build.gradle
Add this under allprojects/repositories

```gradle
allprojects {
  repositories {
    ...

    maven {
      url "https://linphone.org/maven_repository"
    }
  }
 }
```

### iOs

Steps to setup in iOs

#### 1. Insert linphone-sdk.podspec file under project folder

please get the file from example/linphone-sdk.podspec

#### 2. Update Podfile under ios/Podfile
- Add `pod 'linphone-sdk', :podspec => "../linphone-sdk.podspec"` under target
- Comment `use_flipper!()` if existing, to disable

Example

```Podfile
target 'JarvisTemplateAppSdkExample' do
  ...
  pod 'react-native-jarvis-template-app-sdk', :path => '../..'
  pod 'linphone-sdk', :podspec => "../linphone-sdk.podspec"

  #use_flipper!()
  ...
end
```

#### 3. Run pod install again under ios folder
`pod install`

#### 4. If facing below error when run
Error `folly/portability/Config.h` file not found, then let remove that line from the file

## Request permissions in your app

1. This is just example to request permissions at first access. You can build as you wish but just make sure all
the following permissions is allowed before using SDK

2. Please make sure Bluetooth and Location is enabled


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

Second, it requires internet connected, please handle it at your side before call `startScanService`

Finally, make sure bluetooth service is enabled, please handle it at your side before call `startScanService`

## Start and Stop SDK

How to run SDK service:

- Ble Push Notification: please check example/src/App.tsx
- Gps Locating: please check example/src/LocatingApp.tx

## Methods

---

### startScanService(sdkKey, locatingRange, notificationIconResourceName, notificationTitle, notificationDescription, onProximityPush)

To start sdk service in foreground. It will start only one service task in foreground even when you trigger this method multiple times.

#### Arguments

- `sdkKey` : `string` | Your account SDK Key
- `locatingRange` : `number` | Range threshold for locating beacon. If you set 3, it means only detect beacon within 3 meters
- `notificationIconResourceName` : `string` | Name of resource file for Foreground Notification Icon. The icon should be under mipmap type.
- `notificationTitle` : `string` | Set title for Foreground Notification
- `notificationDescription` : `string` | Set description for Foreground Notification
- `onProximityPush` : `(device: BeaconInfo, noti: NotificationInfo, time: string) => {}` | Callback method for proximity push

### stopScanService

To stop the running sdk ble push notification service when no use.

Please remember to stop it when no longer use otherwise it causes your battery drain.

### startLocatingService(sdkKey, locatingRange, notificationIconResourceName, notificationTitle, notificationDescription, onFound)

To start sdk service in foreground. It will start only one service task in foreground even when you trigger this method multiple times.

#### Arguments

- `sdkKey` : `string` | Your account SDK Key
- `locatingRange` : `number` | Range threshold for locating beacon. If you set 3, it means only detect beacon within 3 meters
- `notificationIconResourceName` : `string` | Name of resource file for Foreground Notification Icon. The icon should be under mipmap type.
- `notificationTitle` : `string` | Set title for Foreground Notification
- `notificationDescription` : `string` | Set description for Foreground Notification
- `onProximityPush` : `(device: BeaconInfo, userId: string, lat: string, lng: string, time: string) => {}` | Callback method for proximity push

### stopLocatingService

To stop the running sdk gps locating service when no use.

Please remember to stop it when no longer use otherwise it causes your battery drain.

### getServiceStatus()

To retrieve all current information from running service

#### Response
```tsx
type JarvisServiceStatus = {
  lastDetectedSignalDateTime: number;
  serviceRunning: boolean;
  beacons: ServiceBeaconInfo[];
};
```

- `lastDetectedSignalDateTime`: timestamp when running service get last signal from any devices found nearby inside locating range
- `serviceRunning`: flag to know whether service is still running in background
- `beacons`: list of devices found and notified and still received readings, when you are out of locating range for 1 minute, the device will be removed from the list

## License

---

MIT

