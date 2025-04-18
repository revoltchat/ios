//
//  Channel.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation

public struct SavedMessages: Codable, Equatable, Identifiable, Hashable {
    public init(id: String, user: String) {
        self.id = id
        self.user = user
    }
    
    public var id: String
    public var user: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
    }
}

public struct DMChannel: Codable, Equatable, Identifiable, Hashable {
    public init(id: String, active: Bool, recipients: [String], last_message_id: String? = nil) {
        self.id = id
        self.active = active
        self.recipients = recipients
        self.last_message_id = last_message_id
    }
    
    public var id: String
    public var active: Bool
    public var recipients: [String]
    public var last_message_id: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case active, recipients, last_message_id
    }
}

public struct GroupDMChannel: Codable, Equatable, Identifiable, Hashable {
    public init(id: String, recipients: [String], name: String, owner: String, icon: File? = nil, permissions: Permissions? = nil, description: String? = nil, nsfw: Bool? = nil, last_message_id: String? = nil) {
        self.id = id
        self.recipients = recipients
        self.name = name
        self.owner = owner
        self.icon = icon
        self.permissions = permissions
        self.description = description
        self.nsfw = nsfw
        self.last_message_id = last_message_id
    }
    
    public var id: String
    public var recipients: [String]
    public var name: String
    public var owner: String
    public var icon: File?
    public var permissions: Permissions?
    public var description: String?
    public var nsfw: Bool?
    public var last_message_id: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case recipients, name, owner, icon, permissions, description, nsfw, last_message_id
    }
}

public struct TextChannel: Codable, Equatable, Identifiable, Hashable {
    public init(id: String, server: String, name: String, description: String? = nil, icon: File? = nil, default_permissions: Overwrite? = nil, role_permissions: [String : Overwrite]? = nil, nsfw: Bool? = nil, last_message_id: String? = nil, voice: VoiceInformation? = nil) {
        self.id = id
        self.server = server
        self.name = name
        self.description = description
        self.icon = icon
        self.default_permissions = default_permissions
        self.role_permissions = role_permissions
        self.nsfw = nsfw
        self.last_message_id = last_message_id
        self.voice = voice
    }
    
    public var id: String
    public var server: String
    public var name: String
    public var description: String?
    public var icon: File?
    public var default_permissions: Overwrite?
    public var role_permissions: [String: Overwrite]?
    public var nsfw: Bool?
    public var last_message_id: String?
    public var voice: VoiceInformation?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case server, name, description, icon, default_permissions, role_permissions, nsfw, last_message_id, voice
    }
}

public struct VoiceChannel: Codable, Equatable, Identifiable, Hashable {
    public init(id: String, server: String, name: String, description: String? = nil, icon: File? = nil, default_permissions: Overwrite? = nil, role_permissions: [String : Overwrite]? = nil, nsfw: Bool? = nil) {
        self.id = id
        self.server = server
        self.name = name
        self.description = description
        self.icon = icon
        self.default_permissions = default_permissions
        self.role_permissions = role_permissions
        self.nsfw = nsfw
    }
    
    public var id: String
    public var server: String
    public var name: String
    public var description: String?
    public var icon: File?
    public var default_permissions: Overwrite?
    public var role_permissions: [String: Overwrite]?
    public var nsfw: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case server, name, description, icon, default_permissions, role_permissions, nsfw
    }
}

public struct VoiceInformation: Codable, Equatable, Hashable {
    public init(max_users: Int? = nil) {
        self.max_users = max_users
    }
    
    public var max_users: Int?
}

@frozen
public enum Channel: Identifiable, Equatable, Hashable {
    case saved_messages(SavedMessages)
    case dm_channel(DMChannel)
    case group_dm_channel(GroupDMChannel)
    case text_channel(TextChannel)
    case voice_channel(VoiceChannel)
    
    public var name: String? {
        get {
            switch self {
                case .saved_messages(let savedMessages):
                    nil
                case .dm_channel(let dMChannel):
                    nil
                case .group_dm_channel(let groupDMChannel):
                    groupDMChannel.name
                case .text_channel(let textChannel):
                    textChannel.name
                case .voice_channel(let voiceChannel):
                    voiceChannel.name
            }
        }
        set {
            if let newValue {
                switch self {
                    case .saved_messages(let savedMessages):
                        ()
                    case .dm_channel(let dMChannel):
                        ()
                    case .group_dm_channel(var groupDMChannel):
                        groupDMChannel.name = newValue
                    case .text_channel(var textChannel):
                        textChannel.name = newValue
                    case .voice_channel(var voiceChannel):
                        voiceChannel.name = newValue
                }
            }
        }
    }
    
    public var owner: String? {
        get {
            switch self {
                case .saved_messages:
                    nil
                case .dm_channel:
                    nil
                case .group_dm_channel(let groupDMChannel):
                    groupDMChannel.owner
                case .text_channel:
                    nil
                case .voice_channel:
                    nil
            }
        }
        set {
            if let newValue {
                switch self {
                    case .saved_messages:
                        ()
                    case .dm_channel:
                        ()
                    case .group_dm_channel(var groupDMChannel):
                        groupDMChannel.owner = newValue
                    case .text_channel:
                        ()
                    case .voice_channel:
                        ()
                }
            }
        }
    }
    
    public var id: String {
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
    
    public var icon: File? {
        get {
            switch self {
                case .group_dm_channel(let c):
                    c.icon
                case .text_channel(let c):
                    c.icon
                case .voice_channel(let c):
                    c.icon
                default:
                    nil
            }
        }
        set {
            switch self {
                case .group_dm_channel(var groupDMChannel):
                    groupDMChannel.icon = newValue
                case .text_channel(var textChannel):
                    textChannel.icon = newValue
                case .voice_channel(var voiceChannel):
                    voiceChannel.icon = newValue
                default:
                    ()
            }
        }
    }
    
    public var description: String? {
        get {
            switch self {
                case .group_dm_channel(let c):
                    c.description
                case .text_channel(let c):
                    c.description
                case .voice_channel(let c):
                    c.description
                default:
                    nil
            }
        }
        set {
            switch self {
                case .group_dm_channel(var groupDMChannel):
                    groupDMChannel.description = newValue
                case .text_channel(var textChannel):
                    textChannel.description = newValue
                case .voice_channel(var voiceChannel):
                    voiceChannel.description = newValue
                default:
                    ()
            }
        }
    }
    
    public var last_message_id: String? {
        get {
            switch self {
                case .dm_channel(let c):
                    c.last_message_id
                case .group_dm_channel(let c):
                    c.last_message_id
                case .text_channel(let c):
                    c.last_message_id
                default:
                    nil
            }
        }
        set {
            switch self {
                case .dm_channel(var dMChannel):
                    dMChannel.last_message_id = newValue
                case .group_dm_channel(var groupDMChannel):
                    groupDMChannel.last_message_id = newValue
                case .text_channel(var textChannel):
                    textChannel.last_message_id = newValue
                default:
                    ()
            }
        }
    }
    
    public var nsfw: Bool? {
        get {
            switch self {
                case .group_dm_channel(let c):
                    c.nsfw
                case .text_channel(let c):
                    c.nsfw
                case .voice_channel(let c):
                    c.nsfw
                default:
                    nil
            }
        }
        set {
            switch self {
                case .group_dm_channel(var groupDMChannel):
                    groupDMChannel.nsfw = newValue
                case .text_channel(var textChannel):
                    textChannel.nsfw = newValue
                case .voice_channel(var voiceChannel):
                    voiceChannel.nsfw = newValue
                default:
                    ()
            }
        }
    }
    
    public var active: Bool? {
        get {
            switch self {
                case .dm_channel(let dMChannel):
                    dMChannel.active
                default:
                    nil
            }
        }
        set {
            if let newValue {
                switch self {
                    case .dm_channel(var dMChannel):
                        dMChannel.active = newValue
                    default:
                        ()
                }
            }
        }
    }
    
    public var recipients: [String]? {
        get {
            switch self {
                case .dm_channel(let dMChannel):
                    dMChannel.recipients
                case .group_dm_channel(let groupDMChannel):
                    groupDMChannel.recipients
                default:
                    nil
            }
        }
        set {
            if let newValue {
                switch self {
                    case .dm_channel(var dMChannel):
                        dMChannel.recipients = newValue
                    case .group_dm_channel(var groupDMChannel):
                        groupDMChannel.recipients = newValue
                    default:
                        ()
                }
            }
        }
    }
    
    public var server: String? {
        switch self {
            case .saved_messages(_):
                nil
            case .dm_channel(_):
                nil
            case .group_dm_channel(_):
                nil
            case .text_channel(let textChannel):
                textChannel.server
            case .voice_channel(let voiceChannel):
                voiceChannel.server
        }
    }
    
    public var role_permissions: [String: Overwrite]? {
        get {
            switch self {
                case .text_channel(let textChannel):
                    textChannel.role_permissions
                case .voice_channel(let voiceChannel):
                    voiceChannel.role_permissions
                default:
                    nil
            }
        }
        set {
            switch self {
                case .text_channel(var textChannel):
                    textChannel.role_permissions = newValue
                case .voice_channel(var voiceChannel):
                    voiceChannel.role_permissions = newValue
                default:
                    ()
            }
        }
    }
    
    public var permissions: Permissions? {
        get {
            switch self {
                case .group_dm_channel(let groupDMChannel):
                    groupDMChannel.permissions
                default:
                    nil
            }
        }
        set {
            switch self {
                case .group_dm_channel(var groupDMChannel):
                    groupDMChannel.permissions = newValue
                default:
                    ()
            }
        }
    }
    
    public var default_permissions: Overwrite? {
        get {
            switch self {
                case .text_channel(let textChannel):
                    textChannel.default_permissions
                case .voice_channel(let voiceChannel):
                    voiceChannel.default_permissions
                default:
                    nil
            }
        }
        set {
            switch self {
                case .text_channel(var textChannel):
                    textChannel.default_permissions = newValue
                case .voice_channel(var voiceChannel):
                    voiceChannel.default_permissions = newValue
                default:
                    ()
            }
        }
    }
}


extension Channel: Decodable {
    enum CodingKeys: String, CodingKey { case channel_type }
    enum Tag: String, Codable { case SavedMessages, DirectMessage, Group, TextChannel, VoiceChannel }
    
    public init(from decoder: Decoder) throws {
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

extension Channel: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var tagContainer = encoder.container(keyedBy: CodingKeys.self)

        switch self {
            case .saved_messages(let c):
                try tagContainer.encode(Tag.SavedMessages, forKey: .channel_type)
                try c.encode(to: encoder)
            case .dm_channel(let c):
                try tagContainer.encode(Tag.DirectMessage, forKey: .channel_type)
                try c.encode(to: encoder)
            case .group_dm_channel(let c):
                try tagContainer.encode(Tag.Group, forKey: .channel_type)
                try c.encode(to: encoder)
            case .text_channel(let c):
                try tagContainer.encode(Tag.TextChannel, forKey: .channel_type)
                try c.encode(to: encoder)
            case .voice_channel(let c):
                try tagContainer.encode(Tag.VoiceChannel, forKey: .channel_type)
                try c.encode(to: encoder)
        }
    }
}
