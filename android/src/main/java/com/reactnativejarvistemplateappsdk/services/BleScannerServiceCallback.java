package com.reactnativejarvistemplateappsdk.services;

import androidx.annotation.Nullable;
import com.facebook.react.bridge.WritableMap;

public interface BleScannerServiceCallback {

  void onStarted(boolean success);

  void onProximityPush(@Nullable WritableMap eventBody);
}
