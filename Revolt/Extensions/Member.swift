//
//  Member.swift
//  Revolt
//
//  Created by Angelo on 2024-07-18.
//

import Foundation
import Types
import SwiftUI

extension Member {
    public func displayColour(theme: Theme, server: Server) -> AnyShapeStyle? {
        roles?
            .compactMap { server.roles?[$0] }
            .sorted(by: { $0.rank > $1.rank })
            .compactMap(\.colour)
            .last
            .map {
                return parseCSSColor(currentTheme: theme, input: $0)
            }
    }
}
