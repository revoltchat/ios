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
    
    struct ServerSettingsValues: Equatable {
        var icon: SettingImage
        var banner: SettingImage
        var name: String
        var description: String
        var system_channels: SystemMessages
    }
    
    @State var initial: ServerSettingsValues
    @State var currentValues: ServerSettingsValues
    @State var showSaveButton: Bool = false
    
    @State var showIconPhotoPicker: Bool = false
    @State var serverIconPhoto: PhotosPickerItem? = nil
    
    @State var showBannerPhotoPicker: Bool = false
    @State var serverBannerPhoto: PhotosPickerItem? = nil
    
    @Binding var server: Server
    
    init(server s: Binding<Server>) {
        let settings = ServerSettingsValues(
            icon: .remote(s.icon.wrappedValue),
            banner: .remote(s.banner.wrappedValue),
            name: s.name.wrappedValue,
            description: s.description.wrappedValue ?? "",
            system_channels: s.system_messages.wrappedValue ?? SystemMessages()
        )
        
        initial = settings
        currentValues = settings
        _server = s
    }
    
    var body: some View {
        List {
            Section("Server Icon") {
                VStack {
                    Button {
                        showIconPhotoPicker = true
                    } label: {
                        switch currentValues.icon {
                            case .remote(let file):
                                if let file {
                                    LazyImage(source: .file(file), height: 64, width: 64, clipTo: Circle())
                                } else {
                                    ZStack(alignment: .center) {
                                        let firstChar = server.name.first!
                                        
                                        Circle()
                                            .fill(.gray)  // TODO: background3
                                            .frame(width: 64, height: 64)
                                        
                                        Text(verbatim: "\(firstChar)")
                                            .font(.title)
                                    }
                                }
                            case .local(let photo):
                                if let photo {
                                    LazyImage(source: .local(photo.content), height: 64, width: 64, clipTo: Circle())
                                } else {
                                    Circle()
                                        .foregroundStyle(viewState.theme.background2)
                                        .frame(width: 64, height: 64)
                                }
                        }
                    }
                    .photosPicker(isPresented: $showIconPhotoPicker, selection: $serverIconPhoto)
                    .onChange(of: serverIconPhoto) { (_, new) in
                        Task {
                            if let photo = new {
                                if let data = try? await photo.loadTransferable(type: Data.self) {
                                    currentValues.icon = .local(LocalFile(content: data, filename: "icon.\(photo.supportedContentTypes[0].preferredFilenameExtension!)"))  // TODO: figure out filename
                                }
                            }
                        }
                    }
                    
                    Button {
                        currentValues.icon = .local(nil)
                    } label: {
                        Text("Remove")
                            .font(.caption)
                            .foregroundStyle(viewState.theme.foreground2)
                    }
                }
            }
            .listRowBackground(viewState.theme.background)
            
            Section("Server Banner") {
                VStack(spacing: 16) {
                    Button {
                        showBannerPhotoPicker = true
                    } label: {
                        switch currentValues.banner {
                            case .remote(let file):
                                if let file {
                                    LazyImage(source: .file(file), height: 160, clipTo: RoundedRectangle(cornerRadius: 12))
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .frame(height: 160)
                                        .foregroundStyle(viewState.theme.background2)
                                }
                            case .local(let photo):
                                if let photo {
                                    LazyImage(source: .local(photo.content), height: 160, clipTo: RoundedRectangle(cornerRadius: 12))
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .frame(height: 160)
                                        .foregroundStyle(viewState.theme.background2)
                                }
                        }
                    }
                    .photosPicker(isPresented: $showBannerPhotoPicker, selection: $serverBannerPhoto)
                    .onChange(of: serverBannerPhoto) { (_, new) in
                        Task {
                            if let photo = new {
                                if let data = try? await photo.loadTransferable(type: Data.self) {
                                    currentValues.banner = .local(LocalFile(content: data, filename: "banner.\(photo.supportedContentTypes[0].preferredFilenameExtension!)"))  // TODO: figure out filename
                                }
                            }
                        }
                    }
                    
                    Button {
                        currentValues.banner = .local(nil)
                    } label: {
                        Text("Remove")
                            .font(.caption)
                            .foregroundStyle(viewState.theme.foreground2)
                    }
                }
            }
            .listRowBackground(viewState.theme.background)
            
            Section("Server Name") {
                TextField(text: $currentValues.name) {
                    Text("Server Name")
                }
            }
            .listRowBackground(viewState.theme.background3)
            
            Section("Server Description") {
                TextField(text: $currentValues.description, axis: .vertical) {
                    Text("Add a topic...")
                }
            }
            .listRowBackground(viewState.theme.background3)
            
            Section("System Messages") {
                SystemChannelSelector(title: "User Joined", server: server, selection: $currentValues.system_channels.user_joined)
                SystemChannelSelector(title: "User Left", server: server, selection: $currentValues.system_channels.user_left)
                SystemChannelSelector(title: "User Kicked", server: server, selection: $currentValues.system_channels.user_kicked)
                SystemChannelSelector(title: "User Banned", server: server, selection: $currentValues.system_channels.user_banned)

            }
            .listRowBackground(viewState.theme.background2)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Overview")
            }
        }
        .toolbar {
            #if os(iOS)
            let placement = ToolbarItemPlacement.topBarTrailing
            #elseif os(macOS)
            let placement = ToolbarItemPlacement.automatic
            #endif
            ToolbarItem(placement: placement) {
                if showSaveButton {
                    Button {
                        Task {
                            var edits = ServerEdit()
                            
                            if currentValues.name != initial.name {
                                edits.name = currentValues.name
                            }
                            
                            if currentValues.icon != initial.icon {
                                switch currentValues.icon {
                                    case .local(.some(let photo)):
                                        let file = try! await viewState.http.uploadFile(data: photo.content, name: photo.filename, category: .icon).get()
                                        edits.icon = file.id
                                    case .local(.none):
                                        edits.remove = edits.remove ?? []
                                        edits.remove!.append(.icon)
                                    default:
                                        ()
                                }
                            }
                            
                            if currentValues.banner != initial.banner {
                                switch currentValues.banner {
                                    case .local(.some(let photo)):
                                        let file = try! await viewState.http.uploadFile(data: photo.content, name: photo.filename, category: .banner).get()
                                        edits.banner = file.id
                                    case .local(.none):
                                        edits.remove = edits.remove ?? []
                                        edits.remove!.append(.banner)
                                    default:
                                        ()
                                }
                            }
                            
                            if currentValues.description != initial.description {
                                edits.description = currentValues.description
                            }
                            
                            if currentValues.system_channels != initial.system_channels {
                                edits.system_messages = currentValues.system_channels
                            }
                            
                            viewState.servers[server.id] = try! await viewState.http.editServer(server: server.id, edits: edits).get()
                            
                            initial = currentValues
                            showSaveButton = false
                            serverIconPhoto = nil
                            serverBannerPhoto = nil
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

struct SystemChannelSelector: View {
    @EnvironmentObject var viewState: ViewState
    
    var title: String
    var server: Server
    
    @Binding var selection: String?
    
    var body: some View {
        Picker(title, selection: $selection) {
            Text("Disabled")
                .tag(nil as String?)
            
            ForEach(server.channels
                .compactMap({
                    switch viewState.channels[$0] {
                        case .text_channel(let c):
                            return .some(c)
                        default:
                            return .none
                    }
                })
            ) { channel in
                Text("#\(channel.name)")
                    .tag(channel.id as String?)
            }
        }
    }
}


#Preview {
    @StateObject var viewState = ViewState.preview()
    let server = Binding($viewState.servers["0"])!
    
    return NavigationStack {
        ServerOverviewSettings(server: server)
    }
    .applyPreviewModifiers(withState: viewState)
}
