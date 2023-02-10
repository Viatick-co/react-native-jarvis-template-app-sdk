import * as React from 'react';

import {
  PermissionsAndroid,
  Platform,
  SafeAreaView,
  useColorScheme,
  View,
} from 'react-native';
import {
  answerIncomingCall,
  initSipApplication,
  SipCallState,
  SipRegistrationState,
  SipVideoCallPreview,
  stopSipApplication,
} from 'react-native-jarvis-template-app-sdk';
import { Colors } from 'react-native/Libraries/NewAppScreen';
import { useState } from 'react';

export default function App() {
  const [newCall, setNewcall] = useState(false);

  const isDarkMode = useColorScheme() === 'dark';

  const backgroundStyle = {
    backgroundColor: isDarkMode ? Colors.darker : Colors.lighter,
    flex: 1,
  };

  const requestPermission = async (): Promise<void> => {
    if (Platform.OS === 'android') {
      if (
        !(await PermissionsAndroid.check(
          PermissionsAndroid.PERMISSIONS.RECORD_AUDIO!
        ))
      ) {
        await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.RECORD_AUDIO!,
          {
            title: 'Access Record Video',
            message: 'To Video Call',
            buttonNeutral: 'Ask Me Later',
            buttonNegative: 'Cancel',
            buttonPositive: 'OK',
          }
        );
      }

      if (
        !(await PermissionsAndroid.check(
          PermissionsAndroid.PERMISSIONS.CAMERA!
        ))
      ) {
        await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.CAMERA!,
          {
            title: 'Access Camera',
            message: 'To Video Call',
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

  const onSipAccStateChange = (state: SipRegistrationState): void => {
    console.log('onSipAccStateChange', state);
  };

  const onSipCallStateChange = (state: SipCallState): void => {
    console.log('onSipCallStateChange', state);
    if (state === SipCallState.IncomingReceived) {
      console.log('Incoming Received');
      setNewcall(true);

      setTimeout(() => {
        console.log('Incoming Received Asnwering');
        answerIncomingCall();
      }, 3000);
    } else {
      setNewcall(false);
    }
  };

  const stopJarvisSdk = async (): Promise<void> => {
    stopSipApplication();
  };

  React.useEffect(() => {
    requestPermission().then(async () => {
      const cameraGranted = await PermissionsAndroid.check(
        PermissionsAndroid.PERMISSIONS.CAMERA!
      );
      const recordAudioGranted = await PermissionsAndroid.check(
        PermissionsAndroid.PERMISSIONS.RECORD_AUDIO!
      );
      console.log('granted', cameraGranted, recordAudioGranted);
      if (cameraGranted && recordAudioGranted) {
        const initResult = await initSipApplication(
          '7001',
          '7001',
          onSipAccStateChange,
          onSipCallStateChange
        );
        console.log('initResult', initResult);
      }
    });
  }, []);

  // @ts-ignore
  return (
    <SafeAreaView style={backgroundStyle}>
      <View style={{ flex: 1, backgroundColor: 'green' }}>
        <SipVideoCallPreview style={{ flex: 1 }} />
      </View>
    </SafeAreaView>
  );
}
