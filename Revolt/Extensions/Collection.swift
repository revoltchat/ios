//
//  Collection.swift
//  Revolt
//
//  Created by Angelo on 19/06/2024.
//

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
