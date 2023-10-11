//
//  User.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation

struct User: Identifiable, Codable {
    var id: String
    var username: String
    var avatar: String
}
