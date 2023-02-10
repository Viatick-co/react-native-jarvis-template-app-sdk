package com.viatick.jarvissdk.services;

import androidx.annotation.Nullable;
import com.facebook.react.bridge.WritableMap;

public interface BleScannerServiceCallback {

  void onStarted(boolean success);

  void onProximityPush(@Nullable WritableMap eventBody);

  void onDestroyed();

}
