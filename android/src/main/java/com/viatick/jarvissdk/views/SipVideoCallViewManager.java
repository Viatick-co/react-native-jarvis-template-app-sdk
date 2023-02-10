package com.viatick.jarvissdk.views;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;

public class SipVideoCallViewManager extends SimpleViewManager<MainVideoCallView> {

  ReactApplicationContext context;

  private static MainVideoCallView videoCallView;

  public SipVideoCallViewManager(ReactApplicationContext reactContext) {
    this.context = reactContext;
  }

  @NonNull
  @Override
  public String getName() {
    return "SipVideoCallPreview";
  }

  @NonNull
  @Override
  protected MainVideoCallView createViewInstance(@NonNull ThemedReactContext reactContext) {
    videoCallView = new MainVideoCallView(reactContext);
    return videoCallView;
  }

  public static MainVideoCallView getVideoCallView() {
    return videoCallView;
  }

}
