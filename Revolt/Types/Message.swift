//
//  Message.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation

struct Message: Identifiable {
    var id: String
    
    var content: String
    var author: String
    var createdAt: Date
    var channel: String
}
