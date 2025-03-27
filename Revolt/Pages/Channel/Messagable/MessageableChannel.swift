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
    @State var topMessage: MessageContentsViewModel? = nil
    @State var bottomMessage: MessageContentsViewModel? = nil
    @State var messages: [[MessageContentsViewModel]] = []
    
    var toggleSidebar: () -> ()
    
    @Binding var disableScroll: Bool
    @Binding var disableSidebar: Bool
    
    @FocusState var focused: Bool
    
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
            topMessage = messages.first?.first
            bottomMessage = messages.last?.last
            
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
            }
            
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    GeometryReader { geoProxy in
                        ScrollViewReader { proxy in
                            List {
                                if viewState.atTopOfChannel.contains(viewModel.channel.id) {
                                    VStack(alignment: .leading) {
                                        Text("#\(viewModel.channel.getName(viewState))")
                                            .font(.title)
                                        Text("This is the start of your conversation.")
                                    }
                                    .listRowBackground(viewState.theme.background)
                                } else {
                                    Text("Loading more messages...")
                                        .listRowBackground(viewState.theme.background)
                                        .listRowSeparator(.hidden)
                                }
                                
                                ForEach(messages, id: \.last!.message.id) { group in
                                    let first = group.first!
                                    let rest = group.dropFirst()
                                    
                                    MessageView(
                                        viewModel: first,
                                        isStatic: false
                                    )
                                    .listRowBackground((first.message.mentions?.firstIndex(of: viewState.currentUser!.id) != nil || highlighted == first.message.id
                                                       ? viewState.theme.mention
                                                        : viewState.theme.background).animation(.easeInOut))
                                    .animation(.easeInOut, value: highlighted)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: rest.isEmpty ? 4 : 0, trailing: 12))
                                    .id(first.message.id)
                                    
                                    ForEach(rest, id: \.message.id) { message in
                                        MessageContentsView(viewModel: message, isStatic: false)
                                            .listRowBackground((message.message.mentions?.firstIndex(of: viewState.currentUser!.id) != nil || highlighted == message.message.id
                                                               ? viewState.theme.mention
                                                               : viewState.theme.background).animation(.default))
                                            .id(message.message.id)
                                    }
                                    .animation(.easeInOut, value: highlighted)
                                    .padding(.leading, 48)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                                
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
                                        .listRowBackground(viewState.theme.background)
                                        .listRowSeparator(.hidden)
                                    }
                                }
                                
//                                Color.clear
//                                    .listRowSeparator(.hidden)
//                                    .id("bottom")
//                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
//                                    .listRowBackground(Color.clear)
//                                    .frame(height: 0)
//                                    .onAppear {
//                                        if let lastMessage = messages.last?.last {
//                                        }
//                                    }
//                                    .onChange(of: messages) { (_, _) in
//                                        withAnimation {
//                                            proxy.scrollTo("bottom")
//                                        }
//                                    }
                            }
                            .task {
                                messages = getMessages(scrollProxy: proxy)
                            }
                            .onChange(of: viewModel.messages, { _, _ in
                                messages = getMessages(scrollProxy: proxy)
                            })
                            .onScrollTargetVisibilityChange(idType: String.self, { ids in
                                if let firstId = ids.first, firstId == topMessage?.message.id {
                                    Task {
                                        await loadMoreMessages(before: firstId)
                                    }
                                } else if let lastId = ids.last, lastId == bottomMessage?.message.id {
                                    Task {
                                        await viewState.http.ackMessage(channel: viewModel.channel.id, message: lastId)
                                    }
                                }
                            })
                            .onScrollPhaseChange({ old, new in
                                if new != .idle {
                                    disableSidebar = true
                                } else {
                                    disableSidebar = false
                                }
                            })
                            .safeAreaPadding(EdgeInsets(top: 0, leading: 0, bottom: 24, trailing: 0))
                            .listStyle(.plain)
                            .listRowSeparator(.hidden)
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
                            .environment(\.defaultMinListRowHeight, 0)
                            //.gesture(TapGesture().onEnded { focused = false }, isEnabled: focused)
                            .scrollDismissesKeyboard(.never)
                            .scrollDisabled(disableScroll)
                        }
                        .defaultScrollAnchor(.bottom)
                        .scrollDismissesKeyboard(.never)
                    }
                    .gesture(TapGesture().onEnded { focused = false }, isEnabled: focused)
                    
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

#Preview {
    @Previewable @StateObject var viewState = ViewState.preview()
    let messages = Binding($viewState.channelMessages["0"])!
    
    return MessageableChannelView(viewModel: .init(viewState: viewState, channel: viewState.channels["0"]!, server: viewState.servers[""], messages: messages), toggleSidebar: {}, disableScroll: .constant(false), disableSidebar: .constant(false))
        .applyPreviewModifiers(withState: viewState)
}
