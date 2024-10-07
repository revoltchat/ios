//
//  GroupDMChannelPermissions.swift
//  Revolt
//
//  Created by Angelo on 03/10/2024.
//

import Foundation
import SwiftUI
import Types

struct GroupDMChannelPermissionsSettings: View {
    @EnvironmentObject var viewState: ViewState
    
    @State var initial: GroupDMChannel
    @State var current: GroupDMChannel
    
    init(channel: GroupDMChannel) {
        self.initial = channel
        self.current = channel
    }
    
    var body: some View {
        AllPermissionSettings(
            permissions: .defaultRole(Binding {
                current.permissions ?? .defaultDirectMessages
            } set: {
                current.permissions = $0
            }),
            filter: [.readMessageHistory, .sendMessages, .manageMessages, .inviteOthers, .sendEmbeds, .uploadFiles, .masquerade, .react, .manageChannel, .managePermissions]
        )
        .listRowBackground(viewState.theme.background2)
        .toolbar {
#if os(iOS)
            let placement = ToolbarItemPlacement.topBarTrailing
#elseif os(macOS)
            let placement = ToolbarItemPlacement.automatic
#endif
            ToolbarItem(placement: placement) {
                if initial != current {
                    Button {
                        Task {
                            if let permissions = current.permissions {
                                if let channel = try? await viewState.http.setDefaultRoleChannelPermissions(channel: initial.id, permissions: permissions).get(),
                                   case .group_dm_channel(let group) = channel
                                {
                                    initial = group
                                    current = group
                                }
                            }
                        }
                    } label: {
                        Text("Save")
                            .foregroundStyle(viewState.theme.accent)
                    }
                }
                
            }
        }
    }
}
