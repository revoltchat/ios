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
    case language
    case about
}

struct Settings: View {
    @EnvironmentObject var viewState: ViewState

    var body: some View {
        List {
            Section("User Settings") {
                NavigationLink(destination: { UserSettings(viewState: viewState) }) {
                    Image(systemName: "person.fill")
                    Text("My Account")
                }
                NavigationLink(destination: ProfileSettings()) {
                    Image(systemName: "person.text.rectangle.fill")
                    Text("Profile")
                }
                
                NavigationLink(destination: SessionsSettings()) {
                    Image(systemName: "checkmark.shield.fill")
                    Text("Sessions")
                }
            }
            .listRowBackground(viewState.theme.background2)

            Section("Client Settings") {
                NavigationLink(destination: AppearanceSettings()) {
                    Image(systemName: "paintpalette.fill")
                    Text("Appearance")
                }

                NavigationLink(destination: { NotificationSettings() }) {
                    Image(systemName: "bell.fill")
                    Text("Notifications")
                }
                NavigationLink(destination: LanguageSettings()) {
                    Image(systemName: "globe")
                    Text("Language")
                }
            }
            .listRowBackground(viewState.theme.background2)

            Section("Misc") {
                NavigationLink(destination: About()) {
                    Image(systemName: "info.circle.fill")
                    Text("About")
                }
                NavigationLink(destination: ExperimentsSettings()) {
                    Image(systemName: "flask.fill")
                    Text("Experiments")
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
            .listRowBackground(viewState.theme.background2)
        }
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(String(localized: "Settings", comment: "Settings Tooltip"))
            }
        }
        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
        .background(viewState.theme.background)
    }
}


#Preview {
    Settings()
        .applyPreviewModifiers(withState: ViewState.preview())
}
