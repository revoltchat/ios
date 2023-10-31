//
//  Theme.swift
//  Revolt
//
//  Created by Angelo on 31/10/2023.
//

import Foundation
import SwiftUI

struct ThemeColor: Codable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double
    
    init(r: Double, g: Double, b: Double, a: Double) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
    
    init(fromHex: String) {
        var hex = fromHex
        hex.trimPrefix("#")
        
        let int = Int(hex, radix: 16)!
        
        r = 255.0 / Double(int >> 24)
        g = 255.0 / Double(int >> 16 & 0xFF)
        b = 255.0 / Double(int >> 8 & 0xFF)
        a = 255.0 / Double(int & 0xFF)
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
    
    var color: Color {
        Color(red: r, green: g, blue: b, opacity: a)
    }
    
    static var white: ThemeColor {
        ThemeColor(r: 1, g: 1, b: 1, a: 1)
    }
    
    static var black: ThemeColor {
        ThemeColor(r: 0, g: 0, b: 0, a: 1)
    }
}

struct Theme: Codable {
    var accent: ThemeColor
    var background: ThemeColor
    var background2: ThemeColor
    var textColor: ThemeColor
    var messageBox: ThemeColor
    var messageBoxBackground: ThemeColor
    var topBar: ThemeColor
    var messageBoxBorder: ThemeColor
    
    static var light: Theme {
        Theme(
            accent: ThemeColor.init(fromHex: "#FD6671FF"),
            background: ThemeColor.white,
            background2: ThemeColor.white,
            textColor: ThemeColor.black,
            messageBox: ThemeColor.white,
            messageBoxBackground: ThemeColor.white,
            topBar: ThemeColor(fromHex: "#FFFFFFAA"),
            messageBoxBorder: ThemeColor.black
        )
    }
    
    init(
        accent: ThemeColor,
        background: ThemeColor,
        background2: ThemeColor,
        textColor: ThemeColor,
        messageBox: ThemeColor,
        messageBoxBackground: ThemeColor,
        topBar: ThemeColor,
        messageBoxBorder: ThemeColor
    ) {
        self.accent = accent
        self.background = background
        self.background2 = background2
        self.textColor = textColor
        self.messageBox = messageBox
        self.messageBoxBackground = messageBoxBackground
        self.topBar = topBar
        self.messageBoxBorder = messageBoxBorder
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accent = try container.decodeIfPresent(ThemeColor.self, forKey: .accent) ?? Theme.light.accent
        self.background = try container.decodeIfPresent(ThemeColor.self, forKey: .background) ?? Theme.light.background
        self.background2 = try container.decodeIfPresent(ThemeColor.self, forKey: .background2) ?? Theme.light.background2
        self.textColor = try container.decodeIfPresent(ThemeColor.self, forKey: .textColor) ?? Theme.light.textColor
        self.messageBox = try container.decodeIfPresent(ThemeColor.self, forKey: .messageBox) ?? Theme.light.messageBox
        self.messageBoxBackground = try container.decodeIfPresent(ThemeColor.self, forKey: .messageBoxBackground) ?? Theme.light.messageBoxBackground
        self.topBar = try container.decodeIfPresent(ThemeColor.self, forKey: .topBar) ?? Theme.light.topBar
        self.messageBoxBorder = try container.decodeIfPresent(ThemeColor.self, forKey: .messageBoxBorder) ?? Theme.light.messageBoxBorder
    }
}
