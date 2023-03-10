//
//  VideoCallView.swift
//  JarvisTemplateAppSdk
//
//  Created by Viatick-JueJue on 5/3/23.
//  Copyright © 2023 Facebook. All rights reserved.
// 

import SwiftUI
import linphonesw
import UIKit

struct VideoCallView: View {

    static var nativeVideoWindow: UIView? = nil;

    @available(iOS 13.0, *)
    var body:some View {
        VStack {
            LinphoneVideoViewHolder() { view in
                print("IntercomSDK: LinphoneVideoViewHolder returned");
                VideoCallView.nativeVideoWindow = view
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
