//
//  Embed.swift
//  Revolt
//
//  Created by Angelo on 08/07/2024.
//

public struct YoutubeSpecial: Codable, Hashable {
    public var id: String
    public var timestamp: String?
}

public struct TwitchSpecial: Codable, Hashable {
    public enum ContentType: String, Codable, Hashable {
        case channel = "Channel"
        case video = "Video"
        case clip = "Clip"
    }
    
    public var content_type: ContentType
    public var id: String
}

public struct SpotifySpecial: Codable, Hashable {
    public var content_type: String
    public var id: String
}

public struct SoundcloudSpecial: Codable, Hashable {}

public struct BandcampSpecial: Codable, Hashable {
    public enum ContentType: String, Codable, Hashable {
        case album = "Album"
        case track = "Track"
    }
    
    public var content_type: ContentType
    public var id: String
}

public struct LightspeedSpecial: Codable, Hashable {
    public enum ContentType: String, Codable, Hashable {
        case channel = "Channel"
    }
    
    public var content_type: ContentType
    public var id: String
}

public struct StreamableSpecial: Codable, Hashable {
    public var id: String
}

public enum WebsiteSpecial: Hashable, Equatable {
    case none
    case gif
    case youtube(YoutubeSpecial)
    case lightspeed(LightspeedSpecial)
    case twitch(TwitchSpecial)
    case spotify(SpotifySpecial)
    case soundcloud(SoundcloudSpecial)
    case bandcamp(BandcampSpecial)
    case streamable(StreamableSpecial)
}

extension WebsiteSpecial: Codable {
    enum CodingKeys: String, CodingKey { case type }
    enum Tag: String, Codable { case None, GIF, YouTube, Lightspeed, Twitch, Spotify, Soundcloud, Bandcamp, Streamable }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleValueContainer = try decoder.singleValueContainer()
        
        switch try container.decode(Tag.self, forKey: .type) {
            case .None:
                self = .none
            case .GIF:
                self = .gif
            case .YouTube:
                self = .youtube(try singleValueContainer.decode(YoutubeSpecial.self))
            case .Lightspeed:
                self = .lightspeed(try singleValueContainer.decode(LightspeedSpecial.self))
            case .Twitch:
                self = .twitch(try singleValueContainer.decode(TwitchSpecial.self))
            case .Spotify:
                self = .spotify(try singleValueContainer.decode(SpotifySpecial.self))
            case .Soundcloud:
                self = .soundcloud(try singleValueContainer.decode(SoundcloudSpecial.self))
            case .Bandcamp:
                self = .bandcamp(try singleValueContainer.decode(BandcampSpecial.self))
            case .Streamable:
                self = .streamable(try singleValueContainer.decode(StreamableSpecial.self))
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var tagContainer = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
            case .none:
                try tagContainer.encode(Tag.None, forKey: .type)
            case .gif:
                try tagContainer.encode(Tag.GIF, forKey: .type)
            case .youtube(let e):
                try tagContainer.encode(Tag.YouTube, forKey: .type)
                try e.encode(to: encoder)
            case .lightspeed(let e):
                try tagContainer.encode(Tag.Lightspeed, forKey: .type)
                try e.encode(to: encoder)
            case .twitch(let e):
                try tagContainer.encode(Tag.Twitch, forKey: .type)
                try e.encode(to: encoder)
            case .spotify(let e):
                try tagContainer.encode(Tag.Spotify, forKey: .type)
                try e.encode(to: encoder)
            case .soundcloud(let e):
                try tagContainer.encode(Tag.Soundcloud, forKey: .type)
                try e.encode(to: encoder)
            case .bandcamp(let e):
                try tagContainer.encode(Tag.Bandcamp, forKey: .type)
                try e.encode(to: encoder)
            case .streamable(let e):
                try tagContainer.encode(Tag.Streamable, forKey: .type)
                try e.encode(to: encoder)
        }
    }
}

public struct JanuaryImage: Codable, Hashable {
    public enum Size: String, Codable, Hashable {
        case large = "Large"
        case preview = "Preview"
    }
    
    public var url: String
    public var width: Int
    public var height: Int
    public var size: Size
}

public struct JanuaryVideo: Codable, Hashable {
    public var url: String
    public var width: Int
    public var height: Int
}

public struct WebsiteEmbed: Codable, Hashable {
    public var url: String?
    public var special: WebsiteSpecial?
    public var title: String?
    public var description: String?
    public var image: JanuaryImage?
    public var video: JanuaryVideo?
    public var site_name: String?
    public var icon_url: String?
    public var colour: String?
}

public struct TextEmbed: Codable, Hashable {
    public var icon_url: String?
    public var url: String?
    public var title: String?
    public var description: String?
    public var media: File?
    public var colour: String?
}

public enum Embed: Hashable {
    case website(WebsiteEmbed)
    case image(JanuaryImage)
    case video(JanuaryVideo)
    case text(TextEmbed)
    case none
}

extension Embed: Codable {
    enum CodingKeys: String, CodingKey { case type }
    enum Tag: String, Codable { case Website, Image, Video, Text, None }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleValueContainer = try decoder.singleValueContainer()
        
        switch try container.decode(Tag.self, forKey: .type) {
            case .Website:
                self = .website(try singleValueContainer.decode(WebsiteEmbed.self))
            case .Image:
                self = .image(try singleValueContainer.decode(JanuaryImage.self))
            case .Video:
                self = .video(try singleValueContainer.decode(JanuaryVideo.self))
            case .Text:
                self = .text(try singleValueContainer.decode(TextEmbed.self))
            case .None:
                self = .none
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var tagContainer = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
            case .website(let e):
                try tagContainer.encode(Tag.Website, forKey: .type)
                try e.encode(to: encoder)
            case .image(let e):
                try tagContainer.encode(Tag.Image, forKey: .type)
                try e.encode(to: encoder)
            case .video(let e):
                try tagContainer.encode(Tag.Video, forKey: .type)
                try e.encode(to: encoder)
            case .text(let e):
                try tagContainer.encode(Tag.Text, forKey: .type)
                try e.encode(to: encoder)
            case .none:
                try tagContainer.encode(Tag.None, forKey: .type)
        }
    }
}
