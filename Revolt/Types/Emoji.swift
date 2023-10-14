//
//  Emoji.swift
//  Revolt
//
//  Created by Angelo on 14/10/2023.
//

import Foundation

struct EmojiParentServer: Decodable {
    var id: String
}

struct EmojiParentDetached: Decodable {
    
}

enum EmojiParent {
    case server(EmojiParentServer)
    case detached(EmojiParentDetached)
}

extension EmojiParent: Decodable {
    enum CodingKeys: String, CodingKey { case type }
    enum Tag: String, Decodable { case Server, Detached }
    
    init(from decoder: Decoder) throws {
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

struct Emoji: Decodable {
    var id: String
    var parent: EmojiParent
    var creator_id: String
    var name: String
    var animated: Bool?
    var nsfw: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case parent, creator_id, name, animated, nsfw
    }
}
