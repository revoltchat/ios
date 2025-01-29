//
//  Member.swift
//  Revolt
//
//  Created by Angelo on 12/10/2023.
//

import Foundation

public struct MemberId: Codable, Equatable, Identifiable, Hashable {
    public init(server: String, user: String) {
        self.server = server
        self.user = user
    }
    
    public var server: String
    public var user: String
    
    public var id: String {
        "\(server)\(user)"
    }
}

public struct Member: Codable, Equatable {
    public init(id: MemberId, nickname: String? = nil, avatar: File? = nil, roles: [String]? = nil, joined_at: String, timeout: String? = nil, can_publish: Bool? = nil, can_receive: Bool? = nil) {
        self.id = id
        self.nickname = nickname
        self.avatar = avatar
        self.roles = roles
        self.joined_at = joined_at
        self.timeout = timeout
        self.can_publish = can_publish
        self.can_receive = can_receive
    }
    
    public var id: MemberId
    public var nickname: String?
    public var avatar: File?
    public var roles: [String]?
    public var joined_at: String
    public var timeout: String?
    public var can_publish: Bool?
    public var can_receive: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case nickname, avatar, roles, joined_at, timeout, can_publish, can_receive
    }
}
