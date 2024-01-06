//
//  Theme.swift
//  Revolt
//
//  Created by Angelo on 31/10/2023.
//

import Foundation
import SwiftUI
import CodableWrapper

@Codable
struct ThemeColor: Equatable, ShapeStyle, View {
    var r: Double
    var g: Double
    var b: Double
    var a: Double
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
            case 3: // RGB (12-bit)
                (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
            case 6: // RGB (24-bit)
                (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
            case 8: // RGBA (32-bit)
                (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            default:
                (r, g, b, a) = (1, 1, 1, 0)
        }
        
        self.init(
            r: Double(r) / 255,
            g: Double(g) / 255,
            b:  Double(b) / 255,
            a: Double(a) / 255
        )
    }

    mutating func set(with: Color.Resolved) {
        self.r = Double(with.red)
        
        if self.r == Double.infinity {
            self.r = 1.0
        }
        
        self.g = Double(with.green)
        
        if self.g == Double.infinity {
            self.g = 1.0
        }
        
        self.b = Double(with.blue)
        
        if self.b == Double.infinity {
            self.b = 1.0
        }
        
        self.a = Double(with.opacity)
        
        if self.a == Double.infinity {
            self.a = 1.0
        }
        
    }
    
    func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        color.resolve(in: environment)
    }
    
    var color: Color {
        Color(red: r, green: g, blue: b, opacity: a)
    }
    
    static var white: ThemeColor = ThemeColor(hex: "#FFFFFFFF")
    static var black: ThemeColor = ThemeColor(hex: "#000000FF")
}

@Codable
struct Theme: Codable, Equatable {
    var accent: ThemeColor = ThemeColor(hex: "#FD7771FF")
    var background: ThemeColor = ThemeColor.white
    var background2: ThemeColor = ThemeColor.white
    var foreground: ThemeColor = ThemeColor.black
    var foreground2: ThemeColor = ThemeColor(hex: "#3A3A3AFF")
    var foreground3: ThemeColor = ThemeColor(hex: "#1F1F1FFF")
    var messageBox: ThemeColor = ThemeColor.white
    var messageBoxBackground: ThemeColor = ThemeColor.white
    var topBar: ThemeColor = ThemeColor(hex: "#FFFFFFAA")
    var messageBoxBorder: ThemeColor = ThemeColor.black
    var shouldFollowiOSTheme: Bool = false
    
    static var light: Theme {
        Theme(
            accent: ThemeColor(hex: "#FD7771FF"),
            background: ThemeColor.white,
            background2: ThemeColor(hex: "#F5F5F5FF"),
            foreground: ThemeColor.black,
            foreground2: ThemeColor(hex: "#1F1F1FFF"),
            foreground3: ThemeColor(hex: "#3A3A3AFF"),
            messageBox: ThemeColor.white,
            messageBoxBackground: ThemeColor.white,
            topBar: ThemeColor(hex: "#FFFFFFEE"),
            messageBoxBorder: ThemeColor.black,
            shouldFollowiOSTheme: false
        )
    }

    static var dark: Theme {
        Theme(
            accent: ThemeColor(hex: "#FD7771FF"),
            background: ThemeColor(hex: "#191919FF"),
            background2: ThemeColor(hex:"#242424FF"),
            foreground: ThemeColor.white,
            foreground2: ThemeColor(hex: "#C8C8C8FF"),
            foreground3: ThemeColor(hex: "#848484FF"),
            messageBox: ThemeColor(hex:"#363636FF"),
            messageBoxBackground: ThemeColor(hex:"#363636FF"),
            topBar: ThemeColor(hex: "#191919EE"),
            messageBoxBorder: ThemeColor.white,
            shouldFollowiOSTheme: false
        )
    }
}
