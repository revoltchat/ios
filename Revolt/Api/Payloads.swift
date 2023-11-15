//
//  Payloads.swift
//  Revolt
//
//  Created by Tom on 2023-11-13.
//

import Foundation

struct AccountCreatePayload: Encodable {
    var email: String
    var password: String
    var invite: String?
    var captcha: String?
}
