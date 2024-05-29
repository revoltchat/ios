//
//  Api.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation

public struct CaptchaFeature: Codable {
    public init(enabled: Bool, key: String) {
        self.enabled = enabled
        self.key = key
    }
    
    public var enabled: Bool
    public var key: String
}

public struct RevoltFeature: Codable {
    public init(enabled: Bool, url: String) {
        self.enabled = enabled
        self.url = url
    }
    
    public var enabled: Bool
    public var url: String
}

public struct VortexFeature: Codable {
    public init(enabled: Bool, url: String, ws: String) {
        self.enabled = enabled
        self.url = url
        self.ws = ws
    }
    
    public var enabled: Bool
    public var url: String
    public var ws: String
}

public struct ApiFeatures: Codable {
    public init(captcha: CaptchaFeature, email: Bool, invite_only: Bool, autumn: RevoltFeature, january: RevoltFeature, voso: VortexFeature) {
        self.captcha = captcha
        self.email = email
        self.invite_only = invite_only
        self.autumn = autumn
        self.january = january
        self.voso = voso
    }
    
    public var captcha: CaptchaFeature
    public var email: Bool
    public var invite_only: Bool
    public var autumn: RevoltFeature
    public var january: RevoltFeature
    public var voso: VortexFeature
}

public struct ApiInfo: Codable {
    public init(revolt: String, features: ApiFeatures, ws: String, app: String, vapid: String) {
        self.revolt = revolt
        self.features = features
        self.ws = ws
        self.app = app
        self.vapid = vapid
    }
    
    public var revolt: String
    public var features: ApiFeatures
    public var ws: String
    public var app: String
    public var vapid: String
}

public struct Session: Decodable, Identifiable {
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    public var id: String
    public var name: String
    
    enum CodingKeys: String, CodingKey { case id = "_id", name }
}
