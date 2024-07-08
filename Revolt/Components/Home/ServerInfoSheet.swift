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
        VStack {
            ZStack(alignment: .bottomLeading) {
                if let banner = server.banner {
                    LazyImage(source: .file(banner), height: 128, clipTo: UnevenRoundedRectangle(topLeadingRadius: 5, topTrailingRadius: 5))
                        .aspectRatio(contentMode: .fill)
                }
                
                HStack(alignment: .bottom) {
                    ServerIcon(server: server, height: 64, width: 64, clipTo: Rectangle())
                        .addBorder(.black, width: 2, cornerRadius: 8)
                    
                    Text(server.name)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .padding(.bottom, 10)
            
            if let description = server.description {
                Text(verbatim: description)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.subheadline)
            }
            
            List {
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
                }
                
                Section {
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
            }
            .listStyle(.inset)
        }
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
