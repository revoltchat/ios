//
//  Image.swift
//  Revolt
//
//  Created by Angelo Manca on 2024-07-18.
//

import Foundation
import SwiftUI
import Types

extension Image {
    /// Inverts the image depending on the lightness of color
    /// This is specifically designed for use in the sessions settings menu
    @ViewBuilder
    public func maybeColorInvert(color: ThemeColor, isDefaultImage: Bool, defaultIsLight: Bool = true) -> some View {
        if isDefaultImage {
            self
        } else {
            let isLight = Theme.isLightOrDark(color)
            
            if isLight && defaultIsLight {
                self.colorInvert()
            } else if !isLight && !defaultIsLight {
                self.colorInvert()
            } else {
                self
            }
        }
    }
}
