//
//  ServerSettings.swift
//  Revolt
//
//  Created by Angelo on 08/11/2023.
//

import Foundation
import SwiftUI

struct ServerSettings: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var server: Server
    
    var body: some View {
        let server = viewState.currentServer.id.flatMap { viewState.servers[$0] }!
        
        VStack(alignment: .center) {
            Group {
                ServerIcon(server: server, height: 48, width: 48, clipTo: RoundedRectangle(cornerRadius: 12))
                Text(verbatim: server.name)
            }
            
            List {
                Section("Settings") {
                    NavigationLink(destination: { ServerOverviewSettings.fromState(viewState: viewState, server: $server) }) {
                        Image(systemName: "info.circle.fill")
                        Text("Overview")
                    }
                    
                    NavigationLink(destination: Text("Todo")) {
                        Image(systemName: "list.bullet")
                        Text("Categories")
                    }

                    NavigationLink(destination: Text("Todo")) {
                        Image(systemName: "flag.fill")
                        Text("Roles")
                    }
                }
                .listRowBackground(viewState.theme.background2)
                
                Section("Customisation") {
                    NavigationLink(destination: Text("Todo")) {
                        Image(systemName: "flag.fill")
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
                    
                    NavigationLink(destination: Text("Todo")) {
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
        }
        .background(viewState.theme.background)
    }
}


#Preview {
    let viewState = ViewState.preview()

    return NavigationStack {
        ServerSettings(server: .constant(viewState.servers["0"]!))
            .applyPreviewModifiers(withState: viewState)
    }
}
