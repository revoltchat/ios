//
//  ServerEmojiSettings.swift
//  Revolt
//
//  Created by Angelo on 01/10/2024.
//

import Foundation
import Types
import SwiftUI
import PhotosUI
import SwiftyCrop

struct ServerEmojiSettings: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var server: Server
    
    @State var showPhotoPicker: Bool = false
    @State var selectedPhoto: PhotosPickerItem? = nil
    @State var selectedImage: UIImage? = nil
    @State var showImageCropper: Bool = false
    @State var emojiName: String = ""
    
    var serverEmojis: [Emoji] {
        viewState.emojis.values.filter { $0.parent.id == server.id }
    }
    
    var body: some View {
        List {
            let emojis = serverEmojis
            
            Section("Upload Emoji") {
                HStack(spacing: 16) {
                    Button {
                        showPhotoPicker.toggle()
                    } label: {
                        Text("Select Emoji")
                            .foregroundStyle(viewState.theme.accent)
                    }
                    .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto)
                    .onChange(of: selectedPhoto) { oldValue, newValue in
                        Task {
                            if let newValue {
                                if let data = try? await newValue.loadTransferable(type: Data.self) {
                                    selectedImage = UIImage(data: data)
                                    showImageCropper = true
                                }
                            }
                        }
                    }
                    .fullScreenCover(isPresented: $showImageCropper) {
                        if let toBeCropped = selectedImage {
                            SwiftyCropView(
                                imageToCrop: toBeCropped,
                                maskShape: .square
                            ) { croppedImage in
                                showImageCropper = false
                                selectedImage = croppedImage
                            }
                        }
                    }

                    
                    TextField("Emoji Name", text: $emojiName)
                        .autocorrectionDisabled()
                        .textCase(.lowercase)
                        .textInputAutocapitalization(.never)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(viewState.theme.background))
                }
                .listRowSeparator(.hidden)
                
                if selectedImage != nil || !emojiName.isEmpty {
                    HStack {
                        if let selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .frame(width: 32, height: 32)
                        }
                        
                        if !emojiName.isEmpty {
                            Text(":").foregroundStyle(viewState.theme.foreground2)
                            +
                            Text(verbatim: emojiName)
                            +
                            Text(":").foregroundStyle(viewState.theme.foreground2)
                            
                        }
                        
                        Spacer()
                        
                        Button("Create") {
                            Task {
                                let file = try! await viewState.http.uploadFile(data: selectedImage!.pngData()!, name: "emoji", category: .emoji).get()
                                let emoji = try! await viewState.http.uploadEmoji(id: file.id, name: emojiName, parent: .server(EmojiParentServer(id: server.id)), nsfw: false).get()
                                viewState.emojis[emoji.id] = emoji
                                emojiName = ""
                                selectedPhoto = nil
                                selectedImage = nil
                            }
                        }
                        .foregroundStyle(viewState.theme.accent)
                        .disabled(selectedImage == nil || emojiName.isEmpty)
                    }
                }
            }
            .listRowBackground(viewState.theme.background2)
            
            Section("Emojis - \(emojis.count)") {
                ForEach(emojis) { emoji in
                    HStack {
                        LazyImage(source: .emoji(emoji.id), clipTo: Rectangle())
                            .frame(width: 32, height: 32)
                        
                        Text(":").foregroundStyle(viewState.theme.foreground2)
                            +
                        Text(verbatim: emoji.name)
                            +
                        Text(":").foregroundStyle(viewState.theme.foreground2)
                        
                        Spacer()
                        
                        if let user = viewState.users[emoji.creator_id] {
                            HStack {
                                Text(verbatim: user.display_name ?? user.username)
                                    .foregroundStyle(viewState.theme.foreground2)
                                
                                Avatar(user: user)
                                    .frame(width: 24, height: 24)
                            }
                        } else {
                            Text("Loading")
                                .task {
                                    if let user = try? await viewState.http.fetchUser(user: emoji.creator_id).get() {
                                        viewState.users[emoji.creator_id] = user
                                    }
                                }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task {
                                await viewState.http.deleteEmoji(emoji: emoji.id)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                }
            }
            .listRowBackground(viewState.theme.background2)
        }
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background)
        .navigationTitle("Emojis")
        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
    }
}
