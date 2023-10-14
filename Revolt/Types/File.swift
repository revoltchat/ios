//
//  File.swift
//  Revolt
//
//  Created by Angelo on 12/10/2023.
//

import Foundation

struct SizedMetadata: Decodable {
    var height: Int
    var width: Int
}

struct SimpleMetadata: Decodable {}

enum FileMetadata {
    case image(SizedMetadata)
    case video(SizedMetadata)
    case file(SimpleMetadata)
    case text(SimpleMetadata)
    case audio(SimpleMetadata)
}

extension FileMetadata: Decodable {
    enum CodingKeys: String, CodingKey { case type }
    enum Tag: String, Decodable { case Image, Video, File, Text, Audio }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleValueContainer = try decoder.singleValueContainer()
        
        switch try container.decode(Tag.self, forKey: .type) {
            case .Image:
                self = .image(try singleValueContainer.decode(SizedMetadata.self))
            case .Video:
                self = .video(try singleValueContainer.decode(SizedMetadata.self))
            case .File:
                self = .file(try singleValueContainer.decode(SimpleMetadata.self))
            case .Text:
                self = .text(try singleValueContainer.decode(SimpleMetadata.self))
            case .Audio:
                self = .audio(try singleValueContainer.decode(SimpleMetadata.self))
        }
    }
}

struct File: Decodable {
    var id: String
    var tag: String
    var size: Int
    var filename: String
    var metadata: FileMetadata
    var content_type: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case tag, size, filename, metadata, content_type
    }
}
