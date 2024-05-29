//
//  File.swift
//  Types
//
//  Created by Angelo on 20/05/2024.
//

import Foundation

public struct SizedMetadata: Codable, Equatable, Hashable {
    public var height: Int
    public var width: Int
    
    enum CodingKeys: String, CodingKey { case height, width }
}

public struct SimpleMetadata: Codable, Equatable, Hashable {}

public enum FileMetadata: Equatable, Hashable {
    case image(SizedMetadata)
    case video(SizedMetadata)
    case file(SimpleMetadata)
    case text(SimpleMetadata)
    case audio(SimpleMetadata)
}

extension FileMetadata: Codable {
    enum CodingKeys: String, CodingKey { case type }
    enum Tag: String, Codable { case Image, Video, File, Text, Audio }
    
    public init(from decoder: Decoder) throws {
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
    
    public func encode(to encoder: any Encoder) throws {
        var tagContainer = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
            case .image(let m):
                try tagContainer.encode(Tag.Image, forKey: .type)
                var container = encoder.container(keyedBy: SizedMetadata.CodingKeys.self)
                try container.encode(m.height, forKey: .height)
                try container.encode(m.width, forKey: .width)
            case .video(let m):
                try tagContainer.encode(Tag.Video, forKey: .type)
                var container = encoder.container(keyedBy: SizedMetadata.CodingKeys.self)
                try container.encode(m.height, forKey: .height)
                try container.encode(m.width, forKey: .width)
            case .file(let m):
                try tagContainer.encode(Tag.File, forKey: .type)
            case .text(let m):
                try tagContainer.encode(Tag.Text, forKey: .type)
            case .audio(let m):
                try tagContainer.encode(Tag.Audio, forKey: .type)
        }

    }
}

public struct File: Codable, Identifiable, Equatable, Hashable {
    public var id: String
    public var tag: String
    public var size: Int64
    public var filename: String
    public var metadata: FileMetadata
    public var content_type: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case tag, size, filename, metadata, content_type
    }
}
