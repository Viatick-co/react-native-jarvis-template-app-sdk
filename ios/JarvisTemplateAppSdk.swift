import Foundation
import CoreLocation


class BleScannerService: CLLocationManagerDelegate {
    
    var CHANNEL_ID = "Jarvis_Rn_Sdk_Channel"
    var DEVICE_CHANNEL_ID = "Jarvis_Rn_Device_Channel"
    @Published var running = false
    @Published var sdkKey = ""
    @Published var locatingRange = 3
    @Published var notificationIconResourceId = 0
    @Published var notificationTitle = "Jarvis"
    @Published var notificationDescription = "SDK Running..."
    
    
    @Published var distance : Double?
    @Published var requested: Bool = false
    var locationManager: CLLocationManager!
    
    
    init(
        sdkKey: String,
        locatingRange: Int?,
        notificationIconResourceId: Int?,
        notificationTitle: String?,
        notificationDescription: String?
    ) {
        print("BleScannerService", "onStartCommand")
        self.sdkKey = sdkKey
        self.locatingRange = locatingRange ?? 3
        self.notificationIconResourceId = notificationIconResourceId ?? 1
        self.notificationTitle = notificationTitle ?? "Jarvis"
        self.notificationDescription = notificationDescription ?? "SDK Running..."
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        self.startScanningService()
        
    }
    
    func startScanningService() -> Void {
        print("BleScannerServiceIos", "Start Scanning")
        let beaconRegion = CLBeaconRegion()
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
        requested = true
    }
    
    func stopScanningService() ->Void {
        print("BleScannerServiceIos", "Stop Scanning")
        let beaconRegion = CLBeaconRegion()
        locationManager.stopMonitoring(for: beaconRegion)
        locationManager.stopRangingBeacons(in: beaconRegion)
        requested = false
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        processBeacons(beacons);
    }
    
    func processBeacons(_ beacons: [CLBeacon]) {
        var maxDistance: Double = 15;
        var uuid:String?;
        var beaconMajor:Int = 0;
        var beaconMinor:Int = 0;
        var beaconDistance:Double = 0;
        var rssi:Int = 0
        for aBeacon in beacons {
            let beaconAccuracy: Double = -1 * aBeacon.accuracy.distance(to: 0);
            if (beaconAccuracy > 0) {
                
                uuid = aBeacon.proximityUUID.uuidString;
                beaconMajor = aBeacon.major.intValue;
                beaconMinor = aBeacon.minor.intValue;
                rssi = aBeacon.rssi;
                maxDistance = beaconAccuracy;
                beaconDistance = beaconAccuracy;
                aBeacon.proximity
                distance = beaconDistance;
                //        print("BeaconModule","UUID -----------", uuid, " major - minor ", beaconMajor , "--" , beaconMinor , "distance ", beaconDistance);
                if (requested == true) {
                    sendEvent(withName: "BeaconInformation", body: [
                        "uuid": uuid,
                        "major": beaconMajor,
                        "minor": beaconMinor,
                        "distance": beaconDistance,
                        "rssi": rssi
                    ])
                }
            }
        }
    }
}


@objc(JarvisTemplateAppSdk)
class JarvisTemplateAppSdk: RCTEventEmitter {
    
    @Published var bleScanningService: BleScannerService?
    
    @objc(multiply:withB:withResolver:withRejecter:)
    func multiply(a: Float, b: Float, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        resolve(a*b)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    startScanning()
                }
            }
        }
    }
    
    @objc(sdkKey:locatingRange:notificationIconName:notificationTitle:notificationDescription:promise:)
    func startScanning(
        sdkKey: String,
        locatingRange: Int,
        notificationIconName: String,
        notificationTitle: String,
        notificationDescription: String,
        _ promise : RCTResponseSenderBlock? = nil
    ) -> Void {
        bleScanningService = BleScannerService(
            sdkKey: sdkKey,
            locatingRange: locatingRange,
            notificationIconResourceId: nil,
            notificationTitle: notificationTitle,
            notificationDescription: notificationDescription
        )
        if (promise != nil) {
            promise!([true])
        }
    }
    
    @objc
    func stopScanning() {
        if (bleScanningService != nil) {
            bleScanningService?.stopScanningService()
        }
    }
    
    open override func supportedEvents() -> [String] {
        ["BeaconInformation", "onPending"]      // etc.
    }
    
    
    
}
