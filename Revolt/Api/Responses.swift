//
//  Responses.swift
//  Revolt
//
//  Created by Tom on 2023-11-13.
//

import Foundation
import Types

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

struct AuthAccount: Decodable {
    var _id: String
    var email: String
}

struct TOTPSecretResponse: Decodable {
    var secret: String
}

struct MFATicketResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case account_id, token, validated, authorised, last_totp_code
    }
    
    var id: String
    var account_id: String
    var token: String
    var validated: Bool
    var authorised: Bool
    var last_totp_code: String?
}

struct SearchResponse: Decodable {
    var messages: [Message]
    var users: [User]
    var members: [Member]
}

struct MutualsResponse: Decodable {
    var servers: [String]
    var users: [String]
}

enum InviteInfoResponse {
    case server(ServerInfoResponse)
    case group(GroupInfoResponse)
}

extension InviteInfoResponse: Decodable {
    enum CodingKeys: String, CodingKey { case type }
    enum Tag: String, Codable { case Server, Group }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleValueContainer = try decoder.singleValueContainer()
        
        switch try container.decode(Tag.self, forKey: .type) {
            case .Server:
                self = .server(try singleValueContainer.decode(ServerInfoResponse.self))
            case .Group:
                self = .group(try singleValueContainer.decode(GroupInfoResponse.self))

        }
    }
}

struct ServerInfoResponse: Decodable {
    var code: String
    var server_id: String
    var server_name: String
    var server_icon: File?
    var server_banner: File?
    var server_flags: ServerFlags?
    var channel_id: String
    var channel_name: String
    var channel_description: String?
    var user_name: String
    var user_avatar: File?
    var member_count: Int
}

struct GroupInfoResponse: Decodable {
    var code: String
    var channel_id: String
    var channel_name: String
    var channel_description: String?
    var user_name: String
    var user_avatar: File?
}
