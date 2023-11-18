//
//  MessageBadge.swift
//  Revolt
//
//  Created by Angelo on 18/11/2023.
//

import Foundation
import SwiftUI

struct MessageBadge: View {
    var text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color, in: RoundedRectangle(cornerRadius: 5))
    }
}

#Preview {
    MessageBadge(text: "Masquerade", color: .teal)
}

#Preview {
    MessageBadge(text: "Bot", color: .purple)
}
