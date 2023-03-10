//
//  SipVideoCallPreviewManager.swift
//  JarvisTemplateAppSdk
//
//  Created by Viatick-JueJue on 5/3/23.
//  Copyright © 2023 Facebook. All rights reserved.
//

import Foundation
import React
import SwiftUI


@objc(SipVideoCallPreviewManager)
class SipVideoCallPreviewManager: RCTViewManager {
    
    // @ObservedObject var videoCallContext = JarvisTemplateAppSdk()
    
    override func view() -> UIView! {
        
        let contentView = TestingView()
        if #available(iOS 13.0, *) {
            return UIHostingController(rootView: contentView).view
        } else {
            // Fallback on earlier versions
            return nil
        }
    }

    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}


