//
//  Section.swift
//  Revolt
//
//  Created by Angelo on 29/10/2024.
//

import SwiftUI


extension Section {
    init(_ title: String, content: @escaping () -> Content, footer: @escaping () -> Footer) where Parent == Text, Content: View, Footer: View {
        self.init(content: content, header: { Text(title) }, footer: footer)
    }
}
