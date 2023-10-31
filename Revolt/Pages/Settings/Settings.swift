//
//  Settings.swift
//  Revolt
//
//  Created by Angelo on 18/10/2023.
//

import Foundation
import SwiftUI

struct Settings: View {
    @EnvironmentObject var viewState: ViewState

    var body: some View {
        List {
            Section("Revolt") {
                NavigationLink("Profile", destination: ProfileSettings.init)
                    .listRowBackground(viewState.theme.background2.color)
                
                NavigationLink("Appearance") {
                    AppearanceSettings(
                        accent: viewState.theme.accent.color,
                        background: viewState.theme.background.color,
                        background2: viewState.theme.background2.color,
                        textColor: viewState.theme.textColor.color,
                        messageBox: viewState.theme.messageBox.color,
                        messageBoxBackground: viewState.theme.messageBoxBackground.color,
                        topBar: viewState.theme.topBar.color,
                        messageBoxBorder: viewState.theme.messageBoxBorder.color
                    )
                }
                .listRowBackground(viewState.theme.background2.color)
            }
            
            Section("Misc") {
                NavigationLink("About", destination: About.init)
                    .listRowBackground(viewState.theme.background2.color)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background.color)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Settings")
            }
        }
        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
    }
}
