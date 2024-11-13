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

    @State var presentLogoutDialog = false

    var body: some View {
        List {
            Section("User Settings") {
                NavigationLink(destination: { UserSettings() }) {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("My Account")
                }
                NavigationLink(destination: { ProfileSettings() }) {
                    Image(systemName: "person.text.rectangle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Profile")
                }

                NavigationLink(destination: { SessionsSettings() }) {
                    Image(systemName: "checkmark.shield.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Sessions")
                }
            }
            .listRowBackground(viewState.theme.background2)

            Section("Client Settings") {
                NavigationLink(destination: { AppearanceSettings() }) {
                    Image(systemName: "paintpalette.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Appearance")
                }

                NavigationLink(destination: { NotificationSettings() }) {
                    Image(systemName: "bell.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Notifications")
                }
                NavigationLink(destination: { LanguageSettings() }) {
                    Image(systemName: "globe")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Language")
                }
            }
            .listRowBackground(viewState.theme.background2)
            

            Section("Revolt") {
                NavigationLink {
                    BotSettings()
                } label: {
                    Image(systemName: "desktopcomputer")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Bots")
                }

            }.listRowBackground(viewState.theme.background2)

            Section("Misc") {
                NavigationLink(destination: About()) {
                    Image(systemName: "info.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("About")
                }
                NavigationLink(destination: { ExperimentsSettings() }) {
                    Image(systemName: "flask.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Experiments")
                }
#if DEBUG
                NavigationLink(destination: { DeveloperSettings() }) {
                    Image(systemName: "hammer.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Developer")
                }
#endif
            }
            .listRowBackground(viewState.theme.background2)
            
            Section {
                Button {
                    presentLogoutDialog = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.left.square")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.red)
                            .frame(width: 16, height: 16)
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
        .confirmationDialog("Are you sure?", isPresented: $presentLogoutDialog, titleVisibility: .visible) {
            Button("Yes", role: .destructive) {
                Task {
                    await viewState.signOut()
                }
            }
            .keyboardShortcut(.defaultAction)
            Button("Wait!", role: .cancel) {
                presentLogoutDialog = false
            }
            .keyboardShortcut(.cancelAction)
        }
    }
}


#Preview {
    Settings()
        .applyPreviewModifiers(withState: ViewState.preview())
}
