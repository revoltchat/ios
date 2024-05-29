//
//  Emoji.swift
//  Revolt
//
//  Created by Angelo on 14/10/2023.
//

import Foundation

public struct EmojiParentServer: Decodable, Equatable {
    public init(id: String) {
        self.id = id
    }
    
    public var id: String
}

public struct EmojiParentDetached: Decodable, Equatable {
    
}

public enum EmojiParent: Equatable {
    case server(EmojiParentServer)
    case detached(EmojiParentDetached)
}

extension EmojiParent: Decodable {
    enum CodingKeys: String, CodingKey { case type }
    enum Tag: String, Decodable { case Server, Detached }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleValueContainer = try decoder.singleValueContainer()
        
        switch try container.decode(Tag.self, forKey: .type) {
            case .Server:
                self = .server(try singleValueContainer.decode(EmojiParentServer.self))
            case .Detached:
                self = .detached(try singleValueContainer.decode(EmojiParentDetached.self))
        }
    }
}

public struct Emoji: Decodable, Equatable, Identifiable {
    public init(id: String, parent: EmojiParent, creator_id: String, name: String, animated: Bool? = nil, nsfw: Bool? = nil) {
        self.id = id
        self.parent = parent
        self.creator_id = creator_id
        self.name = name
        self.animated = animated
        self.nsfw = nsfw
    }
    
    public var id: String
    public var parent: EmojiParent
    public var creator_id: String
    public var name: String
    public var animated: Bool?
    public var nsfw: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case parent, creator_id, name, animated, nsfw
    }
}
