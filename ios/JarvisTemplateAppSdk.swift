import CoreBluetooth
import CoreLocation
import UserNotifications
import React

struct AttendanceBeacon : Codable {
  var uuid : String
  var major : Int16
}

struct DeviceFilter : Codable {
  var attendance_beacon : AttendanceBeacon
}

struct AccountDetail: Codable {
  var id : Int64
  var name: String
  var deviceFilter : DeviceFilter?
  var description: String?
}

struct PeripheralDetail : Codable {
  var uuid : String
  var major : Int
  var minor : Int
  var distance : Double
  var lastSignalTime : Int64
}

struct BeaconNotification : Codable {
  var id : Int64
  var title : String
  var description : String
}

extension String {
  var uuidC: String? {
    var string = self
    var index = string.index(string.startIndex, offsetBy: 8)
    for _ in 0..<4 {
      string.insert("-", at: index)
      index = string.index(index, offsetBy: 5)
    }
    // The init below is used to check the validity of the string returned.
    return UUID(uuidString: string)?.uuidString
  }
}

@objc(JarvisTemplateAppSdk)
class JarvisTemplateAppSdk: RCTEventEmitter, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
  
  let apiHost = "https://jarvis.viatick.com/apis";
  
  var backgroundTask: UIBackgroundTaskIdentifier = .invalid;
  
  var resultTimer : Timer?;
  var scannedBleMap : Dictionary<String, PeripheralDetail> = [:];
  
  private var filterUuid:String = "";
  private var filterMajor:NSNumber = 0;
  private var filterRegion:CLBeaconRegion?;

  private var appKey = "";
  private var locatingRange = 3.0;
  
  private var locationManager:CLLocationManager?;
  
  private var scanning = false;
  private var starting = false;

    
  func registerBackgroundTask() {
    self.backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "ble-background-task", expirationHandler: {
      print("(MainController) expirationHandler")
      self.endBackgroundTask();
    });
    
    assert(backgroundTask != .invalid);
  }
  
  func endBackgroundTask() {
    print("(MainController)  endBackgroundTask");
    UIApplication.shared.endBackgroundTask(backgroundTask);
    self.backgroundTask = .invalid;
  }
  
  @objc public func checkScannedMap() {
    let now = Int64((Date().timeIntervalSince1970 * 1000).rounded());
    
    print("(MainController)  checkScannedMap \(now)");
    
    for (key,value) in self.scannedBleMap {
      let lastSignalTime = value.lastSignalTime;
      if (now - lastSignalTime >= 60 * 1000) {
        print("remove Beacon " + key + " \(now) \(lastSignalTime)")
        self.scannedBleMap.removeValue(forKey: key)
      }
    }
  }
  
  @objc public func startResultTimer() {
    guard self.resultTimer == nil else { return }

    self.resultTimer = Timer.scheduledTimer(
      timeInterval: TimeInterval(10),
      target      : self,
      selector    : #selector(self.checkScannedMap),
      userInfo    : nil,
      repeats     : true
      );
  }
  
  @objc public func stopResultTimer() {
    print("stopResultTimer 2");
    
    if (self.resultTimer != nil) {
      self.resultTimer?.invalidate();
      self.resultTimer = nil;
    }
  }
  
  func initBluetooth() {
    self.scanning = true;
    
   
   
    OperationQueue.main.addOperation {
      if (self.locationManager == nil) {
        let notificationCenter = UNUserNotificationCenter.current();
        notificationCenter.delegate = self;
        
        let options: UNAuthorizationOptions = [.alert, .sound];
        notificationCenter.requestAuthorization(options: options) {
          (didAllow, error) in
          if !didAllow {
            print("User has declined notifications")
          } else {
            print("requestAuthorization allowed")
//            self.pushFoundNotifcation(minor: 99999, title: "Test Title", description: "Test Description")
          }
        }
        
        self.locationManager = CLLocationManager();
        self.locationManager?.delegate = self;
      }
    }
  }
    
  func destroyBluetooth() {
    if (self.locationManager != nil) {
      // self.stopScan();
      
      self.locationManager = nil;
    }
  }
  
  func startBeaconScan() {
      print("startBeaconScan Called");
      
    OperationQueue.main.addOperation {
      let identifer = "com.viatick.jarvissdk.beaconscan";
//      let uuid = "F7826DA6-4FA2-4E98-8024-BC5B71E0893F";
//      let major:NSNumber = 5670;
//      self.filterUuid = uuid;
//      self.filterMajor = major;
      
      if #available(iOS 13.0, *) {
        self.filterRegion = CLBeaconRegion(uuid: UUID(uuidString: self.filterUuid)!, major: CLBeaconMajorValue(truncating: self.filterMajor), identifier: identifer);
      } else {
        self.filterRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: self.filterUuid)!, major: CLBeaconMajorValue(truncating: self.filterMajor), identifier: identifer);
      }

      self.filterRegion!.notifyEntryStateOnDisplay = true;
      self.filterRegion!.notifyOnExit = false;
      self.filterRegion!.notifyOnEntry = false;

      
      if (self.backgroundTask != .invalid) {
        self.endBackgroundTask();
      }
      
      self.registerBackgroundTask();
      
      
      self.locationManager!.startUpdatingLocation();
      self.locationManager!.startMonitoringSignificantLocationChanges();
      self.locationManager!.startMonitoring(for: self.filterRegion!);
      self.locationManager!.startRangingBeacons(in:self.filterRegion!);
      self.locationManager!.desiredAccuracy = kCLLocationAccuracyBest;
      self.locationManager!.allowsBackgroundLocationUpdates = true;
      self.locationManager!.pausesLocationUpdatesAutomatically = false;
      
      self.startResultTimer();
    }
  }
  
  func pushFoundNotifcation(minor : Int, title : String, description: String) {
    OperationQueue.main.addOperation {
      print("pushFoundNotifcation \(minor)");
      let center = UNUserNotificationCenter.current()
      
      let content = UNMutableNotificationContent()

      content.title = title;
      content.body = description;
      content.sound = UNNotificationSound.default;
      content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber);
     
      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
      let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
      
      center.add(request, withCompletionHandler: nil);
    }
  }
  
  func onNewBeaconDetected(ble : PeripheralDetail) {
    let now = Int64((Date().timeIntervalSince1970 * 1000).rounded());
//    print("onNewBeaconDetected \(ble.minor)");
    //print(ble);
    
//    print("ble \(ble.uuid)")
    
    let bodyJson:[String: Any] = ["uuid" : ble.uuid, "major" : ble.major, "minor" : ble.minor];
    let jsonData = try? JSONSerialization.data(withJSONObject: bodyJson)
//    print(jsonData);
    
    let url = URL(string: apiHost + "/resource/locating-notification/find-by-device");
    var request = URLRequest(url: url!);
    request.httpMethod = "POST";
    request.httpBody = jsonData;
    request.setValue(self.appKey, forHTTPHeaderField: "Access-Token");
    
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
      if let error = error {
        print("Error with fetching films: \(error)")
        return
      }
      
      guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
        print("Error with the response, unexpected status code: \(response)")
        return
      }

      if let data = data,
         let notificationDetail = try? JSONDecoder().decode(BeaconNotification.self, from: data) {
        
        let eventBody:[String: Any] = [
          "uuid" : ble.uuid,
          "major" : ble.major,
          "minor" : ble.minor,
          "title" : notificationDetail.title,
          "description" : notificationDetail.description,
          "time" : now
        ];
        self.sendEvent(withName: "BeaconInformation", body: eventBody)
        
        self.pushFoundNotifcation(minor: ble.minor, title: notificationDetail.title, description: notificationDetail.description)
        return;
      }
    })
    
    task.resume();
  }
    
  func processBeacons(_ beacons: [CLBeacon]) {
    let timestamp = Int64((Date().timeIntervalSince1970 * 1000).rounded());
    
    var maxDistance: Double = 15;

    var uuid:String?;
    var beaconMajor:Int = 0;
    var beaconMinor:Int = 0;
    var beaconDistance:Double = 0;
    
    for aBeacon in beacons {
      let beaconAccuracy: Double = -1 * aBeacon.accuracy.distance(to: 0);
      
      if (beaconAccuracy > 0 && beaconAccuracy <= maxDistance) {
        uuid = aBeacon.proximityUUID.uuidString;
        beaconMajor = aBeacon.major.intValue;
        beaconMinor = aBeacon.minor.intValue;
        
        maxDistance = beaconAccuracy;
        beaconDistance = beaconAccuracy;
        
        if (uuid != nil && beaconDistance <= self.locatingRange) {
          uuid = uuid?.replacingOccurrences(of: "-", with: "")
          
          var peripheral = PeripheralDetail(uuid: uuid!, major: beaconMajor, minor: beaconMinor, distance: beaconDistance, lastSignalTime: timestamp);
          var key = self.getPeripheralKey(peripheral: peripheral);
          // print("found key \(key)");
          
          if self.scannedBleMap[key] != nil {
            self.scannedBleMap[key]!.lastSignalTime = timestamp;
          } else {
            self.scannedBleMap[key] = peripheral;
            self.onNewBeaconDetected(ble: peripheral);
          }
        }
      }
    }
  }
  
  
  @objc(multiply:withB:withResolver:withRejecter:)
  func multiply(a: Float, b: Float, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
    resolve(a*b)
  }
  
  @objc(startScanService:withLocatingRange:withNotificationIconName:withNotificationTitle:withNotificationDescription:withResolver:withRejecter:)
  func startScanService(sdkKey: String, locatingRange: NSNumber, notificationIconName : String, notificationTitle: String, notificationDescription: String,
                        
                         resolve:@escaping RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
    if (self.starting) {
      resolve(false);
      return
    }
    
    if (self.scanning) {
      resolve(true);
      return;
    }
    
    self.appKey = sdkKey;
    self.locatingRange = locatingRange.doubleValue;
  
    let url = URL(string: apiHost + "/account/application/detail");
    var request = URLRequest(url: url!);
    request.httpMethod = "GET";
    request.setValue(self.appKey, forHTTPHeaderField: "Access-Token");
      
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
      if let error = error {
        print("Error with fetching films: \(error)")
        resolve(false)
        self.starting = false;
        return
      }
      
      guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
        print("Error with the response, unexpected status code: \(response)")
        resolve(false)
        
        self.starting = false;
        return
      }

      if let data = data,
         let accountDetail = try? JSONDecoder().decode(AccountDetail.self, from: data){
        self.filterUuid = (accountDetail.deviceFilter?.attendance_beacon.uuid)!.uuidC!;
        
        self.filterMajor = accountDetail.deviceFilter?.attendance_beacon.major as! NSNumber;
        
        self.initBluetooth()
        self.starting = false;
        resolve(true);
        return;
      }
    })

    task.resume();
  }
  
  @objc(stopScanService:withRejecter:)
  func stopScanService(resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
      print("stopScanService done 1");
    self.endBackgroundTask();
    self.stopResultTimer();
    self.destroyBluetooth();
    
    self.scanning = false;
    
    resolve(true)
  }
  
  public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    switch status {
      case .restricted:
        print("restricted");
        break;
      case .notDetermined:
        print("notDetermined");
        self.locationManager!.requestWhenInUseAuthorization();
        break;
      case .authorizedWhenInUse:
        print("authorizedWhenInUse");
        self.locationManager!.requestAlwaysAuthorization();
        break;
      case .authorizedAlways:
        self.startBeaconScan();
        break;
      case .denied:
        print("denied");
        break;
      default:
        print("nothing");
    }
  }
  
  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // print("(MainController) Location updating");
  }
  
  public func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
    // print("(MainController) didFinishDeferredUpdatesWithError");
  }
  
  public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    // print("(MainController) didFailWithError");
  }
  
  public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
    // print("(MainController) didStartMonitoringFor");
  }
  
  public func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
    // print("(MainController) rangingBeaconsDidFailFor");
  }
  
  public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
    // print("(MainController) rangingBeaconsDidFailFor");
  }
  
  public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
//    let timestamp = NSDate().timeIntervalSince1970;
//    let myTimeInterval = TimeInterval(timestamp);
//    let time = NSDate(timeIntervalSince1970: TimeInterval(myTimeInterval));
//    print(time);
//    self.processBeacons(beacons);
    
    self.processBeacons(beacons);
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.alert, .badge, .sound])
  }
  
  
  func  getPeripheralKey(peripheral: PeripheralDetail) -> String {
    return "\(peripheral.uuid)-\(peripheral.major)-\(peripheral.minor)";
   }
  
  override func supportedEvents() -> [String]! {
    return ["BeaconInformation"];
  }
}
