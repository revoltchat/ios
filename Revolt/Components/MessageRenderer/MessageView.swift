//
//  Message.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation
import SwiftUI
import Shiny

struct MessageView: View {
    @StateObject var viewModel: MessageContentsViewModel
    
    @EnvironmentObject var viewState: ViewState
    
    @State var showMemberSheet: Bool = false
    @State var showReportSheet: Bool = false
    @State var isStatic: Bool

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                if let replies = viewModel.message.replies {
                    VStack(alignment: .leading) {
                        ForEach(replies, id: \.self) { id in
                            MessageReplyView(mentions: viewModel.$message.mentions, channelScrollPosition: viewModel.$channelScrollPosition, id: id, channel: viewModel.message.channel)
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
                    .onTapGesture {
                        if !isStatic {
                            showMemberSheet.toggle()
                        }
                    }
                    .padding(.trailing, 8)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text(verbatim: viewModel.message.masquerade?.name ?? viewModel.author.display_name ?? viewModel.author.username)
                                .onTapGesture {
                                    if !isStatic {
                                        showMemberSheet.toggle()
                                    }
                                }
                                .foregroundStyle(viewModel.member?.displayColour(server: viewModel.server!) ?? viewState.theme.foreground.color)
                                .fontWeight(.heavy)

                            
                            if viewModel.author.bot != nil {
                                MessageBadge(text: String(localized: "Bot"), color: viewState.theme.accent.color)
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
                        
                        MessageContentsView(viewModel: viewModel, isStatic: isStatic)
                    }
                }
            }
        }
        .listRowSeparator(.hidden)
        .sheet(isPresented: $showMemberSheet) {
            let user = viewModel.$author
            
            if case .server(let serverId) = viewState.currentServer {
                let serverMembers = Binding($viewState.members[serverId])!
                let member = serverMembers[user.id]
                
                UserSheet(user: user, member: member)
            } else {
                UserSheet(user: user, member: Binding.constant(nil))
            }
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
                Contents(text: message.content)
                //.frame(maxWidth: .infinity, alignment: .leading)
            }
            //.frame(maxWidth: .infinity, alignment: .leading)
        }
        .listRowSeparator(.hidden)
    }
}

//struct MessageView_Previews: PreviewProvider {
//    static var viewState: ViewState = ViewState.preview()
//    @State static var message = viewState.messages["01HD4VQY398JNRJY60JDY2QHA5"]!
//    @State static var author = viewState.users[message.author]!
//    @State static var member = viewState.members["0"]!["0"]
//    @State static var channel = viewState.channels["0"]!
//    @State static var server = viewState.servers["0"]
//    @State static var replies: [Reply] = []
//    @State static var channelScrollPosition: String? = nil
//    
//    static var previews: some View {
//        MessageView(viewModel: viewModel(
//            viewState: viewState,
//            message: $message,
//            author: $author,
//            member: $member,
//            server: $server,
//            channel: $channel,
//            replies: $replies,
//            channelScrollPosition: $channelScrollPosition
//        ), isStatic: false)
//            .environmentObject(viewState)
//            .previewLayout(.sizeThatFits)
//    }
//}
