//
//  Permissions.swift
//  Revolt
//
//  Created by Angelo on 18/11/2023.
//

import Foundation

struct UserPermissions: OptionSet {
    var rawValue: Int

    static let access = UserPermissions(rawValue: 1 << 0)
    static let viewProfile = UserPermissions(rawValue: 1 << 1)
    static let sendMessage = UserPermissions(rawValue: 1 << 2)
    static let invite = UserPermissions(rawValue: 1 << 3)
    
    static let all = UserPermissions(arrayLiteral: [.access, .viewProfile, .sendMessage, .invite])
    static let none = UserPermissions(rawValue: 0)
}

extension UserPermissions: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(Int.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct Permissions: OptionSet {
    var rawValue: Int
    
    static let manageChannel = Permissions(rawValue: 1 << 0)
    static let manageServer = Permissions(rawValue: 1 << 1)
    static let managePermissions = Permissions(rawValue: 1 << 2)
    static let manageRole = Permissions(rawValue: 1 << 3)
    static let manageCustomisation = Permissions(rawValue: 1 << 4)

    static let kickMembers = Permissions(rawValue: 1 << 6)
    static let banMembers = Permissions(rawValue: 1 << 7)
    static let timeoutMembers = Permissions(rawValue: 1 << 8)
    static let assignRoles = Permissions(rawValue: 1 << 9)
    static let manageNickname = Permissions(rawValue: 1 << 10)
    static let changeNicknames = Permissions(rawValue: 1 << 11)
    static let changeAvatars = Permissions(rawValue: 1 << 12)
    static let removeAvatars = Permissions(rawValue: 1 << 13)

    static let viewChannel = Permissions(rawValue: 1 << 20)
    static let readMessageHistory = Permissions(rawValue: 1 << 21)
    static let sendMessages = Permissions(rawValue: 1 << 22)
    static let manageMessages = Permissions(rawValue: 1 << 23)
    static let manageWebhooks = Permissions(rawValue: 1 << 24)
    static let inviteOthers = Permissions(rawValue: 1 << 25)
    static let sendEmbeds = Permissions(rawValue: 1 << 26)
    static let uploadFiles = Permissions(rawValue: 1 << 27)
    static let masquerade = Permissions(rawValue: 1 << 28)
    static let react = Permissions(rawValue: 1 << 29)

    static let connect = Permissions(rawValue: 1 << 30)
    static let speak = Permissions(rawValue: 1 << 31)
    static let video = Permissions(rawValue: 1 << 32)
    static let muteMembers = Permissions(rawValue: 1 << 33)
    static let deafenMembers = Permissions(rawValue: 1 << 34)
    static let moveMembers = Permissions(rawValue: 1 << 35)
    
    static let all = Permissions(arrayLiteral: [.manageChannel, .manageServer, .managePermissions, .manageRole, .manageCustomisation, .kickMembers, .banMembers, .timeoutMembers, .assignRoles, .manageNickname, .changeNicknames, .changeAvatars, .removeAvatars, .viewChannel, .readMessageHistory, .sendEmbeds, .manageMessages, .manageWebhooks, .inviteOthers, .sendEmbeds, .uploadFiles, .masquerade, .react,.connect, .speak, .video, .muteMembers, .deafenMembers, .moveMembers])

    static let defaultViewOnly = Permissions([.viewChannel, .readMessageHistory])
    static let `default` = Permissions.defaultViewOnly.intersection(Permissions([.sendMessages, .inviteOthers, .sendEmbeds, .uploadFiles, .connect, .speak]))
    static let defaultDirectMessages = Permissions.defaultViewOnly.intersection(Permissions([.manageChannel, .react]))
    static let defaultAllowInTimeout = Permissions([.viewChannel, .readMessageHistory])
    static let none = Permissions([])
    
    func apply(overwrite: Overwrite) -> Permissions {
        return self
            .union(overwrite.a)
            .intersection(Permissions.all.subtracting(overwrite.d))
    }
    
    mutating func formApply(overwrite: Overwrite) {
        self.formUnion(overwrite.a)
        self.formIntersection(Permissions.all.subtracting(overwrite.d))
    }
}

extension Permissions: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(Int.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

func resolveServerPermissions(user: User, member: Member, server: Server) -> Permissions {
    if user.privileged == true || server.owner == user.id {
        return Permissions.all
    }
    
    var permissions = server.default_permissions
    
    for role in member.roles?
        .map({ server.roles![$0]! })
        .sorted(by: { $0.rank < $1.rank }) ?? []
    {
        permissions.formApply(overwrite: role.permissions)
    }
    
    if member.timeout != nil {
        permissions = permissions.intersection(Permissions.defaultAllowInTimeout)
    }

    return permissions
}

func resolveChannelPermissions(from: User, targettingUser user: User, targettingMember member: Member?, channel: Channel, server: Server?) -> Permissions {
    if user.privileged == true || server?.owner == user.id {
        return Permissions.all
    }
    
    switch channel {
        case .saved_messages(let savedMessages):
            if savedMessages.user == user.id {
                return Permissions.all
            } else {
                return Permissions.none
            }
        case .dm_channel(let dMChannel):
            if dMChannel.recipients.contains(user.id) {
                let userPermissions = resolveUserPermissions(from: from, targetting: user)
                
                if userPermissions.contains(UserPermissions.sendMessage) {
                    return Permissions.defaultDirectMessages
                } else {
                    return Permissions.defaultViewOnly
                }
            } else {
                return Permissions.none
            }
        case .group_dm_channel(let groupDMChannel):
            if groupDMChannel.owner == user.id {
                return Permissions.all
            } else if groupDMChannel.recipients.contains(user.id) {
                return Permissions.defaultViewOnly.union(groupDMChannel.permissions ?? Permissions.none)
            } else {
                return Permissions.none
            }
        case .text_channel(let textChannel):
            if server!.owner == user.id {
                return Permissions.all
            }
            
            var permissions = resolveServerPermissions(user: user, member: member!, server: server!)
            
            if let defaultPermissions = textChannel.default_permissions {
                permissions.formApply(overwrite: defaultPermissions)
            }
            
            let overwrites = textChannel.role_permissions?.map({(server!.roles![$0]!, $1)}).sorted(by: {$0.0.rank < $1.0.rank}) ?? []
            
            for (_, overwrite) in overwrites {
                permissions.formApply(overwrite: overwrite)
            }
            
            if member!.timeout != nil {
                permissions.formIntersection(Permissions.defaultAllowInTimeout)
            }
            
            if !permissions.contains(Permissions.viewChannel) {
                permissions = Permissions.none
            }
            
            return permissions
    
        case .voice_channel(let voiceChannel):
            if server!.owner == user.id {
                return Permissions.all
            }
            
            var permissions = resolveServerPermissions(user: user, member: member!, server: server!)
            
            if let defaultPermissions = voiceChannel.default_permissions {
                permissions.formApply(overwrite: defaultPermissions)
            }
            
            let overwrites = voiceChannel.role_permissions?.map({(server!.roles![$0]!, $1)}).sorted(by: {$0.0.rank < $1.0.rank}) ?? []
            
            for (_, overwrite) in overwrites {
                permissions.formApply(overwrite: overwrite)
            }
            
            if member!.timeout != nil {
                permissions.formIntersection(Permissions.defaultAllowInTimeout)
            }
            
            if !permissions.contains(Permissions.viewChannel) {
                permissions = Permissions.none
            }
            
            return permissions
    }
}

func resolveUserPermissions(from: User, targetting: User) -> UserPermissions {
    if from.privileged == true {
        return UserPermissions.all
    }
    
    if from.id == targetting.id {
        return UserPermissions.all
    }
    
    var permissions = UserPermissions.none
    
    // `from` will only ever be ourself so we can rely on .relationship being correct
    switch targetting.relationship {
        case .Blocked, .BlockedOther:
            return UserPermissions.access
        case .Friend:
            return UserPermissions.all
        case .Incoming, .Outgoing:
            permissions = UserPermissions.access.union(UserPermissions.viewProfile)
        default:
            ()
    }
    
    if from.bot != nil || targetting.bot != nil {
        permissions = permissions.union(UserPermissions.sendMessage)
    }
    
    return permissions
}
