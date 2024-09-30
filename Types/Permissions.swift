//
//  permissions.swift
//  Revolt
//
//  Created by Angelo on 14/10/2023.
//

import Foundation

public struct UserPermissions: OptionSet {
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public var rawValue: Int
    
    public static let access = UserPermissions(rawValue: 1 << 0)
    public static let viewProfile = UserPermissions(rawValue: 1 << 1)
    public static let sendMessage = UserPermissions(rawValue: 1 << 2)
    public static let invite = UserPermissions(rawValue: 1 << 3)
    
    public static let all = UserPermissions(arrayLiteral: [.access, .viewProfile, .sendMessage, .invite])
    public static let none = UserPermissions([])
}

extension UserPermissions: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(Int.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct Permissions: OptionSet, Hashable {
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public var rawValue: Int
    
    public static let manageChannel = Permissions(rawValue: 1 << 0)
    public static let manageServer = Permissions(rawValue: 1 << 1)
    public static let managePermissions = Permissions(rawValue: 1 << 2)
    public static let manageRole = Permissions(rawValue: 1 << 3)
    public static let manageCustomisation = Permissions(rawValue: 1 << 4)
    
    public static let kickMembers = Permissions(rawValue: 1 << 6)
    public static let banMembers = Permissions(rawValue: 1 << 7)
    public static let timeoutMembers = Permissions(rawValue: 1 << 8)
    public static let assignRoles = Permissions(rawValue: 1 << 9)
    public static let manageNickname = Permissions(rawValue: 1 << 10)
    public static let changeNicknames = Permissions(rawValue: 1 << 11)
    public static let changeAvatars = Permissions(rawValue: 1 << 12)
    public static let removeAvatars = Permissions(rawValue: 1 << 13)
    
    public static let viewChannel = Permissions(rawValue: 1 << 20)
    public static let readMessageHistory = Permissions(rawValue: 1 << 21)
    public static let sendMessages = Permissions(rawValue: 1 << 22)
    public static let manageMessages = Permissions(rawValue: 1 << 23)
    public static let manageWebhooks = Permissions(rawValue: 1 << 24)
    public static let inviteOthers = Permissions(rawValue: 1 << 25)
    public static let sendEmbeds = Permissions(rawValue: 1 << 26)
    public static let uploadFiles = Permissions(rawValue: 1 << 27)
    public static let masquerade = Permissions(rawValue: 1 << 28)
    public static let react = Permissions(rawValue: 1 << 29)
    
    public static let connect = Permissions(rawValue: 1 << 30)
    public static let speak = Permissions(rawValue: 1 << 31)
    public static let video = Permissions(rawValue: 1 << 32)
    public static let muteMembers = Permissions(rawValue: 1 << 33)
    public static let deafenMembers = Permissions(rawValue: 1 << 34)
    public static let moveMembers = Permissions(rawValue: 1 << 35)
    
    public static let all = Permissions(arrayLiteral: [.manageChannel, .manageServer, .managePermissions, .manageRole, .manageCustomisation, .kickMembers, .banMembers, .timeoutMembers, .assignRoles, .manageNickname, .changeNicknames, .changeAvatars, .removeAvatars, .viewChannel, .readMessageHistory, .sendEmbeds, .manageMessages, .manageWebhooks, .inviteOthers, .sendEmbeds, .uploadFiles, .masquerade, .react,.connect, .speak, .video, .muteMembers, .deafenMembers, .moveMembers])
    
    public static let defaultViewOnly = Permissions([.viewChannel, .readMessageHistory])
    public static let `default` = Permissions.defaultViewOnly.intersection(Permissions([.sendMessages, .inviteOthers, .sendEmbeds, .uploadFiles, .connect, .speak]))
    public static let defaultDirectMessages = Permissions.defaultViewOnly.intersection(Permissions([.manageChannel, .react]))
    public static let defaultAllowInTimeout = Permissions([.viewChannel, .readMessageHistory])
    public static let none = Permissions([])
    
    public func apply(overwrite: Overwrite) -> Permissions {
        return self
            .union(overwrite.a)
            .intersection(Permissions.all.subtracting(overwrite.d))
    }
    
    public mutating func formApply(overwrite: Overwrite) {
        self.formUnion(overwrite.a)
        self.formIntersection(Permissions.all.subtracting(overwrite.d))
    }
    
    public var name: String {
        switch self {
            case .manageChannel:
                return "Manage Channels"
            case .manageServer:
                return "Manage Server"
            case .managePermissions:
                return "Manage Permissions"
            case .manageRole:
                return "Manage Roles"
            case .manageCustomisation:
                return "Manage Customisations"
            case .kickMembers:
                return "Kick Members"
            case .banMembers:
                return "Ban Members"
            case .timeoutMembers:
                return "Timeout Members"
            case .assignRoles:
                return "Assign Roles"
            case .manageNickname:
                return "Manage Nicknames"
            case .changeNicknames:
                return "Change Nicknames"
            case .changeAvatars:
                return "Change Avatars"
            case .removeAvatars:
                return "Remove Avatars"
            case .viewChannel:
                return "View Channel"
            case .readMessageHistory:
                return "Read Message History"
            case .sendMessages:
                return "Send Messages"
            case .manageMessages:
                return "Manage Messages"
            case .manageWebhooks:
                return "Manage Webhooks"
            case .inviteOthers:
                return "Invite Others"
            case .sendEmbeds:
                return "Send Embeds"
            case .uploadFiles:
                return "Upload Files"
            case .masquerade:
                return "Masquerade"
            case .react:
                return "Use Reactions"
            case .connect:
                return "Connect"
            case .speak:
                return "Speak"
            case .video:
                return "Video"
            case .muteMembers:
                return "Mute Members"
            case .deafenMembers:
                return "Deafen Members"
            case .moveMembers:
                return "Move Members"
            default:
                return "Unknown"
        }
    }
    
    public var description: String {
        switch self {
            case .manageChannel:
                return "Allows members to create, edit and delete channels."
            case .manageServer:
                return "Allows members to change this server's name, description, icon and other related information."
            case .managePermissions:
                return "Allows members to change permissions for channels and roles with a lower ranking."
            case .manageRole:
                return "Allows members to create, edit and delete roles with a lower rank than theirs, and modify role permissions on channels."
            case .manageCustomisation:
                return "Allows members to create, edit and delete emojis."
            case .kickMembers:
                return "Allows members to remove members from this server. Kicked members may rejoin with an invite."
            case .banMembers:
                return "Allows members to permanently remove members from this server."
            case .timeoutMembers:
                return "Allows members to temporarily prevent users from interacting with the server."
            case .assignRoles:
                return "Allows members to assign roles below their own rank to other members."
            case .manageNickname:
                return "Allows members to change the nicknames of other members."
            case .changeNicknames:
                return "Allows members to change their nickname on this server."
            case .removeAvatars:
                return "Allows members to remove the server avatars of other members on this server."
            case .changeAvatars:
                return "Allows members to change their avatar on this server."
            case .viewChannel:
                return "Allows members to view any channels they have this permission on."
            case .readMessageHistory:
                return "Allows members to read the message history of this channel."
            case .sendMessages:
                return "Allows members to send messages in text channels."
            case .manageMessages:
                return "Allows members to delete messages sent by other members."
            case .manageWebhooks:
                return "Allows members to control webhooks in a channel."
            case .inviteOthers:
                return "Allows members to invite other users to a channel."
            case .sendEmbeds:
                return "Allows members to send embedded content, whether from links or custom text embeds."
            case .uploadFiles:
                return "Allows members to upload files in text channels."
            case .masquerade:
                return "Allows members to change their name and avatar per-message."
            case .react:
                return "Allows members to react to messages."
            case .connect:
                return "Allows members to connect to a voice channel."
            case .speak:
                return "Allows members to speak in a voice channel."
            case .video:
                return "Allows members to stream video in a voice channel."
            case .muteMembers:
                return "Allows members to mute others in a voice channel."
            case .deafenMembers:
                return "Allows members to deafen others in a voice channel."
            case .moveMembers:
                return "Allows members to move others between voice channels."
            default:
                return "Unknown"
        }
    }

}

extension Permissions: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(Int.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}


public struct Overwrite: Codable, Equatable {
    public init(a: Permissions, d: Permissions) {
        self.a = a
        self.d = d
    }
    
    public var a: Permissions
    public var d: Permissions
}
