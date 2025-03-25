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
        List {
            Button {
                Task {
                    await viewState.promptForNotifications()
                }
            } label: {
                Text("Force remote notification upload")
            }
            .listRowBackground(viewState.theme.background2)

            Section("Api Url") {
                TextField("Api Url", text: Binding {
                    try! ViewState.decodeUserDefaults(forKey: "apiUrl") ?? DEFAULT_API_URL
                } set: {
                    UserDefaults.standard.set(try! JSONEncoder().encode($0), forKey: "apiUrl")
                    try! viewState.keychain.remove("sessionToken")
                })
                .foregroundStyle(viewState.theme.foreground2)
                
                Button("Sign out and switch instance") {
                    Task {
                        try! await viewState.signOut().get()
                    }
                }
                .foregroundStyle(viewState.theme.error)
            }
            .listRowBackground(viewState.theme.background2)
        }
        .background(viewState.theme.background)
        .scrollContentBackground(.hidden)
        .toolbarBackground(viewState.theme.topBar, for: .automatic)
        .navigationTitle("Developer")
    }
}
