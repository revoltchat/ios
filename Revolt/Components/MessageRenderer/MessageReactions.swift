//
//  MessageReactions.swift
//  Revolt
//
//  Created by Angelo on 05/12/2023.
//

import Foundation
import SwiftUI
import Flow
import Types

struct MessageReaction: View {
    @EnvironmentObject var viewState: ViewState
    
    var channel: Channel
    var message: Message
    
    var emoji: String
    @Binding var users: [String]?
    
    var disabled: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            if emoji.count == 26 {
                LazyImage(source: .emoji(emoji), height: 16, width: 16, clipTo: Rectangle())
            } else {
                Text(verbatim: emoji)
                    .font(.system(size: 16))
            }
            
            Text(verbatim: "\(users?.count ?? 0)")
                .font(.footnote)
                .foregroundStyle(disabled ? viewState.theme.foreground2 : viewState.theme.foreground)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 5)
            .foregroundStyle(viewState.theme.background2)
            .addBorder(
                (users?.contains(viewState.currentUser!.id) ?? false)
                   ? viewState.theme.accent
                   : viewState.theme.background2,
                cornerRadius: 5
            )
        )
        .onTapGesture {
            if users?.contains(viewState.currentUser!.id) ?? false {
                Task {
                    await viewState.http.unreactMessage(channel: channel.id, message: message.id, emoji: emoji)
                }
            } else {
                Task {
                    await viewState.http.reactMessage(channel: channel.id, message: message.id, emoji: emoji)
                }
            }
        }
        
        //.disabled(disabled)
    }
}

struct MessageReactions: View {
    @EnvironmentObject var viewState: ViewState
    
    var channel: Channel
    var message: Message
    
    @Binding var reactions: [String: [String]]?
    @Binding var interactions: Interactions?
    
    func getReactions() -> ([(String, Binding<[String]?>)], [(String, Binding<[String]?>)]) {
        var required: [String] = []
        var optional: [String] = []
        
        for emoji in interactions?.reactions ?? [] {
            required.append(emoji)
        }
        
        if let reactions {
            for emoji in reactions.keys {
                if !required.contains(emoji) {
                    optional.append(emoji)
                }
            }
        }
                
        return (
            required.map { (
                $0,
                Binding($reactions)?[$0] ?? .constant([])
            ) },
            optional.map { (
                $0,
                Binding($reactions)?[$0] ?? .constant([])
            ) }
        )
    }
    
    var body: some View {
        let restrict_reactions = interactions?.restrict_reactions ?? false
        let (required, optional) = getReactions()
        
        HFlow(spacing: 4) {
            ForEach(required, id: \.0) { (emoji, users) in
                MessageReaction(channel: channel, message: message, emoji: emoji, users: users)
            }
            
            if required.count != 0, optional.count != 0 {
                Divider()
                    .frame(height: 14)
                    .foregroundStyle(viewState.theme.foreground3)
                    .padding(.horizontal, 2)
            }
            
            ForEach(optional, id: \.0) { (emoji, users) in
                MessageReaction(channel: channel, message: message, emoji: emoji, users: users, disabled: restrict_reactions)
            }
        }
    }
}
