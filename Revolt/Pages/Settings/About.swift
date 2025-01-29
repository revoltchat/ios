//
//  About.swift
//  Revolt
//
//  Created by Angelo on 31/10/2023.
//

import Foundation
import SwiftUI

struct About: View {
    @EnvironmentObject var viewState: ViewState

    var body: some View {
        VStack {
            Image("wide")

            Text("Revolt iOS")

            Text(Bundle.main.releaseVersionNumber!)
                .font(.caption)

            Spacer()
                .frame(height: 30)

            Text("Brought to you with ❤️ by the Revolt team.")
                .font(.footnote)
                .foregroundStyle(.gray)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("About")
            }
        }
        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)

        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(viewState.theme.background.color)
    }
}

struct About_Preview: PreviewProvider {
    static var previews: some View {
        About()
            .environmentObject(ViewState.preview())
    }
}
