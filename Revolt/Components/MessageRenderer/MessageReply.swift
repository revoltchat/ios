//
//  MessageReply.swift
//  Revolt
//
//  Created by Angelo on 31/10/2023.
//

import Foundation
import SwiftUI

struct MessageReplyView: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var mentions: [String]?
    @Binding var channelScrollPosition: String?
    @State var dead: Bool = false
    var id: String
    var channel: String
    
    @ViewBuilder
    var body: some View {
        let message = viewState.messages[id]
        if message != nil || dead {
            InnerMessageReplyView(mentions: $mentions, channelScrollPosition: $channelScrollPosition, message: message)
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
    @Binding var channelScrollPosition: String?
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
            .onTapGesture {
                channelScrollPosition = message.id
            }
        } else {
            Text("Unknown message")
        }
    }
}

