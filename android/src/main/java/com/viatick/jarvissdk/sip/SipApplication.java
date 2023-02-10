package com.viatick.jarvissdk.sip;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import com.viatick.jarvissdk.sip.data.SipAppInitError;
import com.viatick.jarvissdk.views.MainVideoCallView;
import com.viatick.jarvissdk.views.SipVideoCallViewManager;

import org.linphone.core.Account;
import org.linphone.core.AccountParams;
import org.linphone.core.Address;
import org.linphone.core.AuthInfo;
import org.linphone.core.Call;
import org.linphone.core.Core;
import org.linphone.core.CoreListenerStub;
import org.linphone.core.Factory;
import org.linphone.core.RegistrationState;
import org.linphone.core.TransportType;
import org.linphone.core.VideoActivationPolicy;

public class SipApplication {

  private final static String LOG_TAG = "IntercomSDK";
  private final static String SIP_DOMAIN = "168.138.190.154";

  private static Core sipCore;
  private static SipAppStateListener appStateListener;

  private static final CoreListenerStub coreListenerStub = new CoreListenerStub() {
    @Override
    public void onAccountRegistrationStateChanged(@NonNull Core core, @NonNull Account account, RegistrationState state, @NonNull String message) {
      super.onAccountRegistrationStateChanged(core, account, state, message);

      Log.d(LOG_TAG, "State " + state);
      if (appStateListener != null) {
        appStateListener.onAccountRegistrationStateChanged(state);
      }
    }

    @Override
    public void onCallStateChanged(@NonNull Core core, @NonNull Call call, Call.State state, @NonNull String message) {
      super.onCallStateChanged(core, call, state, message);

      Log.d(LOG_TAG, "Call " + state);
      if (appStateListener != null) {
        appStateListener.onCallStateChanged(state);
      }
    }
  };

  private static boolean checkPermission(Activity activity) {
    return ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED &&
      ContextCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED;
  }

  public static void initApp(
    Activity activity,
    String username,
    String password,
    SipAppStateListener stateListener,
    SipAppInitCallback initResult) {
    Log.d(LOG_TAG, "initApp called");

    if (sipCore != null) {
      initResult.onResult(false, SipAppInitError.ALREADY_INIT);
      return;
    }

    if (!checkPermission(activity)) {
      initResult.onResult(false, SipAppInitError.PERMISSION_NOT_GRANTED);
      return;
    }

    try {
      Factory sipFactory = Factory.instance();

      sipCore = sipFactory.createCore(null, null, activity);

      MainVideoCallView mainVideoCallView = SipVideoCallViewManager.getVideoCallView();
      // For video to work, we need two TextureViews:
      // one for the remote video and one for the local preview
      sipCore.setNativeVideoWindowId(mainVideoCallView.getRemoteVideoSurface());
      // The local preview is a org.linphone.mediastream.video.capture.CaptureTextureView
      // which inherits from TextureView and contains code to keep the ratio of the capture video
      sipCore.setNativePreviewWindowId(mainVideoCallView.getLocalPreviewVideoSurface());

      // Here we enable the video capture & display at Core level
      // It doesn't mean calls will be made with video automatically,
      // But it allows to use it later
      sipCore.enableVideoCapture(true);
      sipCore.enableVideoDisplay(true);

      VideoActivationPolicy policy = sipCore.getVideoActivationPolicy();
      policy.setAutomaticallyAccept(true);
      policy.setAutomaticallyInitiate(true);
      sipCore.setVideoActivationPolicy(policy);

      AuthInfo authInfo = sipFactory.createAuthInfo(username, null, password, null, null, SIP_DOMAIN, null);

      AccountParams accountParams = sipCore.createAccountParams();
      Address accountIdentity = sipCore.createAddress("sip:" + username + "@" + SIP_DOMAIN);
      accountParams.setIdentityAddress(accountIdentity);

      Address address = sipFactory.createAddress("sip:" + SIP_DOMAIN);
      address.setTransport(TransportType.Udp);
      accountParams.setServerAddress(address);

      accountParams.setRegisterEnabled(true);

      Account account = sipCore.createAccount(accountParams);

      sipCore.addAccount(account);
      sipCore.addAuthInfo(authInfo);

      sipCore.setDefaultAccount(account);

      sipCore.addListener(coreListenerStub);

      appStateListener = stateListener;

      int startResult = sipCore.start();

      Log.d(LOG_TAG, "startResult " + startResult);
      if (startResult == 0) {
        initResult.onResult(true, null);
      } else {
        initResult.onResult(false, SipAppInitError.SYSTEM_ERROR);
      }
    } catch (Exception e) {
      Log.e(LOG_TAG, e.toString());
      initResult.onResult(false, SipAppInitError.PERMISSION_NOT_GRANTED);
    }
  }

  public static void answerIncomingCall() {
    Call currentCall = sipCore.getCurrentCall();
    if (currentCall != null) {
      currentCall.accept();
    }
  }

  public static void rejectIncomingCall() {
    Call currentCall = sipCore.getCurrentCall();
    if (currentCall != null) {
      currentCall.terminate();
    }
  }

  public static void destroySdk() {
    if (sipCore != null) {
      sipCore.stop();
      sipCore.clearAllAuthInfo();
      sipCore.removeListener(coreListenerStub);
      sipCore = null;
      appStateListener = null;
    }
  }
}
