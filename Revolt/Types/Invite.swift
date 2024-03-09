//
//  Invite.swift
//  Revolt
//
//  Created by Angelo on 09/03/2024.
//

import Foundation

struct ServerInvite: Decodable, Identifiable {
    var id: String
    var server: String
    var creator: String
    var channel: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case server, creator, channel
    }
}

struct GroupInvite: Decodable, Identifiable {
    var id: String
    var creator: String
    var channel: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case creator, channel
    }
}

enum Invite: Identifiable {
    case server(ServerInvite)
    case group(GroupInvite)
    
    var id: String {
        switch self {
            case .server(let i):
                return i.id
            case .group(let i):
                return i.id
        }
    }
}

extension Invite: Decodable {
    enum CodingKeys: String, CodingKey { case type }
    enum Tag: String, Decodable { case Server, Group }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleValueContainer = try decoder.singleValueContainer()
        
        switch try container.decode(Tag.self, forKey: .type) {
            case .Server:
                self = .server(try singleValueContainer.decode(ServerInvite.self))
            case .Group:
                self = .group(try singleValueContainer.decode(GroupInvite.self))
        }
    }
}
