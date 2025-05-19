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

struct Reply: Identifiable, Equatable {
    var message: Message
    var mention: Bool = false
    
    var id: String { message.id }
}

struct ReplyView: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var reply: Reply
    
    @Binding var replies: [Reply]
    
    var channel: Channel
    var server: Server?

    func remove() {
        withAnimation {
            replies.removeAll(where: { $0.id == reply.id })
        }
    }
    
    var body: some View {
        let user = viewState.users[reply.message.author]!
        let member = server.flatMap { viewState.members[$0.id]?[user.id] }

        HStack(alignment: .center, spacing: 8) {
            Button(action: remove) {
                Image(systemName: "xmark")
                    .resizable()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(viewState.theme.foreground3)
                    .bold()
            }
            
            Avatar(user: user, width: 16, height: 16)
            
            Text(reply.message.masquerade?.name ?? member?.nickname ?? user.display_name ?? user.username)
                .font(.caption)
                .fixedSize()
                .foregroundStyle(member?.displayColour(theme: viewState.theme, server: server!) ?? AnyShapeStyle(viewState.theme.foreground.color))
            
            if !(reply.message.attachments?.isEmpty ?? true) {
                Text(Image(systemName: "doc.text.fill"))
                    .font(.caption)
                    .foregroundStyle(viewState.theme.foreground2)
            }
            
            if let content = Binding($reply.message.content) {
                Contents(text: content, fontSize: 12)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()
            
            Button(action: { reply.mention.toggle() }) {
                if reply.mention {
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
        case usersAndRoles
        case channel
        case emoji
    }
    
    enum UserOrRole: Identifiable {
        case user(UserMaybeMember)
        case role(String, Role)
        case everyone
        case online
        
        var id: String {
            switch self {
                case .user(let userMaybeMember):
                    return userMaybeMember.id
                case .role(let id, _):
                    return id
                case .everyone:
                    return "everyone"
                case .online:
                    return "online"
            }
        }
    }

    enum AutocompleteValues {
        case channels([Channel])
        case usersAndRoles([UserOrRole])
        case emojis([PickerEmoji])
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
    
    @State var currentPermissions: Permissions = .default

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
        let replies = channelReplies
        channelReplies = []

        if let message = editing {
            Task {
                editing = nil

                await viewState.http.editMessage(channel: channel.id, message: message.id, edits: MessageEdit(content: c))
            }
            
        } else {
            let f = selectedPhotos.map({ ($0.data, $0.filename) })
            selectedPhotos = []
            
            Task {
                await viewState.queueMessage(channel: channel.id, replies: replies, content: c, attachments: f)
            }
        }
    }

    func getAutocompleteValues(fromType type: AutocompleteType) -> AutocompleteValues {
        switch type {
            case .usersAndRoles:
                var usersAndRoles: [UserOrRole]

                switch channel {
                    case .saved_messages(_):
                        usersAndRoles = [.user(UserMaybeMember(user: viewState.currentUser!, member: nil))]

                    case .dm_channel(let dMChannel):
                        usersAndRoles = dMChannel.recipients.map { .user(UserMaybeMember(user: viewState.users[$0]!, member: nil)) }

                    case .group_dm_channel(let groupDMChannel):
                        usersAndRoles = groupDMChannel.recipients.map { .user(UserMaybeMember(user: viewState.users[$0]!, member: nil)) }

                    case .text_channel(_), .voice_channel(_):
                        usersAndRoles = viewState.members[server!.id]!.values.compactMap { m in
                            viewState.users[m.id.user].map { .user(UserMaybeMember(user: $0, member: m)) }
                        }
                        
                        if currentPermissions.contains(.mentionRoles) {
                            if let roles = server?.roles {
                                usersAndRoles.append(contentsOf: roles.map { (key, value) in .role(key, value) })
                            }
                        }
                        
                        if currentPermissions.contains(.mentionEveryone) {
                            usersAndRoles.append(contentsOf: [.everyone, .online])
                        }
                }

                return AutocompleteValues.usersAndRoles(usersAndRoles.filter({ value in
                    let lowered = autocompleteSearchValue.lowercased()
                    switch value {
                        case .user(let user):
                            return user.user.display_name?.lowercased().starts(with: lowered)
                                ?? user.member?.nickname?.lowercased().starts(with: lowered)
                                ?? user.user.username.lowercased().starts(with: lowered)
                        case .role(_, let role):
                            return role.name.lowercased().starts(with: lowered)
                        case .everyone:
                            return "everyone".starts(with: lowered)
                        case .online:
                            return "online".starts(with: lowered)
                    }
                }))
            case .channel:
                let channels: [Channel]

                switch channel {
                    case .saved_messages(_), .dm_channel(_), .group_dm_channel(_):
                        channels = [channel]
                    case .text_channel(_), .voice_channel(_):
                        channels = server!.channels.compactMap({ viewState.channels[$0] })
                }

                return AutocompleteValues.channels(channels.filter { channel in
                    channel.getName(viewState).lowercased().starts(with: autocompleteSearchValue.lowercased())
                })
            case .emoji:
                return AutocompleteValues.emojis(loadEmojis(withState: viewState)
                    .values
                    .flatMap { $0 }
                    .filter { emoji in
                        let names: [String]
                        
                        if let emojiId = emoji.emojiId, let emoji = viewState.emojis[emojiId] {
                            names = [emoji.name]
                        } else {
                            var values = emoji.alternates
                            values.append(emoji.base)
                            names = values.map { String(String.UnicodeScalarView($0.compactMap(Unicode.Scalar.init))) }
                        }
                        
                        return names.contains(where: { $0.lowercased().starts(with: autocompleteSearchValue.lowercased()) })
                    })
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach($channelReplies) { reply in
                ReplyView(reply: reply, replies: $channelReplies, channel: channel, server: server)
                    .padding(.horizontal, 4)
                    //.transition(.move(edge: .bottom))
            }
            .animation(.default, value: channelReplies)
            
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
                                            .frame(maxWidth: 100, maxHeight: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 5.0, style: .circular))
#else
                                        Image(nsImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: 100, maxHeight: 100)
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
                                case .usersAndRoles(let usersOrRoles):
                                    ForEach(usersOrRoles) { userOrRole in
                                        Button {
                                            let value: String
                                            
                                            switch userOrRole {
                                                case .user(let user):
                                                    value = "<@\(user.id)>"
                                                case .role(let id, _):
                                                    value = "<%\(id)>"
                                                case .everyone:
                                                    value = "@everyone"
                                                case .online:
                                                    value = "@online"
                                            }
                                            
                                            withAnimation {
                                                content = String(content.dropLast(autocompleteSearchValue.count + 1))
                                                content.append(value)
                                                autoCompleteType = nil
                                            }
                                        } label: {
                                            HStack(spacing: 8) {
                                                switch userOrRole {
                                                    case .user(let user):
                                                        Avatar(user: user.user, member: user.member, width: 24, height: 24)
                                                        Text(verbatim: user.member?.nickname ?? user.user.display_name ?? user.user.username)
                                                    case .role(let id, let role):
                                                        Image(systemName: "at")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 16, height: 16)
                                                            .foregroundStyle(viewState.theme.foreground)
                                                        
                                                        Text(verbatim: role.name)
                                                            .foregroundStyle(role.colour.map { parseCSSColor(currentTheme: viewState.theme, input: $0) } ?? AnyShapeStyle(viewState.theme.foreground))
                                                    case .everyone:
                                                        Image(systemName: "at")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 16, height: 16)
                                                            .foregroundStyle(viewState.theme.foreground)
                                                        
                                                        Text("everyone")
                                                    case .online:
                                                        Image(systemName: "at")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 16, height: 16)
                                                            .foregroundStyle(viewState.theme.foreground)
                                                        
                                                        Text("online")

                                                }
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
                                                content = String(content.dropLast(autocompleteSearchValue.count + 1))
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
                                case .emojis(let emojis):
                                    ForEach(emojis) { emoji in
                                        Button {
                                            let emojiString: String
                                            
                                            if let emojiId = emoji.emojiId {
                                                emojiString = ":\(emojiId):"
                                            } else {
                                                emojiString = String(String.UnicodeScalarView(emoji.base.compactMap(Unicode.Scalar.init)))
                                            }
                                            
                                            withAnimation {
                                                content = String(content.dropLast(autocompleteSearchValue.count + 1))
                                                content.append(emojiString)
                                                autoCompleteType = nil
                                            }
                                        } label: {
                                            HStack(spacing: 8) {
                                                if let id = emoji.emojiId {
                                                    let emoji = viewState.emojis[id]!
                                                    
                                                    LazyImage(source: .emoji(id), height: 24, width: 24, clipTo: Rectangle())
                                                    Text(verbatim: emoji.name)
                                                } else {
                                                    let emojiString = String(String.UnicodeScalarView(emoji.base.compactMap(Unicode.Scalar.init)))
                                                    let image = convertEmojiToImage(text: emojiString)
                                                    
#if os(iOS)
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(width: 24, height: 24)
#elseif os(macOS)
                                                    Image(nsImage: image)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(width: 24, height: 24)
#endif
                                                    
                                                    Text(verbatim: emojiString)
                                                }
                                            }
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
                                            autoCompleteType = .usersAndRoles
                                        case "#":
                                            autoCompleteType = .channel
                                        case ":":
                                            autoCompleteType = .emoji
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
                                autoCompleteType = nil
                                autocompleteSearchValue = ""
                                content = a.content ?? ""
                            } else {
                                channelReplies = []
                                content = ""
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
        .onAppear {
            let member = server.flatMap { viewState.members[$0.id]?[viewState.currentUser!.id] }
            
            currentPermissions = resolveChannelPermissions(from: viewState.currentUser!, targettingUser: viewState.currentUser!, targettingMember: member, channel: channel, server: server)
        }
    }
}

struct UploadButton: View {
    @EnvironmentObject var viewState: ViewState

    @Binding var showingSelectFile: Bool
    @Binding var showingSelectPhoto: Bool
    @Binding var selectedPhotoItems: [PhotosPickerItem]
    @Binding var selectedPhotos: [MessageBox.Photo]

    func onFileCompletion(res: Result<URL, Error>) {
        if case .success(let url) = res, url.startAccessingSecurityScopedResource() {
            let data = try? Data(contentsOf: url)
            url.stopAccessingSecurityScopedResource()
            
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
