package com.viatick.jarvissdk.sip;

import com.viatick.jarvissdk.sip.data.SipAppInitError;

public interface SipAppInitCallback {

  void onResult(boolean success, SipAppInitError errorCode);

}
