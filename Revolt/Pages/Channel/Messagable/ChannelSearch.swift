//
//  ChannelSearch.swift
//  Revolt
//
//  Created by Angelo on 29/08/2024.
//

import Foundation
import SwiftUI
import Types

struct ChannelSearch: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var channel: Channel
    
    @State var searchQuery: String = ""
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
        .searchable(text: $searchQuery)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .resizable()
                        .frame(width: 24, height: 24)
                    
                    Text("Search")
                }
            }
        }
        .toolbarBackground(viewState.theme.topBar, for: .automatic)
        .onChange(of: searchQuery, { _, query in
            if query.count >= 1, query.count <= 64 {
                Task {
                    let response = try! await viewState.http.searchChannel(channel: channel.id, query: query).get()
                    
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
        })
    }
}
