//
//  User.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation

struct UserBot: Decodable {
    var owner: String
}

enum Presence: Codable {
    case Busy, Idle, Invisible, Online, Focus
}

enum Relation: String, Codable {
    case Blocked
    case BlockedOther
    case Friend
    case Incoming
    case None
    case Outgoing
    case User
}

struct Status: Codable {
    var text: String?
    var presence: String?
}

struct UserRelation: Codable {
    var status: String
}

struct User: Identifiable, Decodable {
    var id: String
    var username: String
    var discriminator: String
    var display_name: String?
    var avatar: File?
    var relations: [UserRelation]?
    var badges: Int?
    var status: Status?
    var relationship: Relation?
    var online: Bool?
    var flags: Int?
    var bot: UserBot?
    var privileged: Bool?
    var profile: Profile?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username, discriminator, display_name, avatar, relations, badges, status, relationship, online, flags, bot, privileged
    }
}

struct Profile: Decodable {
    var content: String?
    var background: File?
}
