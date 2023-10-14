//
//  Role.swift
//  Revolt
//
//  Created by Angelo on 14/10/2023.
//

import Foundation

struct Role: Decodable {
    var name: String
    var permissions: Overwrite
    var colour: String?
    var hoist: Bool?
    var rank: Int
}
