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
    @Environment(\.editMode) var editMode: Binding<EditMode>?

    var currentLocale: Locale { viewState.currentLocale ?? systemLocale }
    
    var body: some View {
        ScrollView {
            Button {
                viewState.currentLocale = nil
            } label: {
                Text("Auto")
            }
            .frame(maxWidth: .infinity, maxHeight: 30)
            .padding()
            .background(viewState.currentLocale == nil ? viewState.theme.background.color : viewState.theme.background2.color)
            
            ForEach(Locale.availableIdentifiers.sorted(), id: \.self) { ident in
                let locale = Locale(identifier: ident)
                
                Button {
                    viewState.currentLocale = locale
                } label: {
                    Text(currentLocale.localizedString(forIdentifier: ident) ?? "Unknown")
                }
                .frame(maxWidth: .infinity, maxHeight: 30)
                .padding()
                .background(locale == currentLocale ? viewState.theme.background.color : viewState.theme.background2.color)
            }
        }
    }
}
