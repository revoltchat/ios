//
//  ExperimentsSettings.swift
//  Revolt
//
//  Created by Angelo on 2024-02-10.
//

import SwiftUI

struct ExperimentsSettings: View {
    @EnvironmentObject var viewState: ViewState
    
    var body: some View {
        List {
            CheckboxListItem(title: "Enable Custom Markdown", isOn: $viewState.userSettingsStore.store.experiments.customMarkdown)
                .listRowBackground(viewState.theme.background2)
        }
        .background(viewState.theme.background)
        .scrollContentBackground(.hidden)
        .toolbarBackground(viewState.theme.topBar, for: .automatic)
        .navigationTitle("Experiments")
    }

}

#Preview {
    ExperimentsSettings()
}
