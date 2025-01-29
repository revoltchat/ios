//
//  RoleSettings.swift
//  Revolt
//
//  Created by Angelo on 25/09/2024.
//

import Foundation
import Types
import SwiftUI


struct RoleSettings: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var server: Server
    var roleId: String
    @State var initial: Role
    @State var currentValue: Role
    
    init(server s: Binding<Server>, roleId: String, role: Role) {
        self._server = s
        self.roleId = roleId
        self.initial = role
        self.currentValue = role
    }
    
    var body: some View {
        List {
            Section("Role Name") {
                TextField(text: $currentValue.name) {
                    Text("Role Name")
                }
            }
            .listRowBackground(viewState.theme.background3)
            
            Section("Role Colour") {
                HStack {
                    TextField(text: $currentValue.colour.bindOr(defaultTo: "")) {
                        Text("Role Colour")
                    }
                    
                    Circle()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(currentValue.colour.map { parseCSSColor(currentTheme: viewState.theme, input: $0) } ?? AnyShapeStyle(viewState.theme.foreground))
                    
                }
            }
            .listRowBackground(viewState.theme.background3)
            
            CheckboxListItem(title: "Hoist role", isOn: $currentValue.hoist.bindOr(defaultTo: false))
                .listRowBackground(viewState.theme.background2)
            
            Section("Role Rank") {
                TextField(value: $currentValue.rank, format: .number) {
                    Text("Role Name")
                }
            }
            .listRowBackground(viewState.theme.background3)
            
            Section("Edit Permissions") {
                AllPermissionSettings(permissions: .role($currentValue.permissions))
            }
            .listRowBackground(viewState.theme.background2)
            
            Button {
                Task {
                    try! await viewState.http.deleteRole(server: server.id, role: roleId).get()
                }
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete role")
                }
                .foregroundStyle(.red)
            }
            .listRowBackground(viewState.theme.background2)
        }
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(verbatim: initial.name)
                    .bold()
                    .foregroundStyle(initial.colour.map { parseCSSColor(currentTheme: viewState.theme, input: $0) } ?? AnyShapeStyle(viewState.theme.foreground))
            }
            
#if os(iOS)
            let placement = ToolbarItemPlacement.topBarTrailing
#elseif os(macOS)
            let placement = ToolbarItemPlacement.automatic
#endif
            ToolbarItem(placement: placement) {
                if initial != currentValue {
                    Button {
                        Task {
                            var payload = RoleEditPayload()
                            
                            if initial.name != currentValue.name {
                                payload.name = currentValue.name
                            }
                            
                            if initial.colour != currentValue.colour {
                                if currentValue.colour == nil || currentValue.colour == "" {
                                    if payload.remove == nil {
                                        payload.remove = []
                                    }
                                    payload.remove!.append(.colour)
                                } else {
                                    payload.colour = currentValue.colour
                                }
                            }
                            
                            if initial.hoist != currentValue.hoist {
                                payload.hoist = currentValue.hoist
                            }
                            
                            initial = try! await viewState.http.editRole(server: server.id, role: roleId, payload: payload).get()
                            
                            if initial.permissions != currentValue.permissions {
                                let _ = try! await viewState.http.setRolePermissions(server: server.id, role: roleId, overwrite: currentValue.permissions).get()
                                initial.permissions = currentValue.permissions
                            }
                            
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
