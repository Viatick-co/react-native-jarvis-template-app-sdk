package com.viatick.jarvissdk.sip;

import org.linphone.core.Call;
import org.linphone.core.RegistrationState;

public interface SipAppStateListener {

  void onAccountRegistrationStateChanged(RegistrationState state);

  void onCallStateChanged(Call.State callState, String remoteAddress);

}
