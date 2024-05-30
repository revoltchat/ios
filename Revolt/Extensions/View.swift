//
//  View.swift
//  Revolt
//
//  Created by Angelo on 2024-03-10.
//

import Foundation
import SwiftUI

// Stole this from stackoverflow:tm:
// https://stackoverflow.com/questions/57753997/rounded-borders-in-swiftui
extension View {
    public func addBorder<S>(_ content: S, width: CGFloat = 1, cornerRadius: CGFloat) -> some View where S : ShapeStyle {
        let roundedRect = RoundedRectangle(cornerRadius: cornerRadius)
        return clipShape(roundedRect)
             .overlay(roundedRect.strokeBorder(content, lineWidth: width))
    }
}
