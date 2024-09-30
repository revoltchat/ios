//
//  ChannelPermissionsSettings.swift
//  Revolt
//
//  Created by Angelo on 25/09/2024.
//

import Foundation
import SwiftUI
import Types

struct ChannelPermissionsSettings: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var server: Server?
    @Binding var channel: Channel
    
    var body: some View {
        List {
            switch channel {
                case .saved_messages(let savedMessages):
                    EmptyView()
                case .dm_channel(let dMChannel):
                    EmptyView()
                case .group_dm_channel(var groupDMChannel):
                    AllPermissionSettings(
                        permissions: .defaultRole(Binding {
                            groupDMChannel.permissions ?? .defaultDirectMessages
                        } set: {
                            groupDMChannel.permissions = $0
                        }),
                        filter: [.readMessageHistory, .sendMessages, .manageMessages, .inviteOthers, .sendEmbeds, .uploadFiles, .masquerade, .react, .manageChannel, .managePermissions]
                    )
                    .listRowBackground(viewState.theme.background2)
                case .text_channel, .voice_channel:
                    Section {
                        ForEach(Array(server!.roles ?? [:]).sorted(by: { a, b in a.value.rank < b.value.rank }), id: \.key) { pair in
                            let roleColour = pair.value.colour.map { parseCSSColor(currentTheme: viewState.theme, input: $0) } ?? AnyShapeStyle(viewState.theme.foreground)
                            
                            NavigationLink {
                                let overwrite = channel.role_permissions?[pair.key] ?? Overwrite(a: .none, d: .none)
                                ChannelRolePermissionsSettings(server: Binding($server)!, channel: $channel, roleId: pair.key, permissions: .overwrite(overwrite))
                                    .toolbar {
                                        ToolbarItem(placement: .principal) {
                                            Text(verbatim: pair.value.name)
                                                .bold()
                                                .foregroundStyle(roleColour)
                                        }
                                    }
                            } label: {
                                Text(verbatim: pair.value.name)
                                    .foregroundStyle(roleColour)
                            }
                        }
                        
                        NavigationLink {
                            ChannelRolePermissionsSettings(server: Binding($server)!, channel: $channel, roleId: "default", permissions: .overwrite(channel.default_permissions ?? Overwrite(a: .none, d: .none)))
                                .navigationTitle("Default")
                        } label: {
                            Text("Default")
                        }
                    }
                    .listRowBackground(viewState.theme.background2)
            }
        }
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background)
        .navigationTitle("Permissions")
    }
}
