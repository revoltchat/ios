//
//  ServerInfoSheet.swift
//  Revolt
//
//  Created by Angelo on 08/07/2024.
//

import SwiftUI
import Types

struct ServerInfoSheet: View {
    @EnvironmentObject var viewState: ViewState
    @Environment(\.dismiss) var dismiss
    
    @State var showLeaveServerDialog: Bool = false
    
    var server: Server
    
    var body: some View {
        List {
            ZStack(alignment: .bottomLeading) {
                if let banner = server.banner {
                    LazyImage(source: .file(banner), height: 128, clipTo: Rectangle())
                        .frame(minWidth: 0)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                
                HStack(alignment: .bottom) {
                    ServerIcon(server: server, height: 64, width: 64, clipTo: Rectangle())
                        .addBorder(.black, width: 2, cornerRadius: 8)
                    
                    HStack(alignment: .center, spacing: 8) {
                        ServerBadges(value: server.flags)
                        
                        Text(server.name)
                            .bold()
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)

                }
                .padding(.top, server.banner == nil ? 8 : 0)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            //.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowSeparator(.hidden)
            .listRowBackground(viewState.theme.background)
            
            if let description = server.description {
                Contents(text: .constant(description), fontSize: 15)
                    .fixedSize(horizontal: false, vertical: true)
                    .listRowBackground(viewState.theme.background)
                    .listRowSeparator(.hidden)
            }
            
            Section {
                Button {
                    dismiss()
                    viewState.path.append(NavigationDestination.server_settings(server.id))
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)
                        
                        Text("Settings")
                    }
                }
                
                Button {
                    dismiss()
                    viewState.path.append(NavigationDestination.server_settings(server.id))
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)
                        
                        Text("Edit Server Profile")
                    }
                }
                
                Button(role: .destructive) {
                    showLeaveServerDialog = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.left.square.fill")
                            .resizable()
                            .foregroundStyle(viewState.theme.error)
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)
                        
                        Text("Leave Server")
                            .foregroundStyle(viewState.theme.error)
                    }
                }
                
                Button {
                    copyText(text: server.id)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.on.doc.fill")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)
                        
                        Text("Copy Server ID")
                    }
                }
            }
            .listRowBackground(viewState.theme.background)
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .scrollBounceBehavior(.basedOnSize, axes: [.vertical])
        .contentMargins(.top, 0, for: .scrollContent)
        .presentationDetents([.medium, .large])
        .confirmationDialog("Are you sure you want to leave?", isPresented: $showLeaveServerDialog) {
            Button("Leave", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Are you sure you want to leave?")
        }
    }
}
