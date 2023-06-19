package com.viatick.jarvissdk.services;

import androidx.annotation.Nullable;
import com.facebook.react.bridge.WritableMap;
import com.viatick.jarvissdk.model.PeripheralDetail;

public interface BleScannerServiceCallback {

  void onStarted(boolean success);

  void onProximityPush(PeripheralDetail ble, String notificationTitle, String notificationDescription, long dateTime);

  void onGpsFound(PeripheralDetail ble, String lat, String lng, long dateTime);

  void onDestroyed();

}
