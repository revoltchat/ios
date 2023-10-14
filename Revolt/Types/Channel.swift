//
//  Channel.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation

struct SavedMessages: Decodable {
    var id: String
    var user: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
    }
}

struct DMChannel: Decodable {
    var id: String
    var active: Bool
    var recipients: [String]
    var last_message_id: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case active, recipients, last_message_id
    }
}

struct GroupDMChannel: Decodable {
    var id: String
    var recipients: [String]
    var name: String
    var owner: String
    var icon: File?
    var permissions: Int?
    var description: String?
    var nsfw: Bool?
    var last_message_id: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case recipients, name, owner, icon, permissions, description, nsfw, last_message_id
    }
}

struct TextChannel: Decodable {
    var id: String
    var server: String
    var name: String
    var description: String?
    var icon: File?
    var default_permissions: Overwrite?
    var role_permissions: [String: Overwrite]?
    var nsfw: Bool?
    var last_message_id: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case server, name, description, icon, default_permissions, role_permissions, nsfw, last_message_id
    }
}

struct VoiceChannel: Decodable {
    var id: String
    var server: String
    var name: String
    var description: String?
    var icon: File?
    var default_permissions: Overwrite?
    var role_permissions: [String: Overwrite]?
    var nsfw: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case server, name, description, icon, default_permissions, role_permissions, nsfw
    }
}

enum Channel {
    case saved_messages(SavedMessages)
    case dm_channel(DMChannel)
    case group_dm_channel(GroupDMChannel)
    case text_channel(TextChannel)
    case voice_channel(VoiceChannel)
    
    func id() -> String {
        switch self {
            case .saved_messages(let c):
                c.id
            case .dm_channel(let c):
                c.id
            case .group_dm_channel(let c):
                c.id
            case .text_channel(let c):
                c.id
            case .voice_channel(let c):
                c.id
        }
    }
}


extension Channel: Decodable {
    enum CodingKeys: String, CodingKey { case channel_type }
    enum Tag: String, Decodable { case SavedMessages, DirectMessage, Group, TextChannel, VoiceChannel }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleValueContainer = try decoder.singleValueContainer()
        
        switch try container.decode(Tag.self, forKey: .channel_type) {
            case .SavedMessages:
                self = .saved_messages(try singleValueContainer.decode(SavedMessages.self))
            case .DirectMessage:
                self = .dm_channel(try singleValueContainer.decode(DMChannel.self))
            case .Group:
                self = .group_dm_channel(try singleValueContainer.decode(GroupDMChannel.self))
            case .TextChannel:
                self = .text_channel(try singleValueContainer.decode(TextChannel.self))
            case .VoiceChannel:
                self = .voice_channel(try singleValueContainer.decode(VoiceChannel.self))
        }
    }
}
