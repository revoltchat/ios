//
//  Embed.swift
//  Revolt
//
//  Created by Angelo on 08/07/2024.
//

public struct YoutubeSpecial: Decodable, Hashable {
    public var id: String
    public var timestamp: String?
}

public struct TwitchSpecial: Decodable, Hashable {
    public enum ContentType: String, Decodable, Hashable {
        case channel = "Channel"
        case video = "Video"
        case clip = "Clip"
    }
    
    public var content_type: ContentType
    public var id: String
}

public struct SpotifySpecial: Decodable, Hashable {
    public var content_type: String
    public var id: String
}

public struct SoundcloudSpecial: Decodable, Hashable {
    
}

public struct BandcampSpecial: Decodable, Hashable {
    public enum ContentType: String, Decodable, Hashable {
        case album = "Album"
        case track = "Track"
    }
    
    public var content_type: ContentType
    public var id: String
}

public struct LightspeedSpecial: Decodable, Hashable {
    public enum ContentType: String, Decodable, Hashable {
        case channel = "Channel"
    }
    
    public var content_type: ContentType
    public var id: String
}

public struct StreamableSpecial: Decodable, Hashable {
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

extension WebsiteSpecial: Decodable {
    enum CodingKeys: String, CodingKey { case type }
    enum Tag: String, Codable { case None, GIF, YouTube, Lightspeed, Twitch, Spotify, Cloudcloud, Bandcamp, Streamable }
    
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
            case .Cloudcloud:
                self = .soundcloud(try singleValueContainer.decode(SoundcloudSpecial.self))
            case .Bandcamp:
                self = .bandcamp(try singleValueContainer.decode(BandcampSpecial.self))
            case .Streamable:
                self = .streamable(try singleValueContainer.decode(StreamableSpecial.self))
        }
    }
}

public struct JanuaryImage: Decodable, Hashable {
    public enum Size: String, Decodable, Hashable {
        case large = "Large"
        case preview = "Preview"
    }
    
    public var url: String
    public var width: Int
    public var height: Int
    public var size: Size
}

public struct JanuaryVideo: Decodable, Hashable {
    public var url: String
    public var width: Int
    public var height: Int
}

public struct WebsiteEmbed: Decodable, Hashable {
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

public struct TextEmbed: Decodable, Hashable {
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
    case text(TextEmbed)
    case none
}

extension Embed: Decodable {
    enum CodingKeys: String, CodingKey { case type }
    enum Tag: String, Codable { case Website, Image, Text, None }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleValueContainer = try decoder.singleValueContainer()
        
        switch try container.decode(Tag.self, forKey: .type) {
            case .Website:
                self = .website(try singleValueContainer.decode(WebsiteEmbed.self))
            case .Image:
                self = .image(try singleValueContainer.decode(JanuaryImage.self))
            case .Text:
                self = .text(try singleValueContainer.decode(TextEmbed.self))
            case .None:
                self = .none
        }
    }
}
