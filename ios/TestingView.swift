//
//  TestingView.swift
//  JarvisTemplateAppSdk
//
//  Created by Viatick-JueJue on 5/3/23.
//  Copyright © 2023 Facebook. All rights reserved.
// 

import SwiftUI
import linphonesw
import UIKit

struct TestingView: View {
   // @ObservedObject var videoCallContext : JarvisTemplateAppSdk
    
    static var nativeVideoWindow: UIView? = nil;
    static var nativePreviewWindow: UIView? = nil;

    @available(iOS 13.0, *)
    var body:some View {
        VStack {
            LinphoneVideoViewHolder() { view in
                print("IntercomSDK: LinphoneVideoViewHolder returned");
                TestingView.nativeVideoWindow = view
            }
              .frame(width: 140, height: 200)
              .border(Color.green)
              .padding(.leading)
            
            LinphoneVideoViewHolder() { view in
                TestingView.nativePreviewWindow = view
            }
            .frame(width: 140, height: 200)
            .border(Color.green)
            .padding(.leading)
        }
    }
    
}
