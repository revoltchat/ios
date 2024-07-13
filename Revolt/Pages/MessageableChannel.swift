//
//  MessageableChannel.swift
//  Revolt
//
//  Created by Angelo on 18/10/2023.
//

import Foundation
import SwiftUI
import Types

struct VisibleKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { }
}

struct ChannelScrollController {
    var proxy: ScrollViewProxy
    @Binding var highlighted: String?
    
    func scrollTo(_ id: String) {
        withAnimation {
            proxy.scrollTo(id)
            highlighted = id
        }
        
        Task {
            try! await Task.sleep(for: .seconds(2))
            
            withAnimation(.easeInOut) {
                highlighted = nil
            }
        }
    }
}

@MainActor
class MessageableChannelViewModel: ObservableObject {
    @ObservedObject var viewState: ViewState
    @Published var channel: Channel
    @Published var server: Server?
    @Binding var messages: [String]
    @Published var replies: [Reply] = []
    @Published var queuedMessages: [QueuedMessage] = []
    
    init(viewState: ViewState, channel: Channel, server: Server?, messages: Binding<[String]>) {
        self.viewState = viewState
        self.channel = channel
        self.server = server
        self._messages = messages
        self.replies = []
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
                viewState.members[member.id.server]![member.id.user] = member
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
    
    @State var foundAllMessages = false
    @State var over18: Bool = false
    @State var atBottom: Bool = false
    @State var showDetails: Bool = false
    @State var showingSelectEmoji = false
    @State var currentlyEditing: Message? = nil
    @State var highlighted: String? = nil
    
    @Binding var showSidebar: Bool
    
    @FocusState var focused: Bool
    
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
        
        return "\(base) \(ending)"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            PageToolbar(showSidebar: $showSidebar) {
                NavigationLink(value: NavigationDestination.channel_info(viewModel.channel.id)) {
                    ChannelIcon(channel: viewModel.channel)

                    Image(systemName: "chevron.right")
                        .frame(height: 4)
                }
            } trailing: {
                EmptyView()
            }
            
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    GeometryReader { geoProxy in
                        ScrollViewReader { proxy in
                            List {
                                if foundAllMessages {
                                    VStack(alignment: .leading) {
                                        Text("#\(viewModel.channel.getName(viewState))")
                                            .font(.title)
                                        Text("This is the start of your conversation.")
                                    }
                                    .listRowBackground(viewState.theme.background.color)
                                } else {
                                    Text("Loading more messages...")
                                        .onAppear {
                                            Task {
                                                if let new = await viewModel.loadMoreMessages(before: viewModel.messages.first) {
                                                    foundAllMessages = new.messages.count < 50
                                                }
                                            }
                                        }
                                        .listRowBackground(viewState.theme.background.color)
                                }
                                
                                let messages = $viewModel.messages.map { $messageId -> Binding<Message> in
                                    let message = Binding($viewState.messages[messageId])!
                                    
                                    return message
                                }
                                    .reduce([]) { (messages: [[Binding<Message>]], $msg) in
                                        if let lastMessage = messages.last?.last?.wrappedValue {
                                            if lastMessage.author == msg.author && (msg.replies?.count ?? 0) == 0 {
                                                return messages.prefix(upTo: messages.endIndex - 1) + [messages.last! + [$msg]]
                                            }
                                            
                                            return messages + [[$msg]]
                                        }
                                        
                                        return [[$msg]]
                                    }
                                    .map { msgs in
                                        return msgs.map { msg -> MessageContentsViewModel in
                                            let author = Binding($viewState.users[msg.author.wrappedValue])!
                                            
                                            return MessageContentsViewModel(
                                                viewState: viewState,
                                                message: msg,
                                                author: author,
                                                member: viewModel.getMember(message: msg.wrappedValue),
                                                server: $viewModel.server,
                                                channel: $viewModel.channel,
                                                replies: $viewModel.replies,
                                                channelScrollPosition: ChannelScrollController(proxy: proxy, highlighted: $highlighted),
                                                editing: $currentlyEditing
                                            )
                                        }
                                    }
                                
                                ForEach(messages, id: \.last!.message.id) { group in
                                    let first = group.first!
                                    let rest = group.dropFirst()
                                    
                                    MessageView(
                                        viewModel: first,
                                        isStatic: false
                                    )
                                    .listRowBackground(first.message.mentions?.firstIndex(of: viewState.currentUser!.id) != nil || highlighted == first.message.id ? viewState.theme.mention : viewState.theme.background)
                                    .animation(.linear, value: highlighted == first.message.id)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: rest.isEmpty ? 4 : 0, trailing: 12))
                                    .id(first.message.id)
                                    
                                    ForEach(rest, id: \.message.id) { message in
                                        MessageContentsView(viewModel: message, isStatic: false)
                                            .listRowBackground(message.message.mentions?.firstIndex(of: viewState.currentUser!.id) != nil || highlighted == message.message.id ? viewState.theme.mention : viewState.theme.background)
                                            .animation(.linear, value: highlighted == first.message.id)
                                            .id(message.message.id)
                                    }
                                    .padding(.leading, 40)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                                    
                                    //                                    .if(lastMessage.id == viewModel.messages.last, content: {
                                    //                                        $0.onAppear {
                                    //                                            let message = group.last!.message
                                    //                                            if var unread = viewState.unreads[viewModel.channel.id] {
                                    //                                                unread.last_id = lastMessage.id
                                    //                                                viewState.unreads[viewModel.channel.id] = unread
                                    //                                            } else {
                                    //                                                viewState.unreads[viewModel.channel.id] = Unread(id: Unread.Id(channel: viewModel.channel.id, user: viewState.currentUser!.id), last_id: lastMessage.id)
                                    //                                            }
                                    //
                                    //                                            Task {
                                    //                                                await viewState.http.ackMessage(channel: viewModel.channel.id, message: message.id)
                                    //                                            }
                                    //                                        }
                                    //                                    })
                                    //
                                    //                                    if lastMessage.id == viewState.unreads[viewModel.channel.id]?.last_id, lastMessage.id != viewModel.messages.last {
                                    //                                        HStack(spacing: 0) {
                                    //                                            Text("NEW")
                                    //                                                .font(.caption)
                                    //                                                .fontWeight(.bold)
                                    //                                                .padding(.horizontal, 8)
                                    //                                                .background(RoundedRectangle(cornerRadius: 100).fill(viewState.theme.accent.color))
                                    //
                                    //                                            Rectangle()
                                    //                                                .frame(height: 1)
                                    //                                                .foregroundStyle(viewState.theme.accent.color)
                                    //                                        }
                                    //                                    }
                                }
                                
#if os(iOS)
                                let intersects = UIScreen.main.bounds.intersects(geoProxy.frame(in: .global))
#elseif os(macOS)
                                let intersects = NSIntersectsRect(NSScreen.main!.frame, geoProxy.frame(in: .global))
#endif

                                
                                Color.clear
                                    .id("bottom")
                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                    .listRowBackground(Color.clear)
                                    .frame(height: 0)
                                    .preference(
                                        key: VisibleKey.self,
                                        value: intersects
                                    )
                                    .onPreferenceChange(VisibleKey.self) { isVisible in
                                        atBottom = isVisible
                                    }
                                    .onChange(of: messages) { (_, _) in
                                        withAnimation {
                                            proxy.scrollTo("bottom")
                                        }
                                    }
                                
                            }
                            .safeAreaPadding(EdgeInsets(top: 0, leading: 0, bottom: 24, trailing: 0))
                            .defaultScrollAnchor(.bottom)
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
                                    VStack(alignment: .leading) {
                                        HStack {
                                            HStack(spacing: -10) {
                                                ForEach(users, id: \.0.id) { (user, member) in
                                                    Avatar(user: user, member: member, width: 16, height: 16)
                                                }
                                            }
                                            
                                            Text(formatTypingIndicatorText(withUsers: users))
                                                .font(.callout)
                                                .foregroundStyle(viewState.theme.foreground2)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .background(viewState.theme.messageBox)
                                }
                            }
                            .environment(\.defaultMinListRowHeight, 0)
                            .background(viewState.theme.background)
                        }
                        .scrollDismissesKeyboard(.automatic)
                    }
                    .gesture(TapGesture().onEnded {
                        focused = false
                        showingSelectEmoji = false
                    })
                    
                    MessageBox(
                        channel: viewModel.channel,
                        server: viewModel.server,
                        channelReplies: $viewModel.replies,
                        focusState: $focused,
                        showingSelectEmoji: $showingSelectEmoji,
                        editing: $currentlyEditing
                    )
                }
                
                if viewModel.channel.nsfw {
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
    @StateObject var viewState = ViewState.preview()
    let messages = Binding($viewState.channelMessages["0"])!
    
    return MessageableChannelView(viewModel: .init(viewState: viewState, channel: viewState.channels["0"]!, server: viewState.servers[""], messages: messages), foundAllMessages: true, showSidebar: .constant(false))
        .applyPreviewModifiers(withState: viewState)
}
