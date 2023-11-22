//
//  Responses.swift
//  Revolt
//
//  Created by Tom on 2023-11-13.
//

import Foundation

struct AccountCreateVerifyResponse: Decodable {
    struct Inner: Decodable {
        var _id: String
        var account_id: String
        var token: String
        var validated: Bool
        var authorised: Bool
        var last_totp_code: String?
    }
    
    var ticket: Inner
}

struct OnboardingStatusResponse: Decodable {
    var onboarding: Bool
}

struct AutumnResponse: Decodable {
    var id: String
}

struct JoinResponse: Decodable {
    var type: String
    var channels: [Channel]
    var server: Server
}

struct Unread: Decodable, Identifiable {
    struct Id: Decodable, Hashable {
        var channel: String
        var user: String
    }
    
    var id: Id
    var last_id: String?
    var mentions: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case last_id, mentions
    }
}
