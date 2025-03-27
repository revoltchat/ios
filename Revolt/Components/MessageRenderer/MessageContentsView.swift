//
//  MessageContentsView.swift
//  Revolt
//
//  Created by Angelo on 12/12/2023.
//

import Foundation
import SwiftUI
import Types

@MainActor
class MessageContentsViewModel: ObservableObject, Equatable, Identifiable {
    var viewState: ViewState

    @Binding var message: Message
    @Binding var author: User
    @Binding var member: Member?
    @Binding var server: Server?
    @Binding var channel: Channel
    @Binding var channelReplies: [Reply]
    @Binding var editing: Message?

    var channelScrollPosition: ChannelScrollController

    init(viewState: ViewState, message: Binding<Message>, author: Binding<User>, member: Binding<Member?>, server: Binding<Server?>, channel: Binding<Channel>, replies: Binding<[Reply]>, channelScrollPosition: ChannelScrollController, editing: Binding<Message?>) {
        self.viewState = viewState
        self._message = message
        self._author = author
        self._member = member
        self._server = server
        self._channel = channel
        self._channelReplies = replies
        self.channelScrollPosition = channelScrollPosition
        self._editing = editing
    }

    static func == (lhs: MessageContentsViewModel, rhs: MessageContentsViewModel) -> Bool {
        lhs.message.id == rhs.message.id
    }
    
    var id: String {
        message.id
    }

    func delete() async {
        await viewState.http.deleteMessage(channel: channel.id, message: message.id)
    }

    func reply() {
        if !channelReplies.contains(where: { $0.message.id == message.id }) && channelReplies.count < 5 {
            withAnimation {
                channelReplies.append(Reply(message: message))
            }
        }
    }

    func pin() async {
        await viewState.http.pinMessage(channel: channel.id, message: message.id)
    }
    
    func unpin() async {
        await viewState.http.unpinMessage(channel: channel.id, message: message.id)
    }
}

struct MessageContentsView: View {
    @EnvironmentObject var viewState: ViewState
    @ObservedObject var viewModel: MessageContentsViewModel

    @Environment(\.channelMessageSelection) @Binding var channelMessageSelection
        
    var onlyShowContent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let content = Binding(viewModel.$message.content), !content.wrappedValue.isEmpty {
                Contents(text: content, fontSize: 16)
                //.font(.body)
            }
            
            if !onlyShowContent {
                if let embeds = Binding(viewModel.$message.embeds) {
                    ForEach(embeds, id: \.wrappedValue) { embed in
                        MessageEmbed(embed: embed)
                    }
                }
            }
            
            if !onlyShowContent {
                if let attachments = viewModel.message.attachments {
                    VStack(alignment: .leading) {
                        ForEach(attachments) { attachment in
                            MessageAttachment(attachment: attachment)
                        }
                    }
                }
            }
            
            MessageReactions(
                channel: viewModel.channel,
                message: viewModel.message,
                reactions: viewModel.$message.reactions,
                interactions: viewModel.$message.interactions
            )
        }
        .environment(\.currentMessage, viewModel)
    }
}
