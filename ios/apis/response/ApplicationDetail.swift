//
//  ApplicationDetail.swift
//  JarvisTemplateAppSdk
//
//  Created by Thang Luu on 28/09/2022.
//  Copyright © 2022 Facebook. All rights reserved.
//

import Foundation

struct ApplicationDetailFromServer: Decodable {
    var id: String
    var name: String
    var email: String
//    struct deviceFilter: Decodable {
//        var stringValue: String
//        init?(stringValue: String) {
//            self.stringValue = stringValue
//        }
//        var intValue: DeviceFilter?
//        init?(intValue: DeviceFilter) {
//            return nil
//        }
//    }
}

struct ApplicationDetail{
    let id: String
    let name: String
    let email: String
    let deviceFilterMap: [NSAttributedString.Key: DeviceFilter]
    
    
//    init(from decoder: Decoder) throws {
//        let rawResponse = try ApplicationDetailFromServer(from: decoder)
//        id = String(rawResponse.id)
//        name = rawResponse.name
//        email = rawResponse.email
//        deviceFilterMap = rawResponse.DeviceFilter
//    }
    
}
