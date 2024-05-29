//
//  Permissions.swift
//  Revolt
//
//  Created by Angelo on 18/11/2023.
//

import Foundation
import Types

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
