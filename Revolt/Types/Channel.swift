//
//  Channel.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation

class Channel: Identifiable {
    var id: String
    var name: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

class TextChannel: Channel {
    internal init(id: String, name: String, description: String?) {
        self.description = description

        super.init(id: id, name: name)
    }
    
    var description: String?
}
