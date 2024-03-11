//
//  Member.swift
//  Revolt
//
//  Created by Angelo on 12/10/2023.
//

import Foundation
import SwiftUI

struct MemberId: Decodable, Equatable {
    var server: String
    var user: String
}

struct Member: Decodable, Equatable {
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
    
    func displayColour(theme: Theme, server: Server) -> AnyShapeStyle? {
        roles?
            .compactMap { server.roles?[$0] }
            .sorted(by: { $0.rank > $1.rank })
            .compactMap(\.colour)
            .last
            .map {
                print($0)
                return parseCSSColor(currentTheme: theme, input: $0)
            }
    }
}
