package com.viatick.jarvissdk.views;

import android.content.Context;
import android.graphics.Color;
import android.util.DisplayMetrics;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;

import androidx.annotation.NonNull;

import com.facebook.react.uimanager.ThemedReactContext;

import org.linphone.mediastream.video.capture.CaptureTextureView;

public class MainVideoCallView extends RelativeLayout {

  private final TextureView remoteVideoSurface;
  private final CaptureTextureView localPreviewVideoSurface;

  public MainVideoCallView(@NonNull Context context) {
    super(context);

    this.setBackgroundColor(Color.parseColor("#5FD3F3"));

    LayoutParams remoteVideoLayoutParams = new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
    remoteVideoLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_TOP);

    this.remoteVideoSurface = new TextureView(context);
    this.remoteVideoSurface.setLayoutParams(remoteVideoLayoutParams);

    DisplayMetrics displayMetrics = new DisplayMetrics();
    ((ThemedReactContext) context).getCurrentActivity().getWindowManager().getDefaultDisplay().getMetrics(displayMetrics);
    int parentWidth = displayMetrics.widthPixels;

//    LayoutParams localVideoLayoutParams = new LayoutParams(parentWidth / 3, LayoutParams.WRAP_CONTENT);
    LayoutParams localVideoLayoutParams = new LayoutParams(0, 0);
    localVideoLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT);
    localVideoLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
    localVideoLayoutParams.setMargins(0, 0, 20, 20);

    this.localPreviewVideoSurface = new CaptureTextureView(context);
    this.localPreviewVideoSurface.setLayoutParams(localVideoLayoutParams);

    this.addView(this.remoteVideoSurface);
    this.addView(this.localPreviewVideoSurface);
  }

  public TextureView getRemoteVideoSurface() {
    return remoteVideoSurface;
  }

  public CaptureTextureView getLocalPreviewVideoSurface() {
    return localPreviewVideoSurface;
  }

}
