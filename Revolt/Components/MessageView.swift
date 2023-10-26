//
//  Message.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation
import SwiftUI

struct MessageReplyView: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var mentions: [String]?
    @State var dead: Bool = false
    var id: String
    var channel: String

    @ViewBuilder
    var body: some View {
        let message = viewState.messages[id]
        if message != nil || dead {
            InnerMessageReplyView(mentions: $mentions, message: message)
        } else {
            if !viewState.loadingMessages.contains(id) {
                let _ = Task {
                    do {
                        let message = try await viewState.http.fetchMessage(channel: channel, message: id).get()
                        viewState.messages[id] = message
                    } catch {
                        dead = true
                    }
                }
            }

            Text("Loading...")
        }
    }
}

struct InnerMessageReplyView: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var mentions: [String]?
    var message: Message?
    
    var body: some View {
        if let message = message {
            HStack(spacing: 4) {
                let author = viewState.users[message.author] ?? User(id: "0", username: "Unknown User", discriminator: "0000")
                
                Avatar(user: author, width: 16, height: 16)
                
                HStack(spacing: 0) {
                    if mentions?.contains(message.author) == true {
                        Text("@")
                            .font(.caption)
                    }
                    
                    Text(author.username)
                        .font(.caption)
                }
                
                if let content = message.content {
                    Text(content)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        } else {
            Text("Unknown message")
        }
    }
}

class MessageViewModel: ObservableObject {
    @Binding var message: Message
    @Binding var author: User
    @Binding var channelReplies: [Reply]

    var viewState: ViewState

    init(viewState: ViewState, message: Binding<Message>, author: Binding<User>, replies: Binding<[Reply]>) {
        self.viewState = viewState
        self._message = message
        self._author = author
        self._channelReplies = replies
    }
    
    func delete() async {
        await viewState.http.deleteMessage(channel: message.channel, message: message.id)
    }

    func report() async {
        
    }
    
    func reply() {
        if !channelReplies.contains(where: { $0.message.id == message.id }) && channelReplies.count < 5 {
            channelReplies.append(Reply(message: message))
        }
        
        print(channelReplies)
    }
    
    func copyText() {
        UIPasteboard.general.string = message.content
    }
}

struct MessageView: View {
    @ObservedObject var viewModel: MessageViewModel
    @EnvironmentObject var viewState: ViewState
    
    @State var showMemberSheet: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            if let system = viewModel.message.system {
                HStack {
                    switch system {
                        case .user_joined(let content):
                            let user = viewState.users[content.id]!
                            Image(systemName: "arrow.forward")
                            Avatar(user: user)
                            Text(user.username)
                            Text("Joined")
                        default:
                            Text("unknown")
                    }
                }
            } else {
                if let replies = viewModel.message.replies {
                    VStack(alignment: .leading) {
                        ForEach(replies, id: \.self) { id in
                            MessageReplyView(mentions: $viewModel.message.mentions, id: id, channel: viewModel.message.channel)
                                .padding(.leading, 48)
                        }
                    }
                }
                HStack(alignment: .top) {
                    Avatar(user: viewModel.author, width: 32, height: 32)
                        .padding(.trailing, 8)
                        .onTapGesture {
                            showMemberSheet.toggle()
                        }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text(viewModel.author.username)
                                .fontWeight(.heavy)
                                .onTapGesture {
                                    showMemberSheet.toggle()
                                }

                            Text(createdAt(id: viewModel.message.id).formatted())
                                .font(.footnote)
                                .foregroundStyle(.gray)
                            
                            if viewModel.message.edited != nil {
                                Text("(edited)")
                                    .font(.footnote)
                                    .foregroundStyle(.gray)
                            }
                        }
                        
                        if let content = viewModel.message.content {
                            Text(content)
                        }
                        
                        VStack(alignment: .leading) {
                            ForEach(viewModel.message.attachments ?? []) { attachment in
                                LazyImage(source: .file(attachment), clipTo: RoundedRectangle(cornerRadius: 5))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .listRowSeparator(.hidden)
            }
        }
        .sheet(isPresented: $showMemberSheet) {
            let _ = print(1)
            let serverMembers = Binding($viewState.members[viewState.currentServer!])!
            let member = serverMembers[viewModel.author.id]
            let user = Binding($viewState.users[viewModel.message.author])!
            UserSheet(user: user, member: member)
        }

        .contextMenu {
            Button(action: viewModel.reply, label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
            })
            
            Button(action: viewModel.copyText, label: {
                Label("Copy contents", systemImage: "doc.on.clipboard")
            })
            
            Button(action: { showMemberSheet.toggle() }, label: {
                Label("Open Profile", systemImage: "person.crop.circle")
            })
            
            Button(role: .destructive, action: {
                Task {
                    await viewModel.delete()
                }
            }, label: {
                Label("Delete", systemImage: "trash")
            })
            
            Button(role: .destructive, action: {
                Task {
                    await viewModel.delete()
                }
            }, label: {
                Label("Report", systemImage: "exclamationmark.triangle")
            })
        }
        .swipeActions(edge: .trailing) {
            Button(action: viewModel.reply, label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
            })
            .tint(.green)
        }
    }
}

struct GhostMessageView: View {
    @EnvironmentObject var viewState: ViewState
    
    var message: QueuedMessage
    
    var body: some View {
        HStack(alignment: .top) {
            Avatar(user: viewState.currentUser!, width: 16, height: 16)
            VStack(alignment: .leading) {
                HStack {
                    Text(viewState.currentUser!.username)
                        .fontWeight(.heavy)
                    Text(createdAt(id: message.nonce).formatted())
                }
                Text(message.content)
                //.frame(maxWidth: .infinity, alignment: .leading)
            }
            //.frame(maxWidth: .infinity, alignment: .leading)
        }
        .listRowSeparator(.hidden)
    }
}

struct MessageView_Previews: PreviewProvider {
    static var viewState: ViewState = ViewState.preview()
    @State static var message = viewState.messages["01HD4VQY398JNRJY60JDY2QHA5"]!
    @State static var author = viewState.users[message.author]!
    @State static var replies: [Reply] = []
    
    static var previews: some View {
        MessageView(viewModel: MessageViewModel(viewState: viewState, message: $message, author: $author, replies: $replies))
            .environmentObject(viewState)
            .previewLayout(.sizeThatFits)
    }
}
