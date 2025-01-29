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
        }
        .background(viewState.theme.background)
        .scrollContentBackground(.hidden)
        .toolbarBackground(viewState.theme.topBar, for: .automatic)
        .navigationTitle("Developer")
    }
}
