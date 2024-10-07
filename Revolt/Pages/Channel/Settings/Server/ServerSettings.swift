//
//  ServerSettings.swift
//  Revolt
//
//  Created by Angelo on 08/11/2023.
//

import Foundation
import SwiftUI
import Types

struct ServerSettings: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var server: Server
    
    var body: some View {
        List {
            Section("Settings") {
                NavigationLink {
                    ServerOverviewSettings(server: $server)
                } label: {
                    Image(systemName: "info.circle.fill")
                    Text("Overview")
                }
                
                NavigationLink(destination: Text("Todo")) {
                    Image(systemName: "list.bullet")
                    Text("Categories")
                }

                NavigationLink {
                    ServerRolesSettings(server: $server)
                } label: {
                    Image(systemName: "flag.fill")
                    Text("Roles")
                }
            }
            .listRowBackground(viewState.theme.background2)
            
            Section("Customisation") {
                NavigationLink {
                    ServerEmojiSettings(server: $server)
                } label: {
                    Image(systemName: "face.smiling")
                    Text("Emojis")
                }
            }
            .listRowBackground(viewState.theme.background2)
            
            Section("User Management") {
                NavigationLink(destination: Text("Todo")) {
                    Image(systemName: "person.2.fill")
                    Text("Members")
                }
                
                NavigationLink(destination: Text("Todo")) {
                    Image(systemName: "envelope.fill")
                    Text("Invites")
                }
                
                NavigationLink {
                    ServerBanSettings(server: $server)
                } label: {
                    Image(systemName: "person.fill.xmark")
                    Text("Bans")
                }
            }
            .listRowBackground(viewState.theme.background2)
            
            Button {
                
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete server")
                }
                .foregroundStyle(.red)
            }
            .listRowBackground(viewState.theme.background2)
            
        }
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    ServerIcon(server: server, height: 24, width: 24, clipTo: Circle())
                    Text(verbatim: server.name)
                }
            }
        }
        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
    }
}


#Preview {
    let viewState = ViewState.preview()

    return NavigationStack {
        ServerSettings(server: .constant(viewState.servers["0"]!))
            .applyPreviewModifiers(withState: viewState)
    }
}
