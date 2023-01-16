export interface BeaconInfo {
  uuid: string;
  minor: number;
  major: number;
}

export interface NotifcationInfo {
  title: string;
  description: string;
}

export type ServiceBeaconInfo = {
  uuid: string;
  major: number;
  minor: number;
  distance: number;
  lastSignalTime: number;
};

export type JarvisServiceStatus = {
  lastDetectedSignalDateTime: number;
  serviceRunning: boolean;
  beacons: ServiceBeaconInfo;
};
