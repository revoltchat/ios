//
//  ServerRolesSettings.swift
//  Revolt
//
//  Created by Angelo on 25/09/2024.
//

import Foundation
import Types
import SwiftUI


struct ServerRolesSettings: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var server: Server
    @State var showCreateRole: Bool = false
    
    var body: some View {
        List {
            Section {
                ForEach(Array(server.roles ?? [:]).sorted(by: { a, b in a.value.rank < b.value.rank }), id: \.key) { pair in
                    NavigationLink {
                        RoleSettings(server: $server, roleId: pair.key, role: pair.value)
                    } label: {
                        Text(verbatim: pair.value.name)
                            .foregroundStyle(pair.value.colour.map { parseCSSColor(currentTheme: viewState.theme, input: $0) } ?? AnyShapeStyle(viewState.theme.foreground))
                    }
                }
                
                NavigationLink {
                    DefaultRoleSettings(server: $server, permissions: server.default_permissions)
                } label: {
                    Text("Default")
                }            }
            .listRowBackground(viewState.theme.background2)

            Section {
                Button {
                    showCreateRole = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                            
                            .frame(width: 24, height: 24)
                        
                        Text("Create Role")
                    }
                    .foregroundStyle(.green)
                }
            }
            .listRowBackground(viewState.theme.background2)
        }
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background)
        .navigationTitle("Roles")
        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
        .alert("Create a new role", isPresented: $showCreateRole) {
            CreateRoleAlert(server: $server)
        }
    }
}

struct CreateRoleAlert: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var server: Server
    @State var name: String = ""
    
    var body: some View {
        TextField("Role Name", text: $name)
        
        Button("Create") {
            Task {
                try! await viewState.http.createRole(server: server.id, name: name).get()
            }
        }
        
        Button("Cancel", role: .cancel) {}
    }
}
