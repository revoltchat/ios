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

    @State var currentPage: CurrentSettingsPage? = .language
    
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
                
                NavigationLink(destination: { AppearanceSettings(
                    accent: viewState.theme.accent.color,
                    background: viewState.theme.background.color,
                    background2: viewState.theme.background2.color,
                    textColor: viewState.theme.foreground.color,
                    messageBox: viewState.theme.messageBox.color,
                    topBar: viewState.theme.topBar.color
                )}) {
                    Image(systemName: "paintpalette.fill")
                    Text("Appearance")
                }
                
                NavigationLink(destination: LanguageSettings.init) {
                    Image(systemName: "globe")
                    Text("Language")
                }
            }
            .listRowBackground(viewState.theme.background2)
            
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
            .listRowBackground(viewState.theme.background2)
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Settings")
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
