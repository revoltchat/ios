//
//  LanguageSettings.swift
//  Revolt
//
//  Created by Angelo on 29/11/2023.
//

import Foundation
import SwiftUI

struct LanguageSettings: View {
    @Environment(\.locale) var systemLocale: Locale
    @EnvironmentObject var viewState: ViewState

    var currentLocale: Locale { viewState.currentLocale ?? systemLocale }
    
    var body: some View {
        List {
            Button {
                viewState.currentLocale = nil
            } label: {
                Text("Auto")
            }
            .frame(maxWidth: .infinity, maxHeight: 30)
            .padding(8)
            .foregroundStyle(viewState.currentLocale == nil ? viewState.theme.accent : viewState.theme.foreground)
            .listRowBackground(viewState.theme.background2)
            
            ForEach(Locale.availableIdentifiers.sorted(), id: \.self) { ident in
                let locale = Locale(identifier: ident)
                
                Button {
                    viewState.currentLocale = locale
                } label: {
                    Text(currentLocale.localizedString(forIdentifier: ident) ?? "Unknown")
                        .foregroundStyle(locale == currentLocale ? viewState.theme.accent : viewState.theme.foreground)
                }
                .frame(maxWidth: .infinity, maxHeight: 30)
                .padding(8)
                .listRowBackground(viewState.theme.background2)

            }
        }
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background)
        .navigationTitle("Language")
        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
    }
}


#Preview {
    return NavigationStack {
        LanguageSettings()
    }
        .applyPreviewModifiers(withState: ViewState.preview())
}
