interface BeaconInfo {
  uuid: string;
  minor: number;
  major: number;
}

interface NotifcationInfo {
  title: string;
  description: string;
}

type ServiceBeaconInfo = {
  uuid: string;
  major: number;
  minor: number;
  distance: number;
  lastSignalTime: number;
};

type JarvisServiceStatus = {
  lastDetectedSignalDateTime: number;
  serviceRunning: boolean;
  beacons: ServiceBeaconInfo[];
};

type InitSipAppResult = {
  success: boolean;
  errorCode: number;
};

enum SipRegistrationState {
  None,
  Progress,
  Ok,
  Cleared,
  Failed,
}

enum SipCallState {
  Idle,
  IncomingReceived,
  PushIncomingReceived,
  OutgoingInit,
  OutgoingProgress,
  OutgoingRinging,
  OutgoingEarlyMedia,
  Connected,
  StreamsRunning,
  Pausing,
  Paused,
  Resuming,
  Referred,
  Error,
  End,
  PausedByRemote,
  UpdatedByRemote,
  IncomingEarlyMedia,
  Updating,
  Released,
  EarlyUpdatedByRemote,
  EarlyUpdating,
}

export {
  BeaconInfo,
  NotifcationInfo,
  JarvisServiceStatus,
  InitSipAppResult,
  SipRegistrationState,
  SipCallState,
};
