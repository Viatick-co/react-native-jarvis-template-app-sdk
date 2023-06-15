package com.viatick.jarvissdk.services;

import androidx.annotation.Nullable;

import com.facebook.react.bridge.WritableMap;

public interface GpsLocatingServiceCallback {

  void onStarted(boolean success);

  void onDestroyed();

}
