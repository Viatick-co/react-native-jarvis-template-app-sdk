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
   @ObservedObject var videoCallContext : JarvisTemplateAppSdk

    var body: some View {
        VStack {
            Text(videoCallContext.domain)
                .padding()
                .background(Color.yellow)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1))
            LinphoneVideoViewHolder() { view in
                self.videoCallContext.mCore.nativeVideoWindow = view
            }
              .frame(width: 140, height: 200)
              .border(Color.green)
              .padding(.leading)
        }
    }
}
