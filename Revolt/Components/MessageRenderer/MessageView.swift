//
//  Message.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation
import SwiftUI

class MessageViewModel: ObservableObject {
    @Binding var message: Message
    @Binding var author: User
    @Binding var channelReplies: [Reply]
    @Binding var channelScrollPosition: String?

    var viewState: ViewState

    init(viewState: ViewState, message: Binding<Message>, author: Binding<User>, replies: Binding<[Reply]>, channelScrollPosition: Binding<String?>) {
        self.viewState = viewState
        self._message = message
        self._author = author
        self._channelReplies = replies
        self._channelScrollPosition = channelScrollPosition
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
                            MessageReplyView(mentions: $viewModel.message.mentions, channelScrollPosition: $viewModel.channelScrollPosition, id: id, channel: viewModel.message.channel)
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
                                .font(.caption2)
                                .foregroundStyle(.gray)
                            
                            if viewModel.message.edited != nil {
                                Text("(edited)")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                        
                        if let content = viewModel.message.content {
                            Text(content)
                                .font(.system(size: 16))
                        }
                        
                        VStack(alignment: .leading) {
                            ForEach(viewModel.message.attachments ?? []) { attachment in
                                MessageAttachment(attachment: attachment)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .listRowSeparator(.hidden)
            }
        }
        .background(viewState.theme.background.color)
        .sheet(isPresented: $showMemberSheet) {
            let user = Binding($viewState.users[viewModel.message.author])!

            if case .server(let serverId) = viewState.currentServer {
                let serverMembers = Binding($viewState.members[serverId])!
                let member = serverMembers[viewModel.author.id]
                
                UserSheet(user: user, member: member)
            } else {
                UserSheet(user: user, member: Binding.constant(nil))
            }
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
    @State static var channelScrollPosition: String? = nil
    
    static var previews: some View {
        MessageView(viewModel: MessageViewModel(viewState: viewState, message: $message, author: $author, replies: $replies, channelScrollPosition: $channelScrollPosition))
            .environmentObject(viewState)
            .previewLayout(.sizeThatFits)
    }
}
