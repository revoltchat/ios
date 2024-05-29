//
//  Utils.swift
//  Revolt
//
//  Created by Angelo on 14/10/2023.
//

import Foundation
import ULID
import Types

func createdAt(id: String) -> Date {
    ULID(ulidString: id)!.timestamp
}

enum FileCategory: String {
    case attachment = "attachments"
    case avatar = "avatars"
    case background = "backgrounds"
    case icon = "icons"
    case banner = "banners"
    case emoji = "emojis"
}

enum ChannelType {
    case text, voice, group, dm, saved
}

protocol Messageable: Identifiable {
    var channelType: ChannelType { get }
}
