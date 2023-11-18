//
//  Server.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation

struct Server: Decodable, Identifiable {
    var id: String
    var owner: String
    var name: String
    var channels: [String]
    var default_permissions: Permissions
    var description: String?
    var categories: [Category]?
    var system_messages: SystemMessages?
    var roles: [String: Role]?
    var icon: File?
    var banner: File?
    var nsfw: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case owner, name, channels, default_permissions, description, categories, system_messages, roles, icon, banner, nsfw
    }
}

struct SystemMessages: Decodable {
    var user_joined: String?
    var user_left: String?
    var user_kicked: String?
    var user_banned: String?
}

struct Category: Decodable, Identifiable {
    var id: String
    var title: String
    var channels: [String]
}
