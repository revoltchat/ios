//
//  DefaultRoleSettings.swift
//  Revolt
//
//  Created by Angelo on 25/09/2024.
//

import Foundation
import SwiftUI
import Types

struct DefaultRoleSettings: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var server: Server
    @State var initial: Permissions
    @State var currentValue: Permissions
    
    init(server s: Binding<Server>, permissions: Permissions) {
        self._server = s
        self.initial = permissions
        self.currentValue = permissions
    }
    
    var body: some View {
        List {
            Section("Edit Permissions") {
                AllPermissionSettings(permissions: .defaultRole($currentValue))
            }
            .listRowBackground(viewState.theme.background2)
        }
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background)
        .navigationTitle("Default")
        .toolbar {
#if os(iOS)
            let placement = ToolbarItemPlacement.topBarTrailing
#elseif os(macOS)
            let placement = ToolbarItemPlacement.automatic
#endif
            ToolbarItem(placement: placement) {
                if initial != currentValue {
                    Button {
                        Task {
                            let server = try! await viewState.http.setDefaultRolePermissions(server: server.id, permissions: currentValue).get()
                            initial = server.default_permissions
                            currentValue = initial
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
