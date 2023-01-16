import * as React from 'react';

import {
  StyleSheet,
  View,
  Text,
  useColorScheme,
  SafeAreaView,
  Platform,
  PermissionsAndroid,
  StatusBar,
  ScrollView,
  Button,
} from 'react-native';
import {
  startScanService,
  stopScanService,
  getServiceStatus,
  BeaconInfo,
  NotifcationInfo,
} from 'react-native-jarvis-template-app-sdk';
import { Colors } from 'react-native/Libraries/NewAppScreen';

import LearnMoreLinkList from './LearnMoreLinkList';
import Header from './Header';

// PLEASE DON'T EXPOSE SDK KEY AS BELOW. THIS IS JUST FOR EXAMPLE.
// MAKE SURE YOU GET SDK_KEY THROUGH YOUR OWN API WHICH REQUIRES AUTHENTICATION
const SDK_KEY = 'xxx';

const Section: React.FC<
  React.PropsWithChildren<{
    title: string;
  }>
> = ({ children, title }) => {
  const isDarkMode = useColorScheme() === 'dark';
  return (
    <View style={styles.sectionContainer}>
      <Text
        style={[
          styles.sectionTitle,
          { color: isDarkMode ? Colors.white : Colors.black },
        ]}
      >
        {title}
      </Text>
      <Text
        style={[
          styles.sectionDescription,
          { color: isDarkMode ? Colors.light : Colors.dark },
        ]}
      >
        {children}
      </Text>
    </View>
  );
};

export default function App() {
  const isDarkMode = useColorScheme() === 'dark';

  const backgroundStyle = {
    backgroundColor: isDarkMode ? Colors.darker : Colors.lighter,
  };

  const requestPermission = async (): Promise<void> => {
    if (Platform.OS === 'android') {
      if (Platform.Version >= 31) {
        const bleScanGranted = await PermissionsAndroid.check(
          PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN!
        );
        if (!bleScanGranted) {
          await PermissionsAndroid.request(
            PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN!,
            {
              title: 'Bluetooth Scan Permission',
              message: 'To Scan BLE',
              buttonNeutral: 'Ask Me Later',
              buttonNegative: 'Cancel',
              buttonPositive: 'OK',
            }
          );
        }
      }

      if (
        !(await PermissionsAndroid.check(
          PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION!
        ))
      ) {
        await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION!,
          {
            title: 'Access Fine Location',
            message: 'To Scan BLE',
            buttonNeutral: 'Ask Me Later',
            buttonNegative: 'Cancel',
            buttonPositive: 'OK',
          }
        );
      }

      if (
        !(await PermissionsAndroid.check(
          PermissionsAndroid.PERMISSIONS.ACCESS_COARSE_LOCATION!
        ))
      ) {
        await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.ACCESS_COARSE_LOCATION!,
          {
            title: 'Access Coarse Location',
            message: 'To Scan BLE',
            buttonNeutral: 'Ask Me Later',
            buttonNegative: 'Cancel',
            buttonPositive: 'OK',
          }
        );
      }

      if (
        !(await PermissionsAndroid.check(
          PermissionsAndroid.PERMISSIONS.ACCESS_BACKGROUND_LOCATION!
        ))
      ) {
        await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.ACCESS_BACKGROUND_LOCATION!,
          {
            title: 'Access Background Location',
            message: 'To Scan BLE',
            buttonNeutral: 'Ask Me Later',
            buttonNegative: 'Cancel',
            buttonPositive: 'OK',
          }
        );
      }

      const locgranted = await PermissionsAndroid.check(
        PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION!
      );
      console.log('ACCESS_FINE_LOCATION', locgranted);
      const blegranted = await PermissionsAndroid.check(
        PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN!
      );
      console.log('BLUETOOTH_SCAN', blegranted);
    } else {
      // if running ios
      // make sure your user set always allow location to allow app can run in background
    }
  };

  const onProximityPush = (
    device: BeaconInfo,
    noti: NotifcationInfo,
    time: string
  ) => {
    console.log(device, noti, time);
  };

  const startJarvisSdk = async (): Promise<void> => {
    const success = await startScanService(
      SDK_KEY,
      3,
      'ic_launcher_round',
      'Jarvis Example',
      'We are running foreground service...',
      onProximityPush
    );
    console.log('startJarvisSdk', success);
  };

  const getJarvisServiceStatus = async (): Promise<void> => {
    const status = await getServiceStatus();
    console.log('status', status);
  };

  React.useEffect(() => {
    requestPermission();
  }, []);

  return (
    <SafeAreaView style={backgroundStyle}>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      <ScrollView
        contentInsetAdjustmentBehavior="automatic"
        style={backgroundStyle}
      >
        <Header />
        <View
          style={{ backgroundColor: isDarkMode ? Colors.black : Colors.white }}
        >
          <Section title="Usage">
            Visit <Text style={styles.highlight}>App.tsx</Text> in folder{' '}
            <Text style={styles.highlight}>example</Text> to see example code
          </Section>
          <Section title="Learn More">
            Read the <Text style={styles.highlight}>README</Text> to discover
            all functions and it's prerequisite:
          </Section>
          <LearnMoreLinkList />
          <Section title="Example">
            Press Button <Text style={styles.highlight}>START</Text> or{' '}
            <Text style={styles.highlight}>STOP</Text> to start and stop SDK
          </Section>

          <View style={{ flexDirection: 'row', padding: 10 }}>
            <View style={{ flex: 0.33, padding: 10 }}>
              <Button title="START" onPress={startJarvisSdk} />
            </View>
            <View style={{ flex: 0.33, padding: 10 }}>
              <Button title="STOP" onPress={stopScanService} />
            </View>
            <View style={{ flex: 0.33, padding: 10 }}>
              <Button title="STATUS" onPress={getJarvisServiceStatus} />
            </View>
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  sectionContainer: {
    marginTop: 32,
    paddingHorizontal: 24,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '600',
  },
  sectionDescription: {
    marginTop: 8,
    fontSize: 18,
    fontWeight: '400',
  },
  highlight: { fontWeight: '700' },
});
