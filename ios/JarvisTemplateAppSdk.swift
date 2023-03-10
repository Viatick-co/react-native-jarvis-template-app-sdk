import CoreBluetooth
import CoreLocation
import UserNotifications
import React
import linphonesw
import AVFoundation
import UIKit
import SwiftUI
import Foundation

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

 @objc(SipVideoCallPreviewManager2)
 class SipVideoCallPreviewManager2: RCTViewManager {
 
  override static func requiresMainQueueSetup() -> Bool {
    return true
  }
     
  let videoCallView = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
   
   override func view() -> UIView! {

    //  self.remoteVideoView.backgroundColor = UIColor.blue
    //  self.remoteVideoView.translatesAutoresizingMaskIntoConstraints = false


    //  self.videoCallView.addSubview(self.remoteVideoView)

    //  self.remoteVideoView.topAnchor.constraint(equalTo: self.videoCallView.topAnchor).isActive = true
    //  self.remoteVideoView.leadingAnchor.constraint(equalTo: self.videoCallView.leadingAnchor).isActive = true
    //  self.remoteVideoView.trailingAnchor.constraint(equalTo: self.videoCallView.trailingAnchor).isActive = true
    //  self.remoteVideoView.bottomAnchor.constraint(equalTo: self.videoCallView.bottomAnchor).isActive = true
     //  videoCallView.addSubview(remoteVideoView)

      return videoCallView
   }
   
 }

@objc(JarvisTemplateAppSdk)
class JarvisTemplateAppSdk: RCTEventEmitter, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
  
    // static let shared = JarvisTemplateAppSdk()
    // SIP Call Vars
    var mCore: Core!
    var coreVersion: String = Core.getVersion
    
    var mAccount: Account?
    var mCoreDelegate : CoreDelegate!
    var domain : String = "168.138.190.154"
    
    var cameraPermissionGranted = false
    var audioPermissionGranted = false

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
    private var lastFoundSignalTime : Int64 = 0;
    
    override init() {
          super.init()
      requestCameraPermission()
      requestAudioPermission()
      }

    
 

    
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
          // print("Error with the response, unexpected status code: \(response)")
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
        
        self.pushFoundNotifcation(minor: ble.minor, title: notificationDetail.title, description: notificationDetail.description)
        
        self.sendEvent(withName: "BeaconInformation", body: eventBody)
        return;
      }
    })
    
    task.resume();
  }
    
  func processBeacons(_ beacons: [CLBeacon]) {
    let timestamp = Int64((Date().timeIntervalSince1970 * 1000).rounded());
    self.lastFoundSignalTime = timestamp;
    
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

  @objc(answerIncomingCall)
  func answerIncomingCall() -> Void {
    do {
			try mCore.currentCall?.accept()
		} catch { NSLog(error.localizedDescription) }
  }

  @objc(rejectIncomingCall)
  func rejectIncomingCall() -> Void {
   do {
			try mCore.currentCall?.terminate()
		} catch { NSLog(error.localizedDescription) }
  }

  @objc(toggleVideo)
  func toggleVideo() -> Void {
   do {
            if (mCore.callsNb == 0) { return }
            let coreCall = (mCore.currentCall != nil) ? mCore.currentCall : mCore.calls[0]
            // We will need the CAMERA permission for video call
            
            if let call = coreCall {
                let params = try mCore.createCallParams(call: call)
                params.videoEnabled = !(call.currentParams!.videoEnabled)
                try call.update(params: params)
            }
        } catch { NSLog(error.localizedDescription) }
  }
    
  @objc(toggleCamera)
  func toggleCamera() -> Void {
      do {
            // Currently used camera
            let currentDevice = mCore.videoDevice

            for camera in mCore.videoDevicesList {
                // All devices will have a "Static picture" fake camera, and we don't want to use it
                if (camera != currentDevice && camera != "StaticImage: Static picture") {
                    try mCore.setVideodevice(newValue: camera)
                    break
                }
            }
        } catch { NSLog(error.localizedDescription) }
  }

  @objc(toggleMute)
  func toggleMute() -> Void {
    do {
			try mCore.micEnabled = !mCore.micEnabled
		} catch { NSLog(error.localizedDescription) }
  }
     
  @objc(toggleSpeaker)
  func toggleSpeaker() -> Void {
    do {
      // Get the currently used audio device
      let currentAudioDevice = mCore.currentCall?.outputAudioDevice
      let speakerEnabled = currentAudioDevice?.type == AudioDeviceType.Speaker

      // Get a list of all available audio devices using
      for audioDevice in mCore.audioDevices {
        if (speakerEnabled && audioDevice.type == AudioDeviceType.Microphone) {
          mCore.currentCall?.outputAudioDevice = audioDevice
          return
        } else if (!speakerEnabled && audioDevice.type == AudioDeviceType.Speaker) {
          mCore.currentCall?.outputAudioDevice = audioDevice
          return
        }
      }
		} catch { NSLog(error.localizedDescription) }
  }

  @objc(initSipApplication:withPassword:withResolver:withRejecter:)
  func initSipApplication(username: String, password: String, resolve:@escaping RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {

    requestCameraPermission()
    requestAudioPermission()

    if (mCore != nil) {
        print("IntercomSDK: set nativeVideoWindow from VideoCallView 1");
        mCore.nativeVideoWindow = VideoCallView.nativeVideoWindow;
          mCore.nativePreviewWindow = VideoCallView.nativePreviewWindow;
        
      let result: [String: Any] = ["success": false, "errorCode": 0]
      resolve(result)
      return
    }

      do {
        print("JJP: INIT SIP")

        LoggingService.Instance.logLevel = LogLevel.Debug

        try? mCore = Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)

        mCore.videoDisplayEnabled = true
        mCore.videoCaptureEnabled = true
        
        mCore.activateAudioSession(actived: true)

        let policy = mCore.videoActivationPolicy

        policy?.automaticallyAccept = true
        policy?.automaticallyInitiate = true
        
        mCore.videoActivationPolicy = policy

        let transport : TransportType = TransportType.Udp
        
        let authInfo = try Factory.Instance.createAuthInfo(username: "9004", userid: "", passwd: "9004", ha1: "", realm: "", domain: domain)
        let accountParams = try mCore.createAccountParams()
        let identity = try Factory.Instance.createAddress(addr: String("sip:9004@" + domain))
        try! accountParams.setIdentityaddress(newValue: identity)
        let address = try Factory.Instance.createAddress(addr: String("sip:" + domain))
        try address.setTransport(newValue: transport)
        try accountParams.setServeraddress(newValue: address)
        accountParams.registerEnabled = true
        
        mAccount = try mCore.createAccount(params: accountParams)
        mCore.addAuthInfo(info: authInfo)
        try mCore.addAccount(account: mAccount!)
        mCore.defaultAccount = mAccount

        mCoreDelegate = CoreDelegateStub(
          onCallStateChanged: { (core: Core, call: Call, state: Call.State, message: String) in
            print("IntercomSDK: onCallStateChanged : \(state) remoteAddress :  \(call.remoteAddress!.asStringUriOnly())")
              
              if (state == .IncomingReceived) {
do {
    try self.mCore.currentCall?.accept()
        } catch { NSLog(error.localizedDescription) }
              }
            let eventBody:[String: Any] = [
              "state" : state.rawValue,
              "remoteAddress": call.remoteContact
            ];
   
        //  self.sendEvent(withName: "SipCallState", body: eventBody)

        }, onAudioDeviceChanged: { (core: Core, device: AudioDevice) in
          // This callback will be triggered when a successful audio device has been changed
        }, onAudioDevicesListUpdated: { (core: Core) in
          // This callback will be triggered when the available devices list has changed,
          // for example after a bluetooth headset has been connected/disconnected.
        }, onAccountRegistrationStateChanged: { (core: Core, account: Account, state: RegistrationState, message: String) in
          print("IntercomSDK: onAccountRegistrationStateChanged \(state) for user id \( String(describing: account.params?.identityAddress?.asString()))\n")
          let eventBody:[String: Any] = [
              "state" : state.rawValue
          ];
   
       //   self.sendEvent(withName: "SipAppAccountState", body: eventBody)
        })
          
          print("IntercomSDK: set nativeVideoWindow from VideoCallView 2");
          mCore.nativeVideoWindow = VideoCallView.nativeVideoWindow;
            mCore.nativePreviewWindow = VideoCallView.nativePreviewWindow;
          
        mCore.addDelegate(delegate: mCoreDelegate)

        try? mCore.start()

          
        let result: [String: Any] = ["success": true, "errorCode": 0]
        print("all good")
        // resolve(result)
      }
      catch {
        NSLog(error.localizedDescription)
        let result: [String: Any] = ["success": false, "errorCode": 999]
        // resolve(result)
      }
  }

  func requestCameraPermission() {
    AVCaptureDevice.requestAccess(for: .video, completionHandler: {accessGranted in
      DispatchQueue.main.async {
        self.cameraPermissionGranted = accessGranted
      }
    })
  }
  
  func requestAudioPermission() {
    AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
      if granted {
        print("intercomSDK: permission microphone GRANTED")
        self.audioPermissionGranted = true
      } else{
        self.audioPermissionGranted = false
        print("intercomSDK: permission microphone DENIED")
      }
    })
  }
  
  @objc(stopScanService:withRejecter:)
  func stopScanService(resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
      print("stopScanService done 1");
    self.endBackgroundTask();
    self.stopResultTimer();
    self.destroyBluetooth();
    
    self.scanning = false;
    self.scannedBleMap.removeAll();
    
    resolve(true)
  }

  @objc(getScanServiceStatus:withRejecter:)
  func getScanServiceStatus(resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
    print("getScanServiceStatus called", self.scannedBleMap.values);
    
    let beacons: NSMutableArray = []
    for (uuid, beacon) in self.scannedBleMap {
      let beaconDic: NSMutableDictionary = [:]
      beaconDic["uuid"] = beacon.uuid
      beaconDic["major"] = beacon.major
      beaconDic["minor"] = beacon.minor
      beaconDic["lastSignalTime"] = beacon.lastSignalTime
      beaconDic["distance"] = beacon.distance
      beacons.add(beaconDic)
    }
    
    
    let eventBody:[String: Any] = [
      "lastDetectedSignalDateTime" : self.lastFoundSignalTime,
      "serviceRunning" : self.scanning,
      "beacons" : beacons
    ];
  
    resolve(eventBody);
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
    return ["BeaconInformation", "SipCallState", "SipAppAccountState"];
  }
}
