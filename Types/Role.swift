//
//  Role.swift
//  Types
//
//  Created by Angelo on 19/05/2024.
//

import Foundation

public struct Role: Decodable, Equatable {
    public var name: String
    public var permissions: Overwrite
    public var colour: String?
    public var hoist: Bool?
    public var rank: Int
}
