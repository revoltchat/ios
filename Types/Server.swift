//
//  Server.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation

public struct Server: Codable, Identifiable {
    public init(id: String, owner: String, name: String, channels: [String], default_permissions: Permissions, description: String? = nil, categories: [Category]? = nil, system_messages: SystemMessages? = nil, roles: [String : Role]? = nil, icon: File? = nil, banner: File? = nil, nsfw: Bool? = nil, flags: ServerFlags? = nil) {
        self.id = id
        self.owner = owner
        self.name = name
        self.channels = channels
        self.default_permissions = default_permissions
        self.description = description
        self.categories = categories
        self.system_messages = system_messages
        self.roles = roles
        self.icon = icon
        self.banner = banner
        self.nsfw = nsfw
        self.flags = flags
    }
    
    public var id: String
    public var owner: String
    public var name: String
    public var channels: [String]
    public var default_permissions: Permissions
    public var description: String?
    public var categories: [Category]?
    public var system_messages: SystemMessages?
    public var roles: [String: Role]?
    public var icon: File?
    public var banner: File?
    public var nsfw: Bool?
    public var flags: ServerFlags?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case owner, name, channels, default_permissions, description, categories, system_messages, roles, icon, banner, nsfw, flags
    }
}

public struct ServerFlags: OptionSet {
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public var rawValue: Int
    
    public static let offical = ServerFlags(rawValue: 1 << 0)
    public static let verified = ServerFlags(rawValue: 1 << 1)

}

extension ServerFlags: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(Int.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct SystemMessages: Codable, Equatable {
    public init(user_joined: String? = nil, user_left: String? = nil, user_kicked: String? = nil, user_banned: String? = nil) {
        self.user_joined = user_joined
        self.user_left = user_left
        self.user_kicked = user_kicked
        self.user_banned = user_banned
    }
    
    public var user_joined: String?
    public var user_left: String?
    public var user_kicked: String?
    public var user_banned: String?
}

public struct Category: Codable, Identifiable {
    public init(id: String, title: String, channels: [String]) {
        self.id = id
        self.title = title
        self.channels = channels
    }
    
    public var id: String
    public var title: String
    public var channels: [String]
}
