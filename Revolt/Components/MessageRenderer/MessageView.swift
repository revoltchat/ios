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
    private enum AvatarSize {
        case regular
        case compact
        
        var sizes: (CGFloat, CGFloat, CGFloat) {
            switch self {
                case .regular:
                    return (32, 16, 4)
                case .compact:
                    return (16, 8, 2)
            }
        }
    }
    @StateObject var viewModel: MessageContentsViewModel
    
    @EnvironmentObject var viewState: ViewState
    
    @State var showReportSheet: Bool = false
    @State var isStatic: Bool
    
    var isCompactMode: (Bool, Bool) {
        return TEMP_IS_COMPACT_MODE
    }
    
    private func pfpView(size: AvatarSize) -> some View {
        ZStack(alignment: .topLeading) {
            Avatar(user: viewModel.author, member: viewModel.member, masquerade: viewModel.message.masquerade, webhook: viewModel.message.webhook, width: size.sizes.0, height: size.sizes.0)
            
            if viewModel.message.masquerade != nil {
                Avatar(user: viewModel.author, member: viewModel.member, webhook: viewModel.message.webhook, width: size.sizes.1, height: size.sizes.1)
                    .padding(.leading, -size.sizes.2)
                    .padding(.top, -size.sizes.2)
            }
        }
        .onTapGesture {
            if !isStatic || viewModel.message.webhook != nil {
                viewState.openUserSheet(withId: viewModel.author.id, server: viewModel.server?.id)
            }
        }
    }
    
    private var nameView: some View {
        let name = viewModel.message.webhook?.name
            ?? viewModel.message.masquerade?.name
            ?? viewModel.member?.nickname
            ?? viewModel.author.display_name
            ?? viewModel.author.username
        
        return Text(verbatim: name)
            .onTapGesture {
                if !isStatic || viewModel.message.webhook != nil {
                    viewState.openUserSheet(withId: viewModel.author.id, server: viewModel.server?.id)
                }
            }
            .foregroundStyle(viewModel.member?.displayColour(theme: viewState.theme, server: viewModel.server!) ?? AnyShapeStyle(viewState.theme.foreground.color))
            .font(.body)
            .fontWeight(.bold)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let replies = viewModel.message.replies {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(replies, id: \.self) { id in
                        MessageReplyView(
                            mentions: viewModel.$message.mentions,
                            channelScrollPosition: viewModel.channelScrollPosition,
                            id: id,
                            server: viewModel.server,
                            channel: viewModel.channel
                        )
                            .padding(.leading, 42)
                    }
                }
            }
            
            if isCompactMode.0 {
                HStack(alignment: .top, spacing: 4) {
                    HStack(alignment: .center, spacing: 4) {
                        Text(createdAt(id: viewModel.message.id).formatted(Date.FormatStyle().hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)))
                            .font(.caption)
                            .foregroundStyle(viewState.theme.foreground2)
                        
                        if isCompactMode.1 {
                            pfpView(size: .compact)
                        }
                        
                        nameView
                        
                        if viewModel.author.bot != nil {
                            MessageBadge(text: String(localized: "Bot"), color: viewState.theme.accent.color)
                        }
                    }
                    
                    MessageContentsView(viewModel: viewModel, isStatic: isStatic)
                    
                    if viewModel.message.edited != nil {
                        Text("(edited)")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
                    
            } else {
                HStack(alignment: .top) {
                    pfpView(size: .regular)
                        .padding(.top, 2)
                        .padding(.trailing, 12)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            nameView
                            
                            if viewModel.author.bot != nil {
                                MessageBadge(text: String(localized: "Bot"), color: viewState.theme.accent.color)
                            }
                            
                            if viewModel.message.webhook != nil {
                                MessageBadge(text: String(localized: "Webhook"), color: viewState.theme.accent.color)

                            }
                            
                            Text(createdAt(id: viewModel.message.id).formatted(Date.FormatStyle().hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)))
                                .font(.caption)
                                .foregroundStyle(viewState.theme.foreground2)
                            
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
    @State static var highlighted: String? = nil
    
    static var previews: some View {
        ScrollViewReader { p in
            List {
                MessageView(viewModel: MessageContentsViewModel(viewState: viewState, message: $message, author: $author, member: $member, server: $server, channel: $channel, replies: $replies, channelScrollPosition: ChannelScrollController(proxy: p, highlighted: $highlighted), editing: .constant(nil)), isStatic: false)
            }
        }
            .applyPreviewModifiers(withState: viewState)
    }
}
