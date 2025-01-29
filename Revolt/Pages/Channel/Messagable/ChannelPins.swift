//
//  ChannelPins.swift
//  Revolt
//
//  Created by Angelo on 4/11/2024.
//

import Foundation
import SwiftUI
import Types

struct ChannelPins: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var channel: Channel
    
    @State var results: [Types.Message] = []
    
    var body: some View {
        let server = channel.server.map { $viewState.servers[$0] } ?? .constant(nil)
        
        List {
            ForEach(results) { result in
                MessageView(
                    viewModel: .init(
                        viewState: viewState,
                        message: .constant(result),
                        author: .constant(viewState.users[result.author]!),
                        member: .constant(channel.server.flatMap({ viewState.members[$0]?[result.author] })),
                        server: server,
                        channel: $channel,
                        replies: .constant([]),
                        channelScrollPosition: .empty,
                        editing: .constant(nil)
                    ),
                    isStatic: true
                )
            }
            .listRowBackground(viewState.theme.background2)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Image(systemName: "pin.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    
                    Text("Pins")
                }
            }
        }
        .toolbarBackground(viewState.theme.topBar, for: .automatic)
        .task {
            Task {
                let response = try! await viewState.http.fetchChannelPins(channel: channel.id).get()
                
                for user in response.users {
                    if !viewState.users.keys.contains(user.id) {
                        viewState.users[user.id] = user
                    }
                }
                
                for member in response.members {
                    if !(viewState.members[member.id.server]?.keys.contains(member.id.user) ?? false) {
                        viewState.members[member.id.server]![member.id.user] = member
                    }
                }
                
                results = response.messages
            }

        }
    }
}
