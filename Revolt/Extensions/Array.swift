//
//  Array.swift
//  Revolt
//
//  Created by Angelo on 27/03/2025.
//

import Foundation


extension Array where Element: Identifiable {
    var ids: [Element.ID] {
        map(\.id)
    }
}
