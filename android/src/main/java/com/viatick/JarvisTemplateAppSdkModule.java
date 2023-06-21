package com.viatick;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.viatick.jarvissdk.model.PeripheralDetail;
import com.viatick.jarvissdk.services.BleScannerService;
import com.viatick.jarvissdk.services.BleScannerServiceCallback;
import com.viatick.jarvissdk.sip.SipAppStateListener;
import com.viatick.jarvissdk.sip.SipApplication;

import org.linphone.core.Call;
import org.linphone.core.RegistrationState;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

@ReactModule(name = JarvisTemplateAppSdkModule.NAME)
public class JarvisTemplateAppSdkModule extends ReactContextBaseJavaModule {
  public static final String NAME = "JarvisTemplateAppSdk";

  private final SipAppStateListener sipAppStateListener = new SipAppStateListener() {
    @Override
    public void onAccountRegistrationStateChanged(RegistrationState state) {
      WritableMap eventBody = Arguments.createMap();
      eventBody.putInt("state", state.toInt());

      getReactApplicationContext().getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
        .emit("SipAppAccountState", eventBody);
    }

    @Override
    public void onCallStateChanged(Call.State callState, String remoteAddress) {
      WritableMap eventBody = Arguments.createMap();
      eventBody.putInt("state", callState.toInt());
      eventBody.putString("remoteAddress", remoteAddress);

      getReactApplicationContext().getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
        .emit("SipCallState", eventBody);
    }
  };

  public JarvisTemplateAppSdkModule(ReactApplicationContext reactContext) {
    super(reactContext);
  }

  private void sendEvent(String eventName,
                         @Nullable WritableMap params) {
    getReactApplicationContext()
      .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
      .emit(eventName, params);
  }


  @Override
  @NonNull
  public String getName() {
    return NAME;
  }

  // Example method
  // See https://reactnative.dev/docs/native-modules-android
  @ReactMethod
  public void multiply(double a, double b, Promise promise) {
//    this.getReactApplicationContext().getResources().getIdentifier();
    promise.resolve(a * b);
  }

  @ReactMethod
  public void startScanService(
    String sdkKey,
    int range,
    String notificationIconName,
    String notificationTitle,
    String notificationDescription,
    final Promise promise
  ) {
    List<String> permissions = new ArrayList<>();
    permissions.add(Manifest.permission.ACCESS_FINE_LOCATION);
    permissions.add(Manifest.permission.ACCESS_COARSE_LOCATION);
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      permissions.add(Manifest.permission.ACCESS_BACKGROUND_LOCATION);
    }

    permissions.add(Manifest.permission.BLUETOOTH);
    permissions.add(Manifest.permission.BLUETOOTH_ADMIN);
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      permissions.add(Manifest.permission.BLUETOOTH_SCAN);
    }

    boolean allPermitted = true;
    Activity activity = this.getCurrentActivity();
    for (String permission : permissions) {
      if (ContextCompat.checkSelfPermission(activity, permission) != PackageManager.PERMISSION_GRANTED) {
        allPermitted = false;
        break;
      }
    }

    try {
      if (allPermitted) {
        Log.d("JarvisSdkModule", "BleScannerService Running " + BleScannerService.isRunning());
        if (!BleScannerService.isRunning()) {
          BleScannerService.setDelegate(new BleScannerServiceCallback() {
            @Override
            public void onStarted(boolean success) {
              promise.resolve(success);
            }

            @Override
            public void onProximityPush(PeripheralDetail ble, String notificationTitle, String notificationDescription, long dateTime) {
              WritableMap eventBody = Arguments.createMap();

              eventBody.putString("uuid", ble.getUuid());
              eventBody.putInt("major", ble.getMajor());
              eventBody.putInt("minor", ble.getMinor());
              eventBody.putString("title", notificationTitle);
              eventBody.putString("description", notificationDescription);
              eventBody.putDouble("time", dateTime);

              sendEvent("BeaconInformation", eventBody);
            }

            @Override
            public void onGpsFound(PeripheralDetail ble, String lat, String lng, long dateTime) {
              WritableMap eventBody = Arguments.createMap();

              eventBody.putString("uuid", ble.getUuid());
              eventBody.putInt("major", ble.getMajor());
              eventBody.putInt("minor", ble.getMinor());
              eventBody.putDouble("time", dateTime);
              eventBody.putString("userId", ble.getPersonnelId());
              eventBody.putString("lat", lat);
              eventBody.putString("lng", lng);

              sendEvent("GpsInformation", eventBody);
            }

            @Override
            public void onDestroyed() {
            }
          });

          Context reactContext = this.getReactApplicationContext();
          String iconPackage = reactContext.getPackageName();
          final int iconInt = reactContext.getResources().getIdentifier(notificationIconName, "mipmap", iconPackage);

          Intent viaBeaconIntent = new Intent(activity, BleScannerService.class);
          viaBeaconIntent.putExtra("sdkKey", sdkKey);
          viaBeaconIntent.putExtra("locatingRange", range);
          viaBeaconIntent.putExtra("notificationIconResourceId", iconInt);
          viaBeaconIntent.putExtra("notificationTitle", notificationTitle);
          viaBeaconIntent.putExtra("notificationDescription", notificationDescription);
          viaBeaconIntent.putExtra("servicePushNotificationEnabled", true);
          viaBeaconIntent.putExtra("serviceLocatingEnabled", false);

          if (Build.VERSION.SDK_INT >= 26) {
            Log.d("JarvisSdkModule", "startForegroundService");
            activity.startForegroundService(viaBeaconIntent);
          } else {
            Log.d("JarvisSdkModule", "startService");
            activity.startService(viaBeaconIntent);
          }
        } else {
          promise.resolve(true);
        }

        return;
      }
    } catch (Exception ignored) {
    }
    promise.resolve(false);
  }

  @ReactMethod
  public void stopScanService() {
    Activity activity = this.getCurrentActivity();

    if (activity != null) {
      Intent viaBeaconIntent = new Intent(activity, BleScannerService.class);
      Log.d("JarvisSdkModule", "stopService");
      activity.stopService(viaBeaconIntent);
    }
  }

  @ReactMethod
  public void getScanServiceStatus(final Promise promise) {
    Log.d("SdkModule", "getScanServiceStatus called");
    long lastSignalDateTime = BleScannerService.getLastBleFoundDateTime();
    boolean running = BleScannerService.isRunning();
    Collection<PeripheralDetail> beacons = BleScannerService.getListBeacons();

    WritableMap eventBody = Arguments.createMap();
    eventBody.putDouble("lastDetectedSignalDateTime", lastSignalDateTime);
    eventBody.putBoolean("serviceRunning", running);

    WritableArray beaconArray = new WritableNativeArray();
    for (PeripheralDetail beacon : beacons) {
      beaconArray.pushMap(beacon.toWritableMap());
    }
    eventBody.putArray("beacons", beaconArray);

    promise.resolve(eventBody);
  }

  @ReactMethod
  public void startLocatingService(
    String sdkKey,
    int range,
    String notificationIconName,
    String notificationTitle,
    String notificationDescription,
    final Promise promise
  ) {
    List<String> permissions = new ArrayList<>();
    permissions.add(Manifest.permission.ACCESS_FINE_LOCATION);
    permissions.add(Manifest.permission.ACCESS_COARSE_LOCATION);
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      permissions.add(Manifest.permission.ACCESS_BACKGROUND_LOCATION);
    }

    permissions.add(Manifest.permission.BLUETOOTH);
    permissions.add(Manifest.permission.BLUETOOTH_ADMIN);
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      permissions.add(Manifest.permission.BLUETOOTH_SCAN);
    }

    boolean allPermitted = true;
    Activity activity = this.getCurrentActivity();
    for (String permission : permissions) {
      if (ContextCompat.checkSelfPermission(activity, permission) != PackageManager.PERMISSION_GRANTED) {
        allPermitted = false;
        break;
      }
    }

    try {
      if (allPermitted) {
        Log.d("JarvisSdkModule", "BleScannerService Running " + BleScannerService.isRunning());
        if (!BleScannerService.isRunning()) {
          BleScannerService.setDelegate(new BleScannerServiceCallback() {
            @Override
            public void onStarted(boolean success) {
              promise.resolve(success);
            }

            @Override
            public void onProximityPush(PeripheralDetail ble, String notificationTitle, String notificationDescription, long dateTime) {
              WritableMap eventBody = Arguments.createMap();

              eventBody.putString("uuid", ble.getUuid());
              eventBody.putInt("major", ble.getMajor());
              eventBody.putInt("minor", ble.getMinor());
              eventBody.putString("title", notificationTitle);
              eventBody.putString("description", notificationDescription);
              eventBody.putDouble("time", dateTime);
              sendEvent("BeaconInformation", eventBody);

            }

            @Override
            public void onGpsFound(PeripheralDetail ble, String lat, String lng, long dateTime) {
              WritableMap eventBody = Arguments.createMap();

              eventBody.putString("uuid", ble.getUuid());
              eventBody.putInt("major", ble.getMajor());
              eventBody.putInt("minor", ble.getMinor());
              eventBody.putDouble("time", dateTime);
              eventBody.putString("userId", ble.getPersonnelId());
              eventBody.putString("lat", lat);
              eventBody.putString("lng", lng);
              sendEvent("GpsInformation", eventBody);
            }

            @Override
            public void onDestroyed() {
            }
          });

          Context reactContext = this.getReactApplicationContext();
          String iconPackage = reactContext.getPackageName();
          final int iconInt = reactContext.getResources().getIdentifier(notificationIconName, "mipmap", iconPackage);

          Intent viaBeaconIntent = new Intent(activity, BleScannerService.class);
          viaBeaconIntent.putExtra("sdkKey", sdkKey);
          viaBeaconIntent.putExtra("locatingRange", range);
          viaBeaconIntent.putExtra("notificationIconResourceId", iconInt);
          viaBeaconIntent.putExtra("notificationTitle", notificationTitle);
          viaBeaconIntent.putExtra("notificationDescription", notificationDescription);
          viaBeaconIntent.putExtra("servicePushNotificationEnabled", false);
          viaBeaconIntent.putExtra("serviceLocatingEnabled", true);

          if (Build.VERSION.SDK_INT >= 26) {
            activity.startForegroundService(viaBeaconIntent);
          } else {
            activity.startService(viaBeaconIntent);
          }
        } else {
          promise.resolve(true);
        }

        return;
      }
    } catch (Exception ignored) {
    }
    promise.resolve(false);
  }

  @ReactMethod
  public void stopLocatingService() {
    Activity activity = this.getCurrentActivity();

    if (activity != null) {
      Intent viaBeaconIntent = new Intent(activity, BleScannerService.class);
      activity.stopService(viaBeaconIntent);
    }
  }

  @ReactMethod
  public void initSipApplication(
    String username,
    String password,
    final Promise promise
  ) {
    SipApplication.initApp(
      this.getCurrentActivity(),
      username,
      password,
      this.sipAppStateListener,
      (success, errorCode) -> {
        Log.d("IntercomSDK", "initSipApplication response");

        WritableMap resultBody = Arguments.createMap();
        resultBody.putBoolean("success", success);
        resultBody.putInt("errorCode", errorCode.ordinal());
        promise.resolve(resultBody);
      }
    );
  }

  @ReactMethod
  public void stopSipApplication() {
    SipApplication.destroySdk();
  }

  @ReactMethod
  public void answerIncomingCall() {
    SipApplication.answerIncomingCall();
  }

  @ReactMethod
  public void rejectIncomingCall() {
    SipApplication.rejectIncomingCall();
  }

  @ReactMethod
  public void toggleMute() {
    SipApplication.toggleMute();
  }

  @ReactMethod
  public void toggleSpeaker() {
    SipApplication.toggleSpeaker();
  }

  @ReactMethod
  public void toggleVideo() {
    SipApplication.toggleVideo();
  }

  @ReactMethod
  public void toggleCamera() {
    SipApplication.toggleCamera();
  }

  // Required for rn built in EventEmitter Calls.
  @ReactMethod
  public void addListener(String eventName) {
  }

  @ReactMethod
  public void removeListeners(Integer count) {
  }

}
