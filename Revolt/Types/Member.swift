//
//  Member.swift
//  Revolt
//
//  Created by Angelo on 12/10/2023.
//

import Foundation
import SwiftUI

struct MemberId: Decodable {
    var server: String
    var user: String
}

struct Member: Decodable {
    var id: MemberId
    var nickname: String?
    var avatar: File?
    var roles: [String]?
    var joined_at: String
    var timeout: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case nickname, avatar, roles, joined_at, timeout
    }
    
    func displayColour(server: Server) -> Color? {
        roles?
            .compactMap { server.roles?[$0] }
            .sorted(by: { $0.rank > $1.rank })
            .compactMap(\.colour)
            .last
            .map { ThemeColor(hex: $0).color }
    }
}
