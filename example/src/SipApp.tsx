/* eslint-disable react-native/no-inline-styles */
import React, { useState, useEffect } from 'react';

import {
  PermissionsAndroid,
  Platform,
  SafeAreaView,
  useColorScheme,
  View,
  Text,
  TouchableOpacity,
} from 'react-native';
import {
  answerIncomingCall,
  initSipApplication,
  SipCallState,
  SipRegistrationState,
  SipVideoCallPreview,
  toggleMute,
  toggleSpeaker,
  toggleVideo,
  toggleCamera,
} from 'react-native-jarvis-template-app-sdk';
import { Colors } from 'react-native/Libraries/NewAppScreen';

export default function App() {
  const isDarkMode = useColorScheme() === 'dark';

  const [muted, setMuted] = useState(false);
  const [speaker, setSpeaker] = useState(false);

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
    console.log('JS: onSipAccStateChange', state);
  };

  const onSipCallStateChange = (state: SipCallState, address: string): void => {
    console.log('JS: onSipCallStateChange', state, address);
    console.log('Address ', address);
    if (state === SipCallState.IncomingReceived) {
      console.log('Incoming Received');

      setTimeout(() => {
        console.log('Incoming Received Asnwering');
        answerIncomingCall();
      }, 3000);
    }
  };

  // const stopJarvisSdk = async (): Promise<void> => {
  //   stopSipApplication();
  // };

  useEffect(() => {
    requestPermission().then(async () => {
      console.log('requested');
    });
  }, []);

  useEffect(() => {
    const getStart = async (): Promise<void> => {
      const initResult = await initSipApplication(
        '9004',
        '9004',
        onSipAccStateChange,
        onSipCallStateChange
      );
      console.log('111 : initResult', initResult);
    };
    getStart();
  }, []);

  const muteHandler = () => {
    toggleMute();
    setMuted(!muted);
  };

  const speakerHandler = () => {
    toggleSpeaker();
    setSpeaker(!speaker);
  };

  const videoHandler = () => {
    toggleVideo();
  };

  const cameraHandler = () => {
    toggleCamera();
  };

  return (
    <SafeAreaView style={backgroundStyle}>
      <View style={{ flex: 1 }}>
        <SipVideoCallPreview style={{ flex: 1 }} />
        <View
          style={{
            flexDirection: 'row',
            justifyContent: 'space-around',
            marginVertical: 10,
            marginHorizontal: 10,
          }}
        >
          <TouchableOpacity
            style={{
              paddingHorizontal: 10,
              paddingVertical: 10,
              backgroundColor: '#000',
              alignItems: 'center',
              borderRadius: 10,
            }}
            onPress={videoHandler}
          >
            <Text
              style={{
                color: '#fff',
              }}
            >
              Toggle Video
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={{
              paddingHorizontal: 10,
              paddingVertical: 10,
              backgroundColor: '#000',
              alignItems: 'center',
              borderRadius: 10,
            }}
            onPress={cameraHandler}
          >
            <Text
              style={{
                color: '#fff',
              }}
            >
              Toggle Camera
            </Text>
          </TouchableOpacity>
        </View>

        <View
          style={{
            flexDirection: 'row',
            justifyContent: 'space-around',
            marginVertical: 10,
            marginHorizontal: 10,
          }}
        >
          <TouchableOpacity
            style={{
              paddingHorizontal: 10,
              paddingVertical: 10,
              backgroundColor: '#000',
              alignItems: 'center',
              borderRadius: 10,
            }}
            onPress={muteHandler}
          >
            <Text
              style={{
                color: '#fff',
              }}
            >
              Toggle Mute
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={{
              paddingHorizontal: 10,
              paddingVertical: 10,
              backgroundColor: '#000',
              alignItems: 'center',
              borderRadius: 10,
            }}
            onPress={speakerHandler}
          >
            <Text
              style={{
                color: '#fff',
              }}
            >
              Toggle Speaker
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    </SafeAreaView>
  );
}
