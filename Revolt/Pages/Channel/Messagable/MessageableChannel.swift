//
//  MessageableChannel.swift
//  Revolt
//
//  Created by Angelo on 18/10/2023.
//

import Foundation
import SwiftUI
import Types

struct ChannelScrollController {
    var proxy: ScrollViewProxy?
    @Binding var highlighted: String?
    
    func scrollTo(message id: String) {
        withAnimation(.easeInOut) {
            proxy?.scrollTo(id)
            highlighted = id
        }
        
        Task {
            try! await Task.sleep(for: .seconds(2))
            
            withAnimation(.easeInOut) {
                highlighted = nil
            }
        }
    }
    
    static var empty: ChannelScrollController {
        .init(proxy: nil, highlighted: .constant(nil))
    }
}

@MainActor
class MessageableChannelViewModel: ObservableObject {
    @ObservedObject var viewState: ViewState
    @Published var channel: Channel
    @Published var server: Server?
    @Binding var messages: [String]
    @Published var queuedMessages: [QueuedMessage] = []
    
    init(viewState: ViewState, channel: Channel, server: Server?, messages: Binding<[String]>) {
        self.viewState = viewState
        self.channel = channel
        self.server = server
        self._messages = messages
        self.queuedMessages = []
    }
    
    func getMember(message: Message) -> Binding<Member?> {
        if let server = server {
            return Binding($viewState.members[server.id])![message.author]
        } else {
            return .constant(nil)
        }
    }
    
    func loadMoreMessages(before: String? = nil) async -> FetchHistory? {
        if isPreview { return nil }
        
        let result = (try? await viewState.http.fetchHistory(channel: channel.id, limit: 50, before: before).get()) ?? FetchHistory(messages: [], users: [])  // haha ratelimited
        
        for user in result.users {
            viewState.users[user.id] = user
        }
        
        if let members = result.members {
            for member in members {
                viewState.members[member.id.server, default: [:]][member.id.user] = member
            }
        }
        
        var ids: [String] = []
        
        for message in result.messages {
            viewState.messages[message.id] = message
            ids.append(message.id)
        }
        
        viewState.channelMessages[channel.id] = ids.reversed() + viewState.channelMessages[channel.id]!
        
        return result
    }
    
    func loadMoreMessagesIfNeeded(current: Message?) async -> FetchHistory? {
        guard let item = current else {
            return await loadMoreMessages()
        }
        
        if $messages.wrappedValue.first! == item.id {
            return await loadMoreMessages(before: item.id)
        }
        
        return nil
    }
}

struct MessageableChannelView: View {
    @EnvironmentObject var viewState: ViewState
    @ObservedObject var viewModel: MessageableChannelViewModel
    
    @State var over18: Bool = false
    @State var showDetails: Bool = false
    @State var showingSelectEmoji = false
    @State var currentlyEditing: Message? = nil
    @State var highlighted: String? = nil
    @State var replies: [Reply] = []
    @State var scrollPosition: String? = nil
    @State var messages: [[MessageContentsViewModel]] = []
    @State var selection: Set<String> = []
    @State var nearBottom: Bool = false
    
    var toggleSidebar: () -> ()
    
    @Binding var disableScroll: Bool
    @Binding var disableSidebar: Bool
    
    @FocusState var focused: Bool
    @Namespace var topID
    
    var isCompactMode: Bool {
        return TEMP_IS_COMPACT_MODE.0
    }
    
    func viewMembers() {
        
    }

    func createInvite() {
        
    }
    
    func manageNotifs() {
        
    }
    
    func formatRelative(id: String) -> String {
        let created = createdAt(id: id)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        
        return formatter.localizedString(for: created, relativeTo: Date.now)
    }
    
    func getCurrentlyTyping() -> [(User, Member?)]? {
        viewState.currentlyTyping[viewModel.channel.id]?.compactMap({ user_id in
            guard let user = viewState.users[user_id] else {
                return nil
            }
            
            var member: Member?
            
            if let server = viewModel.server {
                member = viewState.members[server.id]![user_id]
            }
            
            return (user, member)
        })
    }
    
    func formatTypingIndicatorText(withUsers users: [(User, Member?)]) -> String {
        let base = ListFormatter.localizedString(byJoining: users.map({ (user, member) in member?.nickname ?? user.display_name ?? user.username }))
        
        let ending = users.count == 1 ? "is typing" : "are typing"
        
        return "\(base) \(ending)..."
    }
    
    func getAuthor(message: Binding<Message>) -> Binding<User> {
        Binding($viewState.users[message.author.wrappedValue]) ?? .constant(User(id: String(repeating: "0", count: 26), username: "Unknown", discriminator: "0000"))
    }
    
    func getMessages(scrollProxy: ScrollViewProxy) -> [[MessageContentsViewModel]] {
        
        let flatMessages = $viewModel.messages.compactMap { $messageId in Binding($viewState.messages[messageId]) }
        
        // Remove unknown messages
        DispatchQueue.main.async {
            viewModel.messages = flatMessages.map { $m in m.id }
        }
        
        let messages: [[MessageContentsViewModel]]
        
        if isCompactMode {
            messages = flatMessages
                .map { msg in
                    return [MessageContentsViewModel(
                        viewState: viewState,
                        message: msg,
                        author: getAuthor(message: msg),
                        member: viewModel.getMember(message: msg.wrappedValue),
                        server: $viewModel.server,
                        channel: $viewModel.channel,
                        replies: $replies,
                        channelScrollPosition: ChannelScrollController(proxy: scrollProxy, highlighted: $highlighted),
                        editing: $currentlyEditing
                    )]
                }
        } else {
            messages = flatMessages
                .reduce([]) { (messages: [[Binding<Message>]], $msg) in
                    if let lastMessage = messages.last?.last?.wrappedValue {
                        if lastMessage.author == msg.author && (msg.replies?.count ?? 0) == 0,  // same author
                           createdAt(id: lastMessage.id).distance(to: createdAt(id: msg.id)) < (5 * 60)  // at most 5 mins apart
                        {
                            return messages.prefix(upTo: messages.endIndex - 1) + [messages.last! + [$msg]]
                        }
                        
                        return messages + [[$msg]]
                    }
                    
                    return [[$msg]]
                }
                .map { msgs in
                    return msgs.map { msg in
                        return MessageContentsViewModel(
                            viewState: viewState,
                            message: msg,
                            author: getAuthor(message: msg),
                            member: viewModel.getMember(message: msg.wrappedValue),
                            server: $viewModel.server,
                            channel: $viewModel.channel,
                            replies: $replies,
                            channelScrollPosition: ChannelScrollController(proxy: scrollProxy, highlighted: $highlighted),
                            editing: $currentlyEditing
                        )
                    }
                }
        }
        
        Task(priority: .high) {
            if messages.isEmpty {
                await loadMoreMessages(before: nil)
            }
        }
        
        return messages
    }
    
    func loadMoreMessages(before message: String?) async {
        if !viewState.atTopOfChannel.contains(viewModel.channel.id) {
            if let new = await viewModel.loadMoreMessages(before: message), new.messages.count < 50 {
                viewState.atTopOfChannel.insert(viewModel.channel.id)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            PageToolbar(toggleSidebar: toggleSidebar) {
                NavigationLink(value: NavigationDestination.channel_info(viewModel.channel.id)) {
                    ChannelIcon(channel: viewModel.channel)

                    Image(systemName: "chevron.right")
                        .frame(height: 4)
                }
            } trailing: {
                // TODO: finish
//                if !selection.isEmpty {
//                    HStack {
//                        Button("Delete", role: .destructive) {
//                            ()
//                        }
//                        
//                        Button("Done", role: .cancel) {
//                            withAnimation {
//                                selection.removeAll()
//                            }
//                        }
//                    }
//                }
            }
            
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    GeometryReader { geoProxy in
                        ScrollViewReader { proxy in
                            ZStack(alignment: .bottomTrailing) {
                                ScrollView {
                                    LazyVStack {
                                        Group {
                                            if viewState.atTopOfChannel.contains(viewModel.channel.id) {
                                                VStack(alignment: .leading) {
                                                    Text("#\(viewModel.channel.getName(viewState))")
                                                        .font(.title)
                                                    Text("This is the start of your conversation.")
                                                }
                                            } else {
                                                Text("Loading more messages...")
                                            }
                                        }
                                        .id(topID)
                                        
                                        ForEach(messages, id: \.ids) { group in
                                            let first = group.first!
                                            let rest = group.dropFirst()
                                            
                                            VStack(alignment: .leading, spacing: 0) {
                                                if first.message.id == viewState.unreads[viewModel.channel.id]?.last_id, first.message.id != viewModel.messages.last {
                                                    HStack(spacing: 0) {
                                                        Text("NEW")
                                                            .font(.caption)
                                                            .fontWeight(.bold)
                                                            .padding(.horizontal, 8)
                                                            .background(RoundedRectangle(cornerRadius: 100).foregroundStyle(viewState.theme.accent))
    
                                                        Rectangle()
                                                            .frame(height: 1)
                                                            .foregroundStyle(viewState.theme.accent)
                                                    }
                                                }
                                                
                                                MessageWrapper(viewModel: first) {
                                                    MessageView(
                                                        viewModel: first,
                                                        isStatic: false
                                                    )
                                                    .padding(.top, 8)
                                                    .padding(.leading, selection.isEmpty ? 12 : 0)
                                                    .padding(.bottom, rest.isEmpty ? 4 : 0)
                                                    .padding(.trailing, selection.isEmpty ? 12 : 4)
                                                }
                                                .background((first.message.mentions?.firstIndex(of: viewState.currentUser!.id) != nil || highlighted == first.message.id
                                                             ? viewState.theme.mention
                                                             : viewState.theme.background).animation(.easeInOut))
                                                .animation(.easeInOut, value: highlighted)
                                                .environment(\.channelMessageSelection, $selection.animation())
                                                
                                                ForEach(rest) { message in
                                                    MessageWrapper(viewModel: message) {
                                                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                                                            Group {
                                                                if message.message.edited != nil {
                                                                    Text("(edited)")
                                                                        .font(.caption)
                                                                        .foregroundStyle(viewState.theme.foreground3)
                                                                        .multilineTextAlignment(.center)
                                                                } else {
                                                                    Spacer()
                                                                }
                                                            }
                                                            .frame(width: 60)
                                                            
                                                            MessageContentsView(viewModel: message)
                                                        }
                                                    }
                                                    .background((message.message.mentions?.firstIndex(of: viewState.currentUser!.id) != nil || highlighted == message.message.id
                                                                 ? viewState.theme.mention
                                                                 : viewState.theme.background).animation(.default))
                                                }
                                                .padding(.trailing, selection.isEmpty ? 12 : 4)
                                                .animation(.easeInOut, value: highlighted)
                                                .environment(\.channelMessageSelection, $selection.animation())
                                            }
                                            .id(group.ids)
                                        }
                                    }
                                }
                                .task {
                                    messages = getMessages(scrollProxy: proxy)
                                    
                                    if let unread = viewState.unreads[viewModel.channel.id], let last_id = unread.last_id {
                                        proxy.scrollTo(last_id)
                                    }
                                }
                                .onChange(of: viewModel.messages) { _, _ in
                                    messages = getMessages(scrollProxy: proxy)
                                }
                                .safeAreaPadding(EdgeInsets(top: 0, leading: 0, bottom: 32, trailing: 0))
                                .overlay(alignment: .top) {
                                    if let last_id = viewState.unreads[viewModel.channel.id]?.last_id, let last_message_id = viewModel.channel.last_message_id {
                                        if last_id < last_message_id {

                                            Text("New messages since \(formatRelative(id: last_id))")
                                                .padding(4)
                                                .frame(maxWidth: .infinity)
                                                .background(viewState.theme.accent)
                                                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 5, bottomTrailingRadius: 5))
                                                .onTapGesture {
                                                    proxy.scrollTo(last_id)
                                                }
                                        }
                                    }
                                }
                                .overlay(alignment: .bottomLeading) {
                                    if let users = getCurrentlyTyping(), !users.isEmpty {
                                        HStack {
                                            HStack(spacing: -6) {
                                                ForEach(users, id: \.0.id) { (user, member) in
                                                    Avatar(user: user, member: member, width: 12, height: 12)
                                                }
                                            }

                                            Text(formatTypingIndicatorText(withUsers: users))
                                                .font(Font.system(size: 14))
                                                .foregroundStyle(viewState.theme.foreground2)
                                                .lineLimit(1)

                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 12)
                                        .padding(.top, 2)
                                        .background(viewState.theme.messageBox)
                                    }
                                }
                                .scrollDisabled(disableScroll)
                                .scrollTargetLayout()
                                .defaultScrollAnchor(.bottom)
                                .scrollDismissesKeyboard(.immediately)
                                
                                Button {
                                    withAnimation {
                                        if let last = messages.last {
                                            proxy.scrollTo(last.ids)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "arrow.down")
                                        .foregroundStyle(viewState.theme.foreground)
                                }
                                .padding()
                                .background(viewState.theme.background2)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(.bottom, 24)
                                .padding(.trailing, 24)
                                .opacity(nearBottom ? 0 : 1)
                            }
                        }
                        .onScrollTargetVisibilityChange(idType: [String].self) { ids in
                            print(ids)
                            
                            withAnimation {
                                if let lastMessages = messages.last, Set(arrayLiteral: lastMessages.ids).isDisjoint(with: Set(ids)) {
                                    nearBottom = false
                                } else {
                                    nearBottom = true
                                }
                            }
                            
                            if let firstIds = ids.first, let firstMessages = messages.first, firstIds == firstMessages.ids {
                                Task {
                                    await loadMoreMessages(before: firstIds.first!)
                                }
                            } else if let lastIds = ids.last, let lastMessages = messages.last, lastIds == lastMessages.ids {
                                Task {
                                    await viewState.http.ackMessage(channel: viewModel.channel.id, message: lastIds.last!)
                                }
                            }
                        }
                        .onScrollPhaseChange { old, new in
                            if new != .idle {
                                disableSidebar = true
                            } else {
                                disableSidebar = false
                            }
                        }
                    }
                    
                    MessageBox(
                        channel: viewModel.channel,
                        server: viewModel.server,
                        channelReplies: $replies,
                        focusState: $focused,
                        showingSelectEmoji: $showingSelectEmoji,
                        editing: $currentlyEditing
                    )
                }
                
                if viewModel.channel.nsfw ?? false {
                    HStack(alignment: .center) {
                        Spacer()
                        
                        VStack(alignment: .center, spacing: 8) {
                            Spacer()
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .resizable()
                                .frame(width: 100, height:  100)
                            
                            Text(verbatim: viewModel.channel.getName(viewState))
                            
                            Text("This channel is marked as NSFW")
                                .font(.caption)
                            
                            Button {
                                over18 = true
                            } label: {
                                Text("I confirm that i am at least 18 years old")
                            }
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                    .background(viewState.theme.background.color)
                    .opacity(over18 ? 0.0 : 100)
                    
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(viewState.theme.background.color)
        .presentationDetents([.fraction(0.4)])
    }
}

struct MessageWrapper<C: View>: View {
    @EnvironmentObject var viewState: ViewState
    @Environment(\.channelMessageSelection) @Binding var selection
    
    @ObservedObject var viewModel: MessageContentsViewModel
    
    @ViewBuilder var inner: () -> C
    
    @State var showMemberSheet: Bool = false
    @State var showReportSheet: Bool = false
    @State var showReactSheet: Bool = false
    @State var showReactionsSheet: Bool = false
    
    private var canManageMessages: Bool {
        let member = viewModel.server.flatMap {
            viewState.members[$0.id]?[viewState.currentUser!.id]
        }
        
        let permissions = resolveChannelPermissions(from: viewState.currentUser!, targettingUser: viewState.currentUser!, targettingMember: member, channel: viewModel.channel, server: viewModel.server)
        
        return permissions.contains(.manageMessages)
    }
    
    private var isMessageAuthor: Bool {
        viewModel.message.author == viewState.currentUser?.id
    }
    
    private var canDeleteMessage: Bool {
        return isMessageAuthor || canManageMessages
    }
    
    func toggle() {
        if selection.contains(viewModel.message.id) {
            selection.remove(viewModel.message.id)
        } else {
            selection.insert(viewModel.message.id)
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if !selection.isEmpty {
                let contains = selection.contains(viewModel.message.id)
                
                Image(systemName: contains ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(contains ? viewState.theme.foreground : viewState.theme.background2, viewState.theme.accent)
                    .padding(.leading, 12)
                    .padding(.trailing, 12)
            }
            
            inner()
            
            Spacer()
        }
        .sheet(isPresented: $showReportSheet) {
            ReportMessageSheetView(showSheet: $showReportSheet, messageView: viewModel)
                .presentationBackground(viewState.theme.background)
        }
        .sheet(isPresented: $showReactSheet) {
            EmojiPicker(background: AnyView(viewState.theme.background)) { emoji in
                Task {
                    showReactSheet = false
                    await viewState.http.reactMessage(channel: viewModel.message.channel, message: viewModel.message.id, emoji: emoji.id)
                }
            }
            .padding([.top, .horizontal])
            .background(viewState.theme.background.ignoresSafeArea(.all))
            .presentationDetents([.large])
            .presentationBackground(viewState.theme.background)
        }
        .sheet(isPresented: $showReactionsSheet) {
            MessageReactionsSheet(viewModel: viewModel)
        }
        .contextMenu {
            if isMessageAuthor {
                Button {
                    Task {
                        var replies: [Reply] = []
                        
                        for reply in viewModel.message.replies ?? [] {
                            var message: Message? = viewState.messages[reply]
                            
                            if message == nil {
                                message = try? await viewState.http.fetchMessage(channel: viewModel.channel.id, message: reply).get()
                            }
                            
                            if let message {
                                replies.append(Reply(message: message, mention: viewModel.message.mentions?.contains(message.author) ?? false))
                            }
                        }
                        
                        viewModel.channelReplies = replies
                        viewModel.editing = viewModel.message
                    }
                } label: {
                    Label("Edit Message", systemImage: "pencil")
                }
            }
            
            Button(action: viewModel.reply, label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
            })
            
            Button {
                showReactSheet = true
            } label: {
                Label("React", systemImage: "face.smiling.inverse")
            }
            
            if !(viewModel.message.reactions?.isEmpty ?? true) {
                Button {
                    showReactionsSheet = true
                } label: {
                    Label("Reactions", systemImage: "face.smiling.inverse")
                }
            }
            
            if canManageMessages {
                if !(viewModel.message.pinned ?? false) {
                    Button {
                        Task {
                            await viewModel.pin()
                        }
                    } label: {
                        Label("Pin Message", systemImage: "pin.fill")
                    }
                } else {
                    Button {
                        Task {
                            await viewModel.unpin()
                        }
                    } label: {
                        Label("Unpin Message", systemImage: "pin.slash.fill")
                    }
                }
            }
            
            Button {
                copyText(text: viewModel.message.content ?? "")
            } label: {
                Label("Copy text", systemImage: "doc.on.clipboard")
            }
            
            Button {
                if let server = viewModel.server {
                    copyUrl(url: URL(string: "https://revolt.chat/app/server/\(server.id)/channel/\(viewModel.channel.id)/\(viewModel.message.id)")!)
                } else {
                    copyUrl(url: URL(string: "https://revolt.chat/app/channel/\(viewModel.channel.id)/\(viewModel.message.id)")!)
                    
                }
            } label: {
                Label("Copy Message Link", systemImage: "link")
            }
            
            Button {
                copyText(text: viewModel.message.id)
            } label: {
                Label("Copy Message ID", systemImage: "doc.on.clipboard")
            }
            
            Button {
                toggle()
            } label: {
                Label("Select Message", systemImage: "checkmark.circle.fill")
            }
            
            if canDeleteMessage {
                Button(role: .destructive, action: {
                    Task {
                        await viewModel.delete()
                    }
                }, label: {
                    Label("Delete Message", systemImage: "trash")
                })
            }
            
            if !isMessageAuthor {
                Button(role: .destructive, action: { showReportSheet.toggle() }, label: {
                    Label("Report Message", systemImage: "exclamationmark.triangle")
                })
            }
        }

        .gesture(TapGesture().onEnded(toggle), isEnabled: !selection.isEmpty)
    }
}

#Preview {
    @Previewable @StateObject var viewState = ViewState.preview()
    let messages = Binding($viewState.channelMessages["0"])!
    
    return MessageableChannelView(viewModel: .init(viewState: viewState, channel: viewState.channels["0"]!, server: viewState.servers[""], messages: messages), toggleSidebar: {}, disableScroll: .constant(false), disableSidebar: .constant(false))
        .applyPreviewModifiers(withState: viewState)
}
