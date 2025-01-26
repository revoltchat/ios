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
                NavigationLink {
                    UserSettings()
                } label: {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("My Account")
                }
                NavigationLink {
                    ProfileSettings()
                } label: {
                    Image(systemName: "person.text.rectangle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Profile")
                }

                NavigationLink {
                    SessionsSettings()
                } label: {
                    Image(systemName: "checkmark.shield.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Sessions")
                }
            }
            .listRowBackground(viewState.theme.background2)

            Section("Client Settings") {
                NavigationLink {
                    AppearanceSettings()
                } label: {
                    Image(systemName: "paintpalette.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Appearance")
                }

                NavigationLink {
                    NotificationSettings()
                } label: {
                    Image(systemName: "bell.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Notifications")
                }
                NavigationLink {
                    LanguageSettings()
                } label: {
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
                NavigationLink {
                    About()
                } label: {
                    Image(systemName: "info.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("About")
                }
                NavigationLink {
                    ExperimentsSettings()
                } label: {
                    Image(systemName: "flask.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Experiments")
                }
#if DEBUG
                NavigationLink {
                    DeveloperSettings()
                } label: {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Settings")
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
