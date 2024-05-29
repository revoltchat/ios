//
//  ServerOverviewSettings.swift
//  Revolt
//
//  Created by Angelo on 07/01/2024.
//

import Foundation
import SwiftUI
import PhotosUI
import Types

struct ServerOverviewSettings: View {
    @EnvironmentObject var viewState: ViewState
    
    enum Icon: Equatable {
        case remote(File?)
        case local(Data)
    }
    
    struct ServerSettingsValues: Equatable {
        var icon: Icon
        var name: String
        var description: String
    }
    
    @State var initial: ServerSettingsValues
    @State var currentValues: ServerSettingsValues
    @State var showSaveButton: Bool = false
    @State var showIconPhotoPicker: Bool = false
    @State var serverIconPhoto: PhotosPickerItem?
    
    @Binding var server: Server
    
    @MainActor
    static func fromState(viewState: ViewState, server s: Binding<Server>) -> Self {
        let settings = ServerSettingsValues(
            icon: .remote(s.icon.wrappedValue),
            name: s.name.wrappedValue,
            description: s.description.wrappedValue ?? ""
        )
        
        return .init(initial: settings, currentValues: settings, server: s)
    }
    
    var body: some View {
        List {
            Section("Server Icon") {
                VStack {
                    switch currentValues.icon {
                        case .remote(let file):
                            if let file = file {
                                AnyView(LazyImage(source: .file(file), height: 48, width: 48, clipTo: Circle()))
                            } else {
                                AnyView(ZStack(alignment: .center) {
                                    let firstChar = server.name.first!
                                    
                                    Circle()
                                        .fill(.gray)  // TODO: background3
                                        .frame(width: 48, height: 48)
                                    
                                    Text(verbatim: "\(firstChar)")
                                        .font(.title2)
                                })
                            }
                        case .local(let data):
                            LazyImage(source: .local(data), height: 48, width: 48, clipTo: Circle())
                    }
                }
                .onTapGesture { showIconPhotoPicker = true }
                .photosPicker(isPresented: $showIconPhotoPicker, selection: $serverIconPhoto)
                .onChange(of: serverIconPhoto) { (_, new) in
                    Task {
                        if let photo = new {
                            if let data = try? await photo.loadTransferable(type: Data.self) {
                                currentValues.icon = .local(data)
                            }
                        }
                    }
                }
                
            }
            .listRowBackground(viewState.theme.background)
            
            Section("Server Name") {
                TextField(text: $currentValues.name) {
                    Text("Server Name")
                }
            }
            .listRowBackground(viewState.theme.background2)
            
            Section("Server Description") {
                TextField(text: $currentValues.description) {
                    Text("Add a topic...")
                }
            }
            .listRowBackground(viewState.theme.background2)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Overview")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if showSaveButton {
                    Button {
                        Task {
                            var edits = ServerEdit()
                            
                            if currentValues.name != initial.name {
                                edits.name = currentValues.name
                            }
                            
                            if currentValues.icon != initial.icon, case .local(let data) = currentValues.icon {
                                let file = try! await viewState.http.uploadFile(data: data, name: "", category: .icon).get()
                                edits.icon = file.id
                            }
                            
                            if currentValues.description != initial.description {
                                edits.description = currentValues.description
                            }
                            
                            viewState.servers[server.id] = try! await viewState.http.editServer(server: server.id, edits: edits).get()
                            
                            initial = currentValues
                            showSaveButton = false
                        }
                    } label: {
                        Text("Save")
                            .foregroundStyle(viewState.theme.accent)
                    }
                }
                
            }
        }
        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
        .scrollContentBackground(.hidden)
        .onChange(of: currentValues) { showSaveButton = true }
        .frame(maxWidth: .infinity)
        .background(viewState.theme.background)
    }
}


#Preview {
    let viewState = ViewState.preview()
    let server = viewState.servers["0"]!
    
    return NavigationStack {
        ServerOverviewSettings.fromState(viewState: viewState, server: .constant(server))
    }
    .applyPreviewModifiers(withState: viewState)
}
