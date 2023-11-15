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
                NavigationLink(destination: ProfileSettings.init) {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                
                NavigationLink(destination: SessionsSettings.init) {
                    Image(systemName: "shield.fill")
                    Text("Sessions")
                }
                
                NavigationLink {
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
                } label: {
                    Image(systemName: "paintpalette.fill")
                    Text("Appearance")
                }
            }
            .listRowBackground(viewState.theme.background2.color)

            
            Section("Misc") {
                NavigationLink(destination: About.init) {
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
