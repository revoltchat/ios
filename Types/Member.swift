//
//  Member.swift
//  Revolt
//
//  Created by Angelo on 12/10/2023.
//

import Foundation

public struct MemberId: Decodable, Equatable {
    public init(server: String, user: String) {
        self.server = server
        self.user = user
    }
    
    public var server: String
    public var user: String
}

public struct Member: Decodable, Equatable {
    public init(id: MemberId, nickname: String? = nil, avatar: File? = nil, roles: [String]? = nil, joined_at: String, timeout: String? = nil) {
        self.id = id
        self.nickname = nickname
        self.avatar = avatar
        self.roles = roles
        self.joined_at = joined_at
        self.timeout = timeout
    }
    
    public var id: MemberId
    public var nickname: String?
    public var avatar: File?
    public var roles: [String]?
    public var joined_at: String
    public var timeout: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case nickname, avatar, roles, joined_at, timeout
    }
}
