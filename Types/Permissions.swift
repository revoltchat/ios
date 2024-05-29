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

public struct Permissions: OptionSet {
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
    public var a: Permissions
    public var d: Permissions
}
