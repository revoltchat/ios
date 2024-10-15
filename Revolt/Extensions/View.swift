//
//  View.swift
//  Revolt
//
//  Created by Angelo on 2024-03-10.
//

import Foundation
import SwiftUI

extension View {
    // Stole this from stackoverflow:tm:
    // https://stackoverflow.com/questions/57753997/rounded-borders-in-swiftui
    public func addBorder<S>(_ content: S, width: CGFloat = 1, cornerRadius: CGFloat) -> some View where S : ShapeStyle {
        let roundedRect = RoundedRectangle(cornerRadius: cornerRadius)
        return clipShape(roundedRect)
             .overlay(roundedRect.strokeBorder(content, lineWidth: width))
    }
    
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder()
                .opacity(shouldShow ? 1 : 0)
                .allowsHitTesting(false)
            self
        }
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            content(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func `if`<Content: View, Else: View>(_ conditional: Bool, content: (Self) -> Content, else other: (Self) -> Else) -> some View {
        if conditional {
            content(self)
        } else {
            other(self)
        }
    }
    
    @MainActor
    func applyPreviewModifiers(withState viewState: ViewState) -> some View {
        self.environmentObject(viewState)
            .tint(viewState.theme.accent.color)
            .foregroundStyle(viewState.theme.foreground.color)
            .background(viewState.theme.background.color)
        
    }
    
    @MainActor
    func alertPopup<V: View>(show: Bool, @ViewBuilder content: @escaping () -> V) -> some View {
        AlertPopup(show: show, inner: self, popup: content)
    }
    
    @MainActor
    func alertPopup(content: String, show: Bool) -> some View {
        self.alertPopup(show: show) {
            Text(content)
        }
    }
    
    @MainActor
    func alertPopup(content: String?) -> some View {
        self.alertPopup(show: content != nil) {
            Text(content ?? "")
        }
    }
}
