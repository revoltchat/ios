//
//  Message.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation
import SwiftUI
import Types

struct MessageView: View {
    @StateObject var viewModel: MessageContentsViewModel
    
    @EnvironmentObject var viewState: ViewState
    
    @State var showReportSheet: Bool = false
    @State var isStatic: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let replies = viewModel.message.replies {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(replies, id: \.self) { id in
                        MessageReplyView(mentions: viewModel.$message.mentions, channelScrollPosition: viewModel.$channelScrollPosition, id: id, channel: viewModel.message.channel)
                            .padding(.leading, 38)
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
                        viewState.openUserSheet(withId: viewModel.author.id, server: viewModel.server?.id)
                    }
                }
                .padding(.trailing, 8)
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        let name = viewModel.message.masquerade?.name ?? viewModel.member?.nickname ?? viewModel.author.display_name ?? viewModel.author.username

                        Text(verbatim: name)
                            .onTapGesture {
                                if !isStatic {
                                    viewState.openUserSheet(withId: viewModel.author.id, server: viewModel.server?.id)
                                }
                            }
                            .foregroundStyle(viewModel.member?.displayColour(theme: viewState.theme, server: viewModel.server!) ?? AnyShapeStyle(viewState.theme.foreground.color))
                            .font(.body)
                            .fontWeight(.bold)

                        
                        if viewModel.author.bot != nil {
                            MessageBadge(text: String(localized: "Bot"), color: viewState.theme.accent.color)
                        }
                        
                        Text(createdAt(id: viewModel.message.id).formatted())
                            .font(.caption)
                            .foregroundStyle(.gray)
                        
                        if viewModel.message.edited != nil {
                            Text("(edited)")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                    
                    MessageContentsView(viewModel: viewModel, isStatic: isStatic)
                }
            }
        }
        .font(Font.system(size: 14.0))
        .listRowSeparator(.hidden)
    }
}

//struct GhostMessageView: View {
//    @EnvironmentObject var viewState: ViewState
//    
//    var message: QueuedMessage
//    
//    var body: some View {
//        HStack(alignment: .top) {
//            Avatar(user: viewState.currentUser!, width: 16, height: 16)
//            VStack(alignment: .leading) {
//                HStack {
//                    Text(viewState.currentUser!.username)
//                        .fontWeight(.heavy)
//                    Text(createdAt(id: message.nonce).formatted())
//                }
//                Contents(text: message.content)
//                //.frame(maxWidth: .infinity, alignment: .leading)
//            }
//            //.frame(maxWidth: .infinity, alignment: .leading)
//        }
//        .listRowSeparator(.hidden)
//    }
//}

struct MessageView_Previews: PreviewProvider {
    static var viewState: ViewState = ViewState.preview()
    @State static var message = viewState.messages["01HDEX6M2E3SHY8AC2S6B9SEAW"]!
    @State static var author = viewState.users[message.author]!
    @State static var member = viewState.members["0"]!["0"]
    @State static var channel = viewState.channels["0"]!
    @State static var server = viewState.servers["0"]
    @State static var replies: [Reply] = []
    @State static var channelScrollPosition: String? = nil
    
    static var previews: some View {
        List {
            MessageView(viewModel: MessageContentsViewModel(viewState: viewState, message: $message, author: $author, member: $member, server: $server, channel: $channel, replies: $replies, channelScrollPosition: $channelScrollPosition, editing: .constant(nil)), isStatic: false)
        }
            .applyPreviewModifiers(withState: viewState)
    }
}
