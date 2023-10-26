//
//  Message.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation

struct Interactions: Codable {
    var reactions: [String]?
    var restrict_reactions: Bool?
}

struct Masquerade: Codable {
    var name: String?
    var avatar: String?
    var colour: String?
}

struct TextSystemMessageContent: Codable {
    var content: String
}

struct UserAddedSystemContent: Codable {
    var id: String
    var by: String
}

struct UserRemovedSystemContent: Codable {
    var id: String
    var by: String
}

struct UserJoinedSystemContent: Codable {
    var id: String
}

struct UserLeftSystemContent: Codable {
    var id: String
}

struct UserKickedSystemContent: Codable {
    var id: String
}

struct UserBannedSystemContent: Codable {
    var id: String
}

struct ChannelRenamedSystemContent: Codable {
    var name: String
    var by: String
}

struct ChannelDescriptionChangedSystemContent: Codable {
    var by: String
}

struct ChannelIconChangedSystemContent: Codable {
    var by: String
}

struct ChannelOwnershipChangedSystemContent: Codable {
    var from: String
    var to: String
}

enum SystemMessageContent {
    case text(TextSystemMessageContent)
    case user_added(UserAddedSystemContent)
    case user_removed(UserRemovedSystemContent)
    case user_joined(UserJoinedSystemContent)
    case user_left(UserLeftSystemContent)
    case user_kicked(UserKickedSystemContent)
    case user_banned(UserBannedSystemContent)
    case channel_renamed(ChannelRenamedSystemContent)
    case channel_description_changed(ChannelDescriptionChangedSystemContent)
    case channel_icon_changed(ChannelIconChangedSystemContent)
    case channel_ownership_changed(ChannelOwnershipChangedSystemContent)
}

extension SystemMessageContent: Decodable {
    enum CodingKeys: String, CodingKey { case type }
    enum Tag: String, Decodable { case text, user_added, user_remove, user_joined, user_left, user_kicked, user_banned, channel_renamed, channel_description_changed, channel_icon_changed, channel_ownership_changed }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleValueContainer = try decoder.singleValueContainer()
        
        switch try container.decode(Tag.self, forKey: .type) {
            case .text:
                self = .text(try singleValueContainer.decode(TextSystemMessageContent.self))
            case .user_added:
                self = .user_added(try singleValueContainer.decode(UserAddedSystemContent.self))
            case .user_remove:
                self = .user_removed(try singleValueContainer.decode(UserRemovedSystemContent.self))
            case .user_joined:
                self = .user_joined(try singleValueContainer.decode(UserJoinedSystemContent.self))
            case .user_left:
                self = .user_left(try singleValueContainer.decode(UserLeftSystemContent.self))
            case .user_kicked:
                self = .user_kicked(try singleValueContainer.decode(UserKickedSystemContent.self))
            case .user_banned:
                self = .user_banned(try singleValueContainer.decode(UserBannedSystemContent.self))
            case .channel_renamed:
                self = .channel_renamed(try singleValueContainer.decode(ChannelRenamedSystemContent.self))
            case .channel_description_changed:
                self = .channel_description_changed(try singleValueContainer.decode(ChannelDescriptionChangedSystemContent.self))
            case .channel_icon_changed:
                self = .channel_icon_changed(try singleValueContainer.decode(ChannelIconChangedSystemContent.self))
            case .channel_ownership_changed:
                self = .channel_ownership_changed(try singleValueContainer.decode(ChannelOwnershipChangedSystemContent.self))
        }
    }
}

struct Message: Identifiable, Decodable {
    var id: String

    var content: String?
    var author: String
    var channel: String
    var system: SystemMessageContent?
    var attachments: [File]?
    var mentions: [String]?
    var replies: [String]?
    var edited: String?
    var masquerade: Masquerade?
    var interactions: Interactions?
    var reactions: [String: [String]]?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case content, author, channel, system, attachments, mentions, replies, edited, masquerade, interactions, reactions
    }
}
