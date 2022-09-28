//
//  BleScanService.swift
//  JarvisTemplateAppSdk
//
//  Created by Thang Luu on 27/09/2022.
//  Copyright © 2022 Facebook. All rights reserved.
//

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
        locatingRange: Int,
        notificationIconResourceId: String,
        notificationTitle: String,
        notificationDescription: String
    ) {
        print("BleScannerService", "onStartCommand")
        self.sdkKey = sdkKey
        self.locatingRange = locatingRange ?? 3
        self.notificationIconResourceId = notificationIconResourceId ?? 1
        self.notificationTitle = notificationTitle ?? "Jarvis"
        self.notificationDescription = notificationDescription ?? "SDK Running..."
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        self.startScanningService()
        super.init()
    }
    
    func startScanningService() -> Void {
        print("BleScannerServiceIos", "Start Scanning")
        let beaconRegion = CLBeaconRegion()
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
    }
    
    
    
}
