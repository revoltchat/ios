//
//  AnyTransition.swift
//  Revolt
//
//  Created by Angelo on 2024-07-14.
//

import SwiftUI

extension AnyTransition {
    static var slideNext: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading))
    }
    
    static var slideTop: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .top),
            removal: .move(edge: .top))
    }
}
