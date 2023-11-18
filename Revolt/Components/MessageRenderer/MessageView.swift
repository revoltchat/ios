//
//  Message.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation
import SwiftUI

@MainActor
class MessageViewModel: ObservableObject {
    @Binding var message: Message
    @Binding var author: User
    @Binding var member: Member?
    @Binding var server: Server?
    @Binding var channel: Channel
    @Binding var channelReplies: [Reply]
    @Binding var channelScrollPosition: String?

    var viewState: ViewState

    init(viewState: ViewState, message: Binding<Message>, author: Binding<User>, member: Binding<Member?>, server: Binding<Server?>, channel: Binding<Channel>, replies: Binding<[Reply]>, channelScrollPosition: Binding<String?>) {
        self.viewState = viewState
        self._message = message
        self._author = author
        self._member = member
        self._server = server
        self._channel = channel
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
    @State var showReportSheet: Bool = false
    @State var isStatic: Bool
    
    private var isModeratorInChannel: Bool {
        return false // TODO: need bit op stuff
    }
    
    private var isMessageAuthor: Bool {
        viewModel.message.author == viewState.currentUser?.id
    }
    
    private var canDeleteMessage: Bool {
        return isMessageAuthor || isModeratorInChannel
    }

    var body: some View {
        VStack(alignment: .leading) {
            if let system = viewModel.message.system {
                HStack {
                    switch system {
                        case .user_joined(let content):
                            let user = viewState.users[content.id]!
                            Image(systemName: "arrow.forward")
                            Avatar(user: user, masquerade: viewModel.message.masquerade)
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
                    ZStack(alignment: .topLeading) {
                        Avatar(user: viewModel.author, member: viewModel.member, masquerade: viewModel.message.masquerade, width: 32, height: 32)

                        if viewModel.message.masquerade != nil {
                            Avatar(user: viewModel.author, member: viewModel.member, width: 16, height: 16)
                                .padding(.leading, -4)
                                .padding(.top, -4)
                        }
                    }
                    .padding(.trailing, 8)
                    .onTapGesture {
                        if !isStatic {
                            showMemberSheet.toggle()
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text(viewModel.message.masquerade?.name ?? viewModel.author.display_name ?? viewModel.author.username)
                                .fontWeight(.heavy)
                                .onTapGesture {
                                    if !isStatic {
                                        showMemberSheet.toggle()
                                    }
                                }
                            
                            if viewModel.author.bot != nil {
                                MessageBadge(text: "Bot", color: viewState.theme.accent.color)
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
        .sheet(isPresented: $showReportSheet) {
            ReportMessageSheetView(showSheet: $showReportSheet, messageView: viewModel)
        }

        .contextMenu(self.isStatic ? nil : ContextMenu {
            Button(action: viewModel.reply, label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
            })
            
            Button(action: viewModel.copyText, label: {
                Label("Copy contents", systemImage: "doc.on.clipboard")
            })
            
            Button(action: { showMemberSheet.toggle() }, label: {
                Label("Open Profile", systemImage: "person.crop.circle")
            })
            
            if isMessageAuthor {
                Button(role: .destructive, action: {
                    Task {
                        
                    }
                }, label: {
                    Label("Edit", systemImage: "pencil")
                })
            }
            
            if canDeleteMessage {
                Button(role: .destructive, action: {
                    Task {
                        await viewModel.delete()
                    }
                }, label: {
                    Label("Delete", systemImage: "trash")
                })
            }
            
            if !isMessageAuthor {
                Button(role: .destructive, action: { showReportSheet.toggle() }, label: {
                    Label("Report", systemImage: "exclamationmark.triangle")
                })
            }
        }
        )
        .swipeActions(edge: .trailing) {
            isStatic ? nil :
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
    @State static var member = viewState.members["0"]!["0"]
    @State static var channel = viewState.channels["0"]!
    @State static var server = viewState.servers["0"]
    @State static var replies: [Reply] = []
    @State static var channelScrollPosition: String? = nil
    
    static var previews: some View {
        MessageView(viewModel: MessageViewModel(
            viewState: viewState,
            message: $message,
            author: $author,
            member: $member,
            server: $server,
            channel: $channel,
            replies: $replies,
            channelScrollPosition: $channelScrollPosition
        ), isStatic: false)
            .environmentObject(viewState)
            .previewLayout(.sizeThatFits)
    }
}
