//
//  ChannelOverviewSettings.swift
//  Revolt
//
//  Created by Angelo on 07/01/2024.
//

import Foundation
import SwiftUI
import PhotosUI
import Types

struct ChannelOverviewSettings: View {
    @EnvironmentObject var viewState: ViewState
    
    enum Icon: Equatable {
        case remote(File?)
        case local(Data)
    }
    
    struct ChannelSettingsValues: Equatable {
        var icon: Icon
        var description: String
    }
    
    @State var currentValues: ChannelSettingsValues
    @State var showSaveButton: Bool = false
    @State var showIconPhotoPicker: Bool = false
    @State var serverIconPhoto: PhotosPickerItem?
    
    @Binding var channel: Channel
    
    @MainActor
    static func fromState(viewState: ViewState, channel c: Binding<Channel>) -> Self {
        let settings = ChannelSettingsValues(
            icon: .remote(c.wrappedValue.icon),
            description: c.wrappedValue.description ?? ""
        )
        
        return .init(currentValues: settings, channel: c)
    }
    
    var body: some View {
        List {
            Section("Channel Icon") {
                VStack {
                    switch currentValues.icon {
                        case .remote(let file):
                            if let file = file {
                                AnyView(LazyImage(source: .file(file), height: 48, width: 48, clipTo: Circle()))
                            } else {
                                Circle()
                                    .fill(viewState.theme.background2)
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
#if os(iOS)
            let placement = ToolbarItemPlacement.topBarTrailing
#elseif os(macOS)
            let placement = ToolbarItemPlacement.automatic
#endif
            ToolbarItem(placement: placement) {
                if showSaveButton {
                    Button {
                        
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
    let channel = viewState.channels["0"]!
    
    return NavigationStack {
        ChannelOverviewSettings.fromState(viewState: viewState, channel: .constant(channel))
    }
    .applyPreviewModifiers(withState: viewState)
}
