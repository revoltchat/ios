//
//  PresenceIndicator.swift
//  Revolt
//
//  Created by Angelo on 31/10/2023.
//

import Foundation
import SwiftUI

let colours: [Presence?: Color] = [
    .Online: Color(.green),
    .Busy: Color(.red),
    .Idle: Color(.yellow),
    .Focus: Color(.blue),
    .Invisible: Color(.gray),
    nil: Color(.gray)
]

struct PresenceIndicator: View {
    var presence: Presence?
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    
    var body: some View {
        let colour = colours[presence]!
        
        Circle()
            .stroke(.black, lineWidth: 1)
            .fill(colour)
            .frame(width: width, height: height)
    }
}
