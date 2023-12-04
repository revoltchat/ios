//
//  MessageBox.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation
import SwiftUI
import PhotosUI

struct Reply {
    var message: Message
    var mention: Bool = false
}

class ReplyViewModel: ObservableObject {
    var idx: Int

    @Binding var replies: [Reply]

    func remove() {
        replies.remove(at: idx)
    }
    
    internal init(idx: Int, replies: Binding<[Reply]>) {
        self.idx = idx
        _replies = replies
    }
}

struct ReplyView: View {
    @EnvironmentObject var viewState: ViewState
    @ObservedObject var viewModel: ReplyViewModel
    
    var id: String
    
    @ViewBuilder
    var body: some View {
        let reply = viewModel.replies[viewModel.idx]
        
        let author = viewState.users[reply.message.author]!

        HStack {
            Button(action: viewModel.remove) {
                Image(systemName: "xmark.circle")
            }
            Avatar(user: author, width:16, height: 16)
            Text(author.username)
            if let content = reply.message.content {
                Text(content)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer()
            Button(action: { viewModel.replies[viewModel.idx].mention.toggle() }) {
                if viewModel.replies[viewModel.idx].mention {
                    Text("@ on")
                        .foregroundColor(.accentColor)
                } else {
                    Text("@ off")
                        .foregroundColor(.black)
                }
            }
        }
    }
}

struct MessageBox: View {
    @EnvironmentObject var viewState: ViewState
    
    @State var showingSelectFile = false
    @State var showingSelectPhoto = false
    @State var content = ""
    
    @State var selectedPhotoItems = [PhotosPickerItem]()

    #if os(macOS)
    struct Photo: Identifiable, Hashable {
        let data: Data
        let image: NSImage?
        let id: UUID
        let filename: String
        
    }
    #else
    struct Photo: Identifiable, Hashable {
        let data: Data
        let image: UIImage?
        let id: UUID
        let filename: String
        
    }
    #endif
    
    @State var selectedPhotos: [Photo] = []

    @Binding var channelReplies: [Reply]

    let channel: Channel
    let server: Server?

    init(channel: Channel, server: Server?, channelReplies: Binding<[Reply]>) {
        self.channel = channel
        self.server = server
        _channelReplies = channelReplies
    }
    
    func sendMessage() {
        let c = content
        content = ""
        let f = selectedPhotos.map({ ($0.data, $0.filename) })
        selectedPhotos = []
        
        Task {
            await viewState.queueMessage(channel: channel.id, replies: channelReplies, content: c, attachments: f)
        }
    }
    
    func onFileCompletion(res: Result<URL, Error>) {
        if case .success(let url) = res {
            let data = try? Data(contentsOf: url)
            guard let data = data else { return }
            
            #if os(macOS)
            let image = NSImage(data: data)
            #else
            let image = UIImage(data: data)
            #endif
            
            selectedPhotos.append(Photo(data: data, image: image, id: UUID(), filename: url.lastPathComponent))
        }
    }
    
    func getCurrentlyTyping() -> [(User, Member?)]? {
        viewState.currentlyTyping[channel.id]?.compactMap({ user_id in
            guard let user = viewState.users[user_id] else {
                return nil
            }

            var member: Member?
            
            if let server = server {
                member = viewState.members[server.id]![user_id]
            }
            
            return (user, member)
        })
    }
    
    func formatTypingIndicatorText(withUsers users: [(User, Member?)]) -> String {
        let base = ListFormatter.localizedString(byJoining: users.map({ (user, member) in member?.nickname ?? user.display_name ?? user.username }))
        
        let ending = users.count == 1 ? "is typing" : "are typing"

        return "\(base) \(ending)"
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if let users = getCurrentlyTyping(), !users.isEmpty {
                HStack {
                    HStack(spacing: -12) {
                        ForEach(users, id: \.0.id) { (user, member) in
                            Avatar(user: user, member: member, width: 24, height: 24)
                        }
                    }

                    Text(formatTypingIndicatorText(withUsers: users))
                }
            }
            ForEach(Array(channelReplies.enumerated()), id: \.element.message.id) { reply in
                let model = ReplyViewModel(idx: reply.offset, replies: $channelReplies)
                ReplyView(viewModel: model, id: reply.element.message.id)
                    .padding(.horizontal, 16)
            }
            ScrollView(.horizontal) {
                HStack {
                    ForEach($selectedPhotos, id: \.self) { file in
                        let file = file.wrappedValue
                        
                        ZStack(alignment: .topTrailing) {
                            if let image = file.image {
                                #if os(iOS)
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame( maxWidth: 100, maxHeight: 100 )
                                    .clipShape(RoundedRectangle(cornerRadius: 5.0, style: .circular))
                                #else
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame( maxWidth: 100, maxHeight: 100 )
                                    .clipShape(RoundedRectangle(cornerRadius: 5.0, style: .circular))
                                #endif
                            } else {
                                ZStack {
                                    Rectangle()
                                        .frame(width: 100, height: 100)
                                        .foregroundStyle(viewState.theme.background.color)
                                        .clipShape(RoundedRectangle(cornerRadius: 5.0, style: .circular))

                                    Text(verbatim: file.filename)
                                        .font(.caption)
                                        .foregroundStyle(viewState.theme.foreground.color)
                                }
                            }
                            Button(action: { selectedPhotos.removeAll(where: { $0.id == file.id }) }) {
                                Image(systemName: "xmark.app.fill")
                                    .resizable()
                                    .foregroundStyle(.gray)
                                    .symbolRenderingMode(.hierarchical)
                                    .opacity(0.9)
                                    .frame(width: 16, height: 16)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                }
            }
            HStack {
                // MARK: image/file picker
                Image(systemName: "plus.circle")
                    .resizable()
                    .foregroundStyle(.gray)
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                
                    .photosPicker(isPresented: $showingSelectPhoto, selection: $selectedPhotoItems)
                    .photosPickerStyle(.presentation)
                
                    .fileImporter(isPresented: $showingSelectFile, allowedContentTypes: [.item], onCompletion: onFileCompletion)
                
                    .onTapGesture {
                        showingSelectPhoto = true
                    }
                    .contextMenu {
                        Button(action: {
                            showingSelectFile = true
                        }) {
                            Text("Select File")
                        }
                        Button(action: {
                            showingSelectPhoto = true
                        }) {
                            Text("Select Photo")
                        }
                    }
                    .onChange(of: selectedPhotoItems) { before, after in
                        if after.isEmpty { return }
                        Task {
                            for item in after {
                                if let data = try? await item.loadTransferable(type: Data.self) {
                                    #if os(macOS)
                                    let img = NSImage(data: data)
                                    #else
                                    let img = UIImage(data: data)
                                    #endif
                                    
                                    if let img = img {
                                        let fileType = item.supportedContentTypes[0].preferredFilenameExtension!
                                        let fileName = (item.itemIdentifier ?? "Image") + ".\(fileType)"
                                        selectedPhotos.append(Photo(data: data, image: img, id: UUID(), filename: fileName))
                                    }
                                }
                            }
                            selectedPhotoItems.removeAll()
                        }
                    }
            
                ZStack(alignment: .bottomTrailing) {
                    TextField("", text: $content)
                        .placeholder(when: content.isEmpty) {
                            Text("Message \(channel.getName(viewState))")
                        }
                        .foregroundStyle(viewState.theme.foreground.color)
                        .padding([.vertical, .leading, .trailing], 8)
                        .background(RoundedRectangle(cornerRadius: 16)
                            .fill(viewState.theme.messageBox.color)
                            .stroke(viewState.theme.messageBoxBorder.color, lineWidth: 1)
                        )
                    
                    if !content.isEmpty || !selectedPhotos.isEmpty {
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                                .padding(5)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(viewState.theme.messageBoxBackground.color)
    }
}

struct MessageBox_Previews: PreviewProvider {
    static var viewState: ViewState = ViewState.preview()
    @State static var replies: [Reply] = []

    static var previews: some View {
        let channel = viewState.channels["0"]!
        let server = viewState.servers["0"]!
        
        MessageBox(channel: channel, server: server, channelReplies: $replies)
            .environmentObject(viewState)
            .previewLayout(.sizeThatFits)

    }
}
