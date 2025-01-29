//
//  Bot.swift
//  Types
//
//  Created by Angelo on 03/10/2024.
//

import Foundation

public struct Bot: Codable, Identifiable, Equatable {
    public var id: String

    public var owner: String
    public var token: String
    public var isPublic: Bool
    public var analytics: Bool?
    public var discoverable: Bool?
    public var interactions_url: String?
    public var terms_of_service_url: String?
    public var privacy_policy_url: String?
    public var flags: Int?
    public var user: User?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case isPublic = "public"
        case owner, token, analytics, discoverable, interactions_url, terms_of_service_url, privacy_policy_url, flags, user
    }
}
