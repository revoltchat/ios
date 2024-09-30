//
//  ChannelRolePermissionsSettings.swift
//  Revolt
//
//  Created by Angelo on 25/09/2024.
//

import Foundation
import SwiftUI
import Types

struct ChannelRolePermissionsSettings: View {
    @EnvironmentObject var viewState: ViewState
    
    enum Value: Equatable {
        case permission(Permissions)
        case overwrite(Overwrite)
    }
    
    @Binding var server: Server
    @Binding var channel: Channel
    
    var roleId: String
    @State var initial: Value
    @State var currentValue: Value
    
    init(server: Binding<Server>, channel: Binding<Channel>, roleId: String, permissions: Value) {
        self._server = server
        self._channel = channel
        self.roleId = roleId
        self.initial = permissions
        self.currentValue = permissions
    }
    
    var body: some View {
        List {
            AllPermissionSettings(
                permissions: {
                    switch currentValue {
                        case .permission(let permissions):
                            .defaultRole(Binding {
                                permissions
                            } set: {
                                currentValue = .permission($0)
                            })
                        case .overwrite(let overwrite):
                            .role(Binding {
                                overwrite
                            } set: {
                                currentValue = .overwrite($0)
                            })
                    }
                }(),
                filter: [.viewChannel, .readMessageHistory, .sendMessages, .manageMessages, .inviteOthers, .sendEmbeds, .uploadFiles, .masquerade, .react, .manageChannel, .managePermissions]
            )
                .listRowBackground(viewState.theme.background2)
        }
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background)
        .toolbar {
#if os(iOS)
            let placement = ToolbarItemPlacement.topBarTrailing
#elseif os(macOS)
            let placement = ToolbarItemPlacement.automatic
#endif
            ToolbarItem(placement: placement) {
                if initial != currentValue {
                    Button {
                        
                    } label: {
                        Text("Save")
                            .foregroundStyle(viewState.theme.accent)
                    }
                }
                
            }
        }
        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
    }
}
