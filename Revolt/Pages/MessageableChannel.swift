//
//  TextChannel.swift
//  Revolt
//
//  Created by Angelo on 18/10/2023.
//

import Foundation
import SwiftUI

var isPreview: Bool {
#if DEBUG
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
#else
    false
#endif
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
        
        let result = try! await viewState.http.fetchHistory(channel: channel.id, limit: 50, before: before).get()

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
    @State var scrollPosition: String? = nil
    
    @Binding var showSidebar: Bool

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
    
    var body: some View {
        VStack(spacing: 0) {
            PageToolbar(showSidebar: $showSidebar) {
                NavigationLink(value: NavigationDestination.channel_settings(viewModel.channel.id)) {
                    ChannelIcon(channel: viewModel.channel)
                    Image(systemName: "chevron.right")
                        .frame(height: 4)
                }
            } trailing: {
                EmptyView()
            }
            
            ZStack {
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ZStack(alignment: .top) {
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
                                
                                ForEach($viewModel.messages, id: \.self) { messageId in
                                    let message = Binding($viewState.messages[messageId.wrappedValue])!
                                    let author = Binding($viewState.users[message.author.wrappedValue])!
                                    
                                    MessageView(
                                        viewModel: MessageViewModel(
                                            viewState: viewState,
                                            message: message,
                                            author: author,
                                            member: viewModel.getMember(message: message.wrappedValue),
                                            server: $viewModel.server,
                                            channel: $viewModel.channel,
                                            replies: $viewModel.replies,
                                            channelScrollPosition: $scrollPosition),
                                        isStatic: false
                                    )
                                    .if(messageId.wrappedValue == viewModel.messages.last, content: {
                                        $0.onAppear {
                                            if var unread = viewState.unreads[viewModel.channel.id] {
                                                unread.last_id = messageId.wrappedValue
                                                viewState.unreads[viewModel.channel.id] = unread
                                            } else {
                                                viewState.unreads[viewModel.channel.id] = Unread(id: Unread.Id(channel: viewModel.channel.id, user: viewState.currentUser!.id), last_id: messageId.wrappedValue)
                                            }
                                            
                                            Task {
                                                await viewState.http.ackMessage(channel: viewModel.channel.id, message: messageId.wrappedValue)
                                            }
                                        }
                                    })
                                    
                                    if messageId.wrappedValue == viewState.unreads[viewModel.channel.id]?.last_id, messageId.wrappedValue != viewModel.messages.last {
                                        HStack(spacing: 0) {
                                            Text("NEW")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .padding(.horizontal, 8)
                                                .background(RoundedRectangle(cornerRadius: 100).fill(viewState.theme.accent.color))
                                            
                                            Rectangle()
                                                .frame(height: 1)
                                                .foregroundStyle(viewState.theme.accent.color)
                                        }
                                    }
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                                .listRowBackground(viewState.theme.background.color)
                            }
                            .scrollPosition(id: $scrollPosition)
                            .listStyle(.plain)
                            .listRowSeparator(.hidden)
                            .background(viewState.theme.background.color)
                            
                            if let last_id = viewState.unreads[viewModel.channel.id]?.last_id, let last_message_id = viewModel.channel.last_message_id {
                                if last_id < last_message_id {
                                    
                                    Text("New messages since \(formatRelative(id: last_id))")
                                        .padding(4)
                                        .frame(maxWidth: .infinity)
                                        .background(viewState.theme.accent.color)
                                        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 5, bottomTrailingRadius: 5))
                                        .onTapGesture {
                                            proxy.scrollTo(last_id)
                                        }
                                }
                            }
                        }
                        
                    }
                    MessageBox(channel: viewModel.channel, server: viewModel.server, channelReplies: $viewModel.replies)
                    
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
                    //.frame(maxWidth: .infinity)
                    .opacity(over18 ? 0.0 : 100)

                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(viewState.theme.background.color)
        .presentationDetents([.fraction(0.4)])
    }
}
