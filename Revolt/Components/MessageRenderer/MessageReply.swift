//
//  MessageReply.swift
//  Revolt
//
//  Created by Angelo on 31/10/2023.
//

import Foundation
import SwiftUI
import Types

struct MessageReplyView: View {
    @EnvironmentObject var viewState: ViewState
    
    @State var dead: Bool = false

    @Binding var mentions: [String]?
    
    var channelScrollPosition: ChannelScrollController
    var id: String
    var server: Server?
    var channel: Channel
    
    var body: some View {
        let message = viewState.messages[id]
        
        if message != nil || dead {
            InnerMessageReplyView(mentions: $mentions, channelScrollPosition: channelScrollPosition, server: server, message: message)
        } else {
            if !viewState.loadingMessages.contains(id) {
                let _ = Task {
                    do {
                        let message = try await viewState.http.fetchMessage(channel: channel.id, message: id).get()
                        viewState.messages[id] = message
                        
                        if let server, viewState.members[server.id]?[message.author] == nil {
                            if let member = try? await viewState.http.fetchMember(server: server.id, member: message.author).get() {
                                viewState.members[server.id]?[message.author] = member
                            }
                        }
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
    var channelScrollPosition: ChannelScrollController
    var server: Server?
    var message: Message?
    
    func formatName(message: Message, author: User, member: Member?) -> String {
        (mentions?.contains(message.author) == true ? "@" : "") + (message.masquerade?.name ?? member?.nickname ?? author.display_name ?? author.username)
    }
    
    var body: some View {
        if let message = message {
            let author = viewState.users[message.author] ?? User(id: "0", username: "Unknown User", discriminator: "0000")
            let member = server.flatMap { viewState.members[$0.id] }.flatMap { $0[message.author] }

            HStack(spacing: 4) {
                
                Avatar(user: author, member: member, masquerade: message.masquerade, width: 16, height: 16)
                
                Text(formatName(message: message, author: author, member: member))
                    .lineLimit(1)
                    .foregroundStyle(member?.displayColour(theme: viewState.theme, server: server!) ?? AnyShapeStyle(viewState.theme.foreground.color))
                    .font(.caption)
                
                if !(message.attachments?.isEmpty ?? true) {
                    Text(Image(systemName: "doc.text.fill"))
                        .font(.caption)
                        .foregroundStyle(viewState.theme.foreground2)
                }
                
                if let content = message.content {
                    Text(content)
                        .font(.caption)
                        .foregroundStyle(viewState.theme.foreground2)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .onTapGesture {
                channelScrollPosition.scrollTo(message: message.id)
            }
        } else {
            Text("Unknown message")
                .foregroundStyle(viewState.theme.foreground2)
        }
    }
}
