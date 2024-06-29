//
//  MessageBox.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation
import SwiftUI
import PhotosUI
import Types

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
                }
            }
        }
    }
}

struct MessageBox: View {
    enum AutocompleteType {
        case user
        case channel
    }

    enum AutocompleteValues {
        case channels([Channel])
        case users([(User, Member?)])
    }

    struct Photo: Identifiable, Hashable {
        let data: Data
#if os(macOS)
        let image: NSImage?
#else
        let image: UIImage?
#endif
        let id: UUID
        let filename: String
    }

    @EnvironmentObject var viewState: ViewState

    @Binding var channelReplies: [Reply]
    var focusState: FocusState<Bool>.Binding
    @Binding var showingSelectEmoji: Bool
    @Binding var editing: Message?

    @State var showingSelectFile = false
    @State var showingSelectPhoto = false

    @State var reshowKeyboard = false

    @State var content = ""

    @State var selectedPhotos: [Photo] = []
    @State var selectedPhotoItems: [PhotosPickerItem] = []
    @State var selectedEmoji: String = ""

    @State var autoCompleteType: AutocompleteType? = nil
    @State var autocompleteSearchValue: String = ""

    let channel: Channel
    let server: Server?

    init(channel: Channel, server: Server?, channelReplies: Binding<[Reply]>, focusState f: FocusState<Bool>.Binding, showingSelectEmoji: Binding<Bool>, editing: Binding<Message?>) {
        self.channel = channel
        self.server = server
        _channelReplies = channelReplies
        focusState = f
        _showingSelectEmoji = showingSelectEmoji
        _editing = editing
        
        if let msg = editing.wrappedValue {
            content = msg.content ?? ""
        }
    }

    func sendMessage() {
        let c = content
        content = ""

        if let message = editing {
            Task {
                await viewState.http.editMessage(channel: channel.id, message: message.id, edits: MessageEdit(content: c))
                
                editing = nil
            }
            
        } else {
            let f = selectedPhotos.map({ ($0.data, $0.filename) })
            selectedPhotos = []
            
            Task {
                await viewState.queueMessage(channel: channel.id, replies: channelReplies, content: c, attachments: f)
            }
        }
    }

    func getAutocompleteValues(fromType type: AutocompleteType) -> AutocompleteValues {
        switch type {
            case .user:
                let users: [(User, Member?)]

                switch channel {
                    case .saved_messages(_):
                        users = [(viewState.currentUser!, nil)]

                    case .dm_channel(let dMChannel):
                        users = dMChannel.recipients.map({ (viewState.users[$0]!, nil) })

                    case .group_dm_channel(let groupDMChannel):
                        users = groupDMChannel.recipients.map({ (viewState.users[$0]!, nil) })

                    case .text_channel(_), .voice_channel(_):
                        users = viewState.members[server!.id]!.values.map({ m in (viewState.users[m.id.user]!, m) })
                }

                return AutocompleteValues.users(users)
            case .channel:
                let channels: [Channel]

                switch channel {
                    case .saved_messages(_), .dm_channel(_), .group_dm_channel(_):
                        channels = [channel]
                    case .text_channel(_), .voice_channel(_):
                        channels = server!.channels.compactMap({ viewState.channels[$0] })
                }

                return AutocompleteValues.channels(channels)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(channelReplies.enumerated()), id: \.element.message.id) { reply in
                let model = ReplyViewModel(idx: reply.offset, replies: $channelReplies)
                ReplyView(viewModel: model, id: reply.element.message.id)
                    .padding(.horizontal, 16)
            }
            VStack(alignment: .leading, spacing: 8) {
                if selectedPhotos.count > 0 {
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
                }

                if let type = autoCompleteType {
                    let values = getAutocompleteValues(fromType: type)

                    ScrollView(.horizontal) {
                        LazyHStack {
                            switch values {
                                case .users(let users):
                                    ForEach(users, id: \.0.id) { (user, member) in
                                        Button {
                                            withAnimation {
                                                content = String(content.dropLast())
                                                content.append("<@\(user.id)>")
                                                autoCompleteType = nil
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                Avatar(user: user, member: member, width: 24, height: 24)
                                                Text(verbatim: member?.nickname ?? user.display_name ?? user.username)
                                            }
                                            .padding(6)
                                        }
                                        .background(viewState.theme.background2.color)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                case .channels(let channels):
                                    ForEach(channels) { channel in
                                        Button {
                                            withAnimation {
                                                content = String(content.dropLast())
                                                content.append("<#\(channel.id)>")
                                                autoCompleteType = nil
                                            }
                                        } label: {
                                            ChannelIcon(channel: channel)
                                                .padding(6)
                                        }
                                        .background(viewState.theme.background2.color)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                            }
                        }
                        .frame(height: 42)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                if editing != nil {
                    Button {
                        editing = nil
                        content = ""
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                                .foregroundStyle(viewState.theme.accent)
                            
                            Text("Editing Message")
                            
                            Spacer()
                            
                            Image(systemName: "xmark")
                                .foregroundStyle(viewState.theme.foreground2)
                        }
                        .bold()
                    }
                }

                HStack(alignment: .top) {
                    if editing == nil {
                        UploadButton(showingSelectFile: $showingSelectFile, showingSelectPhoto: $showingSelectPhoto, selectedPhotoItems: $selectedPhotoItems, selectedPhotos: $selectedPhotos)
                            .frame(alignment: .top)
                    }

                    TextField("", text: $content.animation(), axis: .vertical)
                        .focused(focusState)
                        .placeholder(when: content.isEmpty) {
                            Text("Message #\(channel.getName(viewState))")
                                .foregroundStyle(viewState.theme.foreground2.color)
                        }
                        .onChange(of: content) { _, value in
                            withAnimation {
                                if let last = value.split(separator: " ").last {
                                    let pre = last.first
                                    autocompleteSearchValue = String(last[last.index(last.startIndex, offsetBy: 1)...])

                                    switch pre {
                                        case "@":
                                            autoCompleteType = .user
                                        case "#":
                                            autoCompleteType = .channel
                                        default:
                                            autoCompleteType = nil
                                    }
                                } else {
                                    autoCompleteType = nil
                                }
                            }
                        }
                        .onChange(of: focusState.wrappedValue, { _, v in
                            if v, showingSelectEmoji {
                                withAnimation {
                                    showingSelectEmoji = false
                                }
                            }
                        })
                        .onChange(of: showingSelectEmoji, { b, a in
                            if b, !a {
                                withAnimation {
                                    focusState.wrappedValue = true
                                }
                            }
                        })
                        .onChange(of: editing, { b, a in
                            if let a {
                                selectedPhotos = []
                                selectedPhotoItems = []
                                channelReplies = []
                                autoCompleteType = nil
                                autocompleteSearchValue = ""
                                content = a.content ?? ""
                            }
                        })
                        .sheet(isPresented: $showingSelectEmoji) {
                            EmojiPicker(background: AnyView(viewState.theme.background)) { emoji in
                                if let id = emoji.emojiId {
                                    content.append(":\(id):")
                                } else {
                                    content.append(String(String.UnicodeScalarView(emoji.base.compactMap(Unicode.Scalar.init))))
                                }

                                showingSelectEmoji = false
                            }
                            .padding([.top, .horizontal])
                            .background(viewState.theme.background.ignoresSafeArea(.all))
                            .presentationDetents([.large])
                        }

                    Group {
                        Button {
                            withAnimation {
                                focusState.wrappedValue = false
                                showingSelectEmoji.toggle()
                            }
                        } label: {
                            Image(systemName: "face.smiling")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(viewState.theme.foreground3.color)
                        }


                        if !content.isEmpty || !selectedPhotos.isEmpty {
                            Button(action: sendMessage) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundStyle(viewState.theme.foreground3.color)
                            }
                        }
                    }
                    .frame(alignment: .top)
                }
            }
            .padding(.top, 8)
        }
        .padding(.top, 4)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .background(viewState.theme.messageBox.color)
    }
}

struct UploadButton: View {
    @EnvironmentObject var viewState: ViewState

    @Binding var showingSelectFile: Bool
    @Binding var showingSelectPhoto: Bool
    @Binding var selectedPhotoItems: [PhotosPickerItem]
    @Binding var selectedPhotos: [MessageBox.Photo]

    func onFileCompletion(res: Result<URL, Error>) {
        if case .success(let url) = res {
            let data = try? Data(contentsOf: url)
            guard let data = data else { return }

#if os(macOS)
            let image = NSImage(data: data)
#else
            let image = UIImage(data: data)
#endif

            selectedPhotos.append(.init(data: data, image: image, id: UUID(), filename: url.lastPathComponent))
        }
    }

    var body: some View {
        Image(systemName: "plus")
            .resizable()
            .foregroundStyle(viewState.theme.foreground3.color)
            .frame(width: 16, height: 16)
            .frame(width: 20, height: 20)

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
                                selectedPhotos.append(.init(data: data, image: img, id: UUID(), filename: fileName))
                            }
                        }
                    }
                    selectedPhotoItems.removeAll()
                }
            }
    }
}

struct MessageBox_Previews: PreviewProvider {
    static var viewState: ViewState = ViewState.preview().applySystemScheme(theme: .dark)
    @State static var replies: [Reply] = []
    @State static var showingSelectEmoji = false
    @FocusState static var focused: Bool

    static var previews: some View {
        let channel = viewState.channels["0"]!
        let server = viewState.servers["0"]!

        MessageBox(channel: channel, server: server, channelReplies: $replies, focusState: $focused, showingSelectEmoji: $showingSelectEmoji, editing: .constant(nil))
            .applyPreviewModifiers(withState: viewState)
    }
}
