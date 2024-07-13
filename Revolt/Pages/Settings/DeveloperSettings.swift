//
//  DeveloperSettings.swift
//  Revolt
//
//  Created by Angelo Manca on 2024-07-12.
//

import SwiftUI

struct DeveloperSettings: View {
    @EnvironmentObject var viewState: ViewState

    var body: some View {
        Button(action: {
            Task {
                await viewState.promptForNotifications()
            }
        }) {
            Text("Force remote notification upload")
        }
    }
}
