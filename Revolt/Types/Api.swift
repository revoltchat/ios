//
//  Api.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation

struct CaptchaFeature: Codable {
    var enabled: Bool
    var key: String
}
struct RevoltFeature: Codable {
    var enabled: Bool
    var url: String
}

struct VortexFeature: Codable {
    var enabled: Bool
    var url: String
    var ws: String
}

struct ApiFeatures: Codable {
    var captcha: CaptchaFeature
    var email: Bool
    var invite_only: Bool
    var autumn: RevoltFeature
    var january: RevoltFeature
    var voso: VortexFeature
}

struct ApiInfo: Codable {
    var revolt: String
    var features: ApiFeatures
    var ws: String
    var app: String
    var vapid: String
}
