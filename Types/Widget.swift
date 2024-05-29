//
//  Widget.swift
//  Types
//
//  Created by Angelo on 21/05/2024.
//

import Foundation
import ActivityKit

public struct VoiceWidgetAttributes: ActivityAttributes {
    public init(us: User, pfp: URL, channel: Channel, channelName: String) {
        self.us = us
        self.pfp = pfp
        self.channel = channel
        self.channelName = channelName
    }
    
    public struct ContentState: Decodable, Encodable, Hashable {
        public init(currentlySpeaking: [URL], weSpeaking: Bool) {
            self.currentlySpeaking = currentlySpeaking
            self.weSpeaking = weSpeaking
        }
        
        public var currentlySpeaking: [URL]
        public var weSpeaking: Bool
    }
    
    public let us: User
    public let pfp: URL
    public let channel: Channel
    public let channelName: String
    
//    public static let preview: Self = .init(us: User(id: "0", username: "Zomatree", discriminator: "0000"), pfp: URL(string: "https://autumn.revolt.chat/avatars/DZdeerdwrU6rvfDOOGdNUptzHZT8Ri0cHCo0Z1sz99/large.png")!, channel: .voice_channel(.init(id: "0", server: "0", name: "Voice General")), channelName: "Voice")
}
