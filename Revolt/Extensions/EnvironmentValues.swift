//
//  EnvironmentValues.swift
//  Revolt
//
//  Created by Angelo on 17/10/2024.
//

import SwiftUI
import Types

extension EnvironmentValues {
    @Entry var currentMessage: MessageContentsViewModel? = nil
    @Entry var currentServer: Server? = nil
    @Entry var currentChannel: Channel? = nil
}
