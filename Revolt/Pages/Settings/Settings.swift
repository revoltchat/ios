//
//  Settings.swift
//  Revolt
//
//  Created by Angelo on 18/10/2023.
//

import Foundation
import SwiftUI

enum CurrentSettingsPage: Hashable {
    case profile
    case sessions
    case appearance
    case about
}

struct Settings: View {
    @EnvironmentObject var viewState: ViewState

    @State var currentPage: CurrentSettingsPage? = nil
    
    var body: some View {
        NavigationSplitView {
            List(selection: $currentPage) {
                Section("Revolt") {
                    NavigationLink(value: CurrentSettingsPage.profile) {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
                    
                    NavigationLink(value: CurrentSettingsPage.sessions) {
                        Image(systemName: "shield.fill")
                        Text("Sessions")
                    }
                    
                    NavigationLink(value: CurrentSettingsPage.appearance) {
                        Image(systemName: "paintpalette.fill")
                        Text("Appearance")
                    }
                }
                .listRowBackground(viewState.theme.background2.color)
                
                Section("Misc") {
                    NavigationLink(value: CurrentSettingsPage.about) {
                        Image(systemName: "info.circle.fill")
                        Text("About")
                    }
                    
                    Button {
                        viewState.logout()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.left.square")
                                .foregroundStyle(.red)
                            Text("Logout")
                                .foregroundStyle(.red)
                        }
                    }
                }
                .listRowBackground(viewState.theme.background2.color)
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
            .background(viewState.theme.background.color)
        } detail: {
            if let page = currentPage {
                switch page {
                    case .profile:
                        ProfileSettings()
                    case .sessions:
                        SessionsSettings()
                    case .appearance:
                        AppearanceSettings(
                            accent: viewState.theme.accent.color,
                            background: viewState.theme.background.color,
                            background2: viewState.theme.background2.color,
                            textColor: viewState.theme.foreground.color,
                            messageBox: viewState.theme.messageBox.color,
                            messageBoxBackground: viewState.theme.messageBoxBackground.color,
                            topBar: viewState.theme.topBar.color,
                            messageBoxBorder: viewState.theme.messageBoxBorder.color
                        )
                    case .about:
                        About()
                }
            }
        }
    }
}
