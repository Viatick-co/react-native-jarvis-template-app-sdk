package com.reactnativejarvistemplateappsdk;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.module.annotations.ReactModule;
import com.reactnativejarvistemplateappsdk.services.BleScannerService;

import java.util.ArrayList;
import java.util.List;

@ReactModule(name = JarvisTemplateAppSdkModule.NAME)
public class JarvisTemplateAppSdkModule extends ReactContextBaseJavaModule {
  public static final String NAME = "JarvisTemplateAppSdk";

  public JarvisTemplateAppSdkModule(ReactApplicationContext reactContext) {
    super(reactContext);
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
          BleScannerService.setDelegate(promise::resolve);

          Context reactContext = this.getReactApplicationContext();
          String iconPackage = reactContext.getPackageName();
          final int iconInt = reactContext.getResources().getIdentifier(notificationIconName, "mipmap", iconPackage);

          Intent viaBeaconIntent = new Intent(activity, BleScannerService.class);
          viaBeaconIntent.putExtra("sdkKey", sdkKey);
          viaBeaconIntent.putExtra("locatingRange", range);
          viaBeaconIntent.putExtra("notificationIconResourceId", iconInt);
          viaBeaconIntent.putExtra("notificationTitle", notificationTitle);
          viaBeaconIntent.putExtra("notificationDescription", notificationDescription);

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

}
