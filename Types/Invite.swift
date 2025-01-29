//
//  Invite.swift
//  Revolt
//
//  Created by Angelo on 09/03/2024.
//

import Foundation

public struct ServerInvite: Codable, Identifiable {
    public var id: String
    public var server: String
    public var creator: String
    public var channel: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case server, creator, channel
    }
}

public struct GroupInvite: Codable, Identifiable {
    public var id: String
    public var creator: String
    public var channel: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case creator, channel
    }
}

public enum Invite: Identifiable {
    case server(ServerInvite)
    case group(GroupInvite)
    
    public var id: String {
        switch self {
            case .server(let i):
                return i.id
            case .group(let i):
                return i.id
        }
    }
}

extension Invite: Codable {
    enum CodingKeys: String, CodingKey { case type }
    enum Tag: String, Codable { case Server, Group }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleValueContainer = try decoder.singleValueContainer()
        
        switch try container.decode(Tag.self, forKey: .type) {
            case .Server:
                self = .server(try singleValueContainer.decode(ServerInvite.self))
            case .Group:
                self = .group(try singleValueContainer.decode(GroupInvite.self))
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var tagContainer = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
            case .server(let s):
                try tagContainer.encode(Tag.Server, forKey: .type)
                try s.encode(to: encoder)
            case .group(let g):
                try tagContainer.encode(Tag.Group, forKey: .type)
                try g.encode(to: encoder)
        }
    }
}
