//
//  TextChannel.swift
//  Revolt
//
//  Created by Angelo on 18/10/2023.
//

import Foundation
import SwiftUI

@MainActor
class MessageableChannelViewModel: ObservableObject {
    var viewState: ViewState
    @Published var channel: Channel
    var messages: Binding<[String]>
    @Published var replies: [Reply] = []
    @Published var queuedMessages: [QueuedMessage] = []
    
    init(viewState: ViewState, channel: Channel, messages: Binding<[String]>) {
        self.viewState = viewState
        self.channel = channel
        self.messages = messages
        self.replies = []
        self.queuedMessages = []
    }
    
    func loadMoreMessages(before: String? = nil) async -> FetchHistory {
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
        
        if messages.wrappedValue.first! == item.id {
            return await loadMoreMessages(before: item.id)
        }
        
        return nil
    }
}

struct MessageableChannelView: View {
    @EnvironmentObject var viewState: ViewState
    @ObservedObject var viewModel: MessageableChannelViewModel
    
    @State var showSheet = false
    @State var foundAllMessages = false
    @State var scrollPosition: String?

    func viewMembers() {
        
    }
    
    func createInvite() {
        
    }
    
    func manageNotifs() {
        
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                                foundAllMessages = await viewModel.loadMoreMessages(before: viewModel.messages.wrappedValue.first).messages.count < 50
                            }
                        }
                        .listRowBackground(viewState.theme.background.color)
                }
                
                ForEach($viewModel.messages.wrappedValue, id: \.self) { messageId in
                    let message = Binding($viewState.messages[messageId.wrappedValue])!
                    let author = Binding($viewState.users[message.author.wrappedValue])!
                    
                    MessageView(viewModel: MessageViewModel(viewState: viewState, message: message, author: author, replies: $viewModel.replies, channelScrollPosition: $scrollPosition))
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                .listRowBackground(viewState.theme.background.color)
            }
            .scrollPosition(id: $scrollPosition)
            .listStyle(.plain)
            .listRowSeparator(.hidden)
            .background(viewState.theme.background.color)
            
            //            List(viewModel.queuedMessages, id: \.nonce) { message in
            //                GhostMessageView(message: message)
            //            }
            //                .backgroundStyle(.white)
            //                .listStyle(.plain)
            
            MessageBox(channel: viewModel.channel, channelReplies: $viewModel.replies)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(action: { showSheet.toggle() }) {
                    ChannelIcon(channel: viewModel.channel)
                    Image(systemName: "chevron.right")
                        .frame(height: 4)
                }
            }
        }
        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
        .sheet(isPresented: $showSheet) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    ZStack {
                        Circle()
                            .frame(width: 40, height: 49)
                        Image(systemName: "number")
                            .colorInvert()
                    }
                    
                    Text(viewModel.channel.getName(viewState))
                        .font(.title2)
                }
                
                if let description = viewModel.channel.description {
                    Text("Channel description")
                        .font(.caption)
                        .bold()
                    
                    Text(description)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Options")
                        .font(.caption)
                        .bold()
                    
                    Button(action: viewMembers) {
                        Image(systemName: "list.bullet")
                        Text("Members")
                    }
                    
                    Button(action: createInvite) {
                        Image(systemName: "plus")
                        Text("Invite")
                    }
                    
                    Button(action: manageNotifs) {
                        Image(systemName: "bell.fill")
                        Text("Manage notifications")
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(viewState.theme.background.color)
            .presentationDetents([.fraction(0.4)])
        }
    }
}
