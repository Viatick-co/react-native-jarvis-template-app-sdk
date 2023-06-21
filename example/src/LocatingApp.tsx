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
  Modal,
} from 'react-native';
import {
  startLocatingService,
  stopLocatingService,
  BeaconInfo,
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

type GpsInfoType = {
  device: BeaconInfo;
  userId: string;
  lat: string;
  lng: string;
  time: string;
};

export default function App() {
  const isDarkMode = useColorScheme() === 'dark';

  const [gpsInfo, setGpsInfo] = React.useState<GpsInfoType>();

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
          PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT!
        ))
      ) {
        await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT!,
          {
            title: 'Access Bluetooth connect',
            message: 'To Scan BLE',
            buttonNeutral: 'Ask Me Later',
            buttonNegative: 'Cancel',
            buttonPositive: 'OK',
          }
        );
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
    } else {
      // if running ios
      // make sure your user set always allow location to allow app can run in background
    }
  };

  const onGpsFound = (
    device: BeaconInfo,
    userId: string,
    lat: string,
    lng: string,
    time: string
  ) => {
    setGpsInfo({ device, userId, lat, lng, time });
  };

  const startJarvisSdk = async (): Promise<void> => {
    const success = await startLocatingService(
      SDK_KEY,
      3,
      'ic_launcher_round',
      'Jarvis Example',
      'We are running foreground service...',
      onGpsFound
    );
    console.log('startJarvisSdk', success);
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
              <Button title="STOP" onPress={stopLocatingService} />
            </View>
            <View style={{ flex: 0.33, padding: 10 }}>
              <Button title="STATUS" />
            </View>
          </View>
        </View>
      </ScrollView>
      {gpsInfo?.device && (
        <Modal
          visible={true}
          transparent={true}
          onRequestClose={() => {
            setGpsInfo(null);
          }}
        >
          <View style={styles.container}>
            <View style={styles.modalBox}>
              <Text style={styles.title}>New Device Detected</Text>
              <View style={styles.row}>
                <Text style={styles.label}>UUID :</Text>
                <Text style={styles.value}>
                  {gpsInfo?.device?.uuid ?? 'N/A'}
                </Text>
              </View>
              <View style={styles.row}>
                <Text style={styles.label}>Major - Minor :</Text>
                <Text style={styles.value}>{`${
                  gpsInfo?.device?.major ?? 'N/A'
                } - ${gpsInfo?.device?.minor ?? 'N/A'}`}</Text>
              </View>
              <View style={styles.row}>
                <Text style={styles.label}>User Id :</Text>
                <Text style={styles.value}>{gpsInfo?.userId ?? 'N/A'}</Text>
              </View>
              <View style={styles.row}>
                <Text style={styles.label}>Location :</Text>
                <Text style={styles.value}>
                  {gpsInfo?.lat ?? 'N/A'}, {gpsInfo?.lng ?? 'N/A'}
                </Text>
              </View>
            </View>
          </View>
        </Modal>
      )}
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
  container: {
    backgroundColor: 'rgba(0,0,0,0.6)',
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalBox: {
    width: '94%',
    backgroundColor: '#fff',
    overflow: 'hidden',
    borderRadius: 10,
    padding: 20,
    paddingTop: 15,
    alignItems: 'center',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingBottom: 5,
  },
  label: {
    fontSize: 14,
    color: 'darkgray',
    width: '40%',
  },
  value: {
    fontSize: 15,
    color: '#000',
    fontWeight: '600',
    width: '60%',
  },
  title: {
    fontSize: 17,
    fontWeight: '600',
    paddingBottom: 13,
  },
});
