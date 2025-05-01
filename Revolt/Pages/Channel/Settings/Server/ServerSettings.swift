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
    
    @State var userPermissions: Permissions = Permissions.all
    
    var body: some View {
        List {
            Section("Settings") {
                if userPermissions.contains(.manageServer) {
                    NavigationLink {
                        ServerOverviewSettings(server: $server)
                    } label: {
                        Image(systemName: "info.circle.fill")
                        Text("Overview")
                    }
                }
                
                if userPermissions.contains(.manageChannel) {
                    NavigationLink(destination: Text("Todo")) {
                        Image(systemName: "list.bullet")
                        Text("Categories")
                    }
                }

                if userPermissions.contains(.manageRole) {
                    NavigationLink {
                        ServerRolesSettings(server: $server)
                    } label: {
                        Image(systemName: "flag.fill")
                        Text("Roles")
                    }
                }
            }
            .listRowBackground(viewState.theme.background2)
            
            Section("Customisation") {
                if userPermissions.contains(.manageCustomisation) {
                    NavigationLink {
                        ServerEmojiSettings(server: $server)
                    } label: {
                        Image(systemName: "face.smiling")
                        Text("Emojis")
                    }
                }
            }
            .listRowBackground(viewState.theme.background2)
            
            Section("User Management") {
                NavigationLink(destination: Text("Todo")) {
                    Image(systemName: "person.2.fill")
                    Text("Members")
                }
                
                if userPermissions.contains(.manageServer) {
                    NavigationLink(destination: Text("Todo")) {
                        Image(systemName: "envelope.fill")
                        Text("Invites")
                    }
                }
                
                if userPermissions.contains(.banMembers) {
                    NavigationLink {
                        ServerBanSettings(server: $server)
                    } label: {
                        Image(systemName: "person.fill.xmark")
                        Text("Bans")
                    }
                }
            }
            .listRowBackground(viewState.theme.background2)
            
            if server.owner == viewState.currentUser?.id {
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
        .task {
            if let user = viewState.currentUser, let member = viewState.members[server.id]?[user.id] {
                userPermissions = resolveServerPermissions(user: user, member: member, server: server)
            }
        }
    }
}


#Preview {
    let viewState = ViewState.preview()

    return NavigationStack {
        ServerSettings(server: .constant(viewState.servers["0"]!))
            .applyPreviewModifiers(withState: viewState)
    }
}
