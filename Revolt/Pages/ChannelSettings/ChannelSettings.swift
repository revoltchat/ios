//
//  ChannelSettiings.swift
//  Revolt
//
//  Created by Angelo on 08/01/2024.
//

import Foundation
import SwiftUI

struct ChannelSettings: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var channel: Channel
    
    var body: some View {
        List {
            Section("Settings") {
                NavigationLink(destination: { ChannelOverviewSettings.fromState(viewState: viewState, channel: $channel) }) {
                    Image(systemName: "info.circle.fill")
                    Text("Overview")
                }
                
                NavigationLink(destination: Text("Todo")) {
                    Image(systemName: "list.bullet")
                    Text("Permissions")
                }
            }
            .listRowBackground(viewState.theme.background2)
            
            Button {
                
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete channel")
                }
                .foregroundStyle(.red)
            }
            .listRowBackground(viewState.theme.background2)

        }
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background)
        .toolbar {
            ToolbarItem(placement: .principal) {
                ChannelIcon(channel: channel)
            }
        }
        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)

    }
}

#Preview {
    let viewState = ViewState.preview().applySystemScheme(theme: .light)
    
    return NavigationStack {
        ChannelSettings(channel: .constant(viewState.channels["0"]!))
    }.applyPreviewModifiers(withState: viewState)
}
