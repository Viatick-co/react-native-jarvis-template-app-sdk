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
    
    @ObservedObject var videoCallContext = JarvisTemplateAppSdk()
    
    override func view() -> UIView! {
        
        let contentView = TestingView(videoCallContext: videoCallContext)
        return UIHostingController(rootView: contentView).view
    }

    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}


