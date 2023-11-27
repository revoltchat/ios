//
//  DMList.swift
//  Revolt
//
//  Created by Angelo on 18/10/2023.
//

import Foundation
import SwiftUI

enum Destination: Hashable, Codable {
    case dm(String)
    case friends
}


struct DMList: View {
    @State var currentDm: Destination?

    @EnvironmentObject var viewState: ViewState
    
    var body: some View {
        NavigationSplitView {
            List(selection: $currentDm) {

                let savedMessagesChannel: SavedMessages = viewState.dms.compactMap { channel in
                    if case .saved_messages(let c) = channel {
                        return c
                    }
                    
                    return nil
                }.first!
                                
                NavigationLink(value: Destination.dm(savedMessagesChannel.id)) {
                    ChannelIcon(channel: .saved_messages(savedMessagesChannel))
                }
                .listRowBackground(viewState.theme.background2.color)

                Section("Conversations") {
                    ForEach(viewState.dms.filter { $0 != .saved_messages(savedMessagesChannel) }) { channel in
                        NavigationLink(value: Destination.dm(channel.id)) {
                            ChannelIcon(channel: channel)
                        }
                    }
                }
                .listRowBackground(viewState.theme.background2.color)
            }
            .scrollContentBackground(.hidden)
            .background(viewState.theme.background.color)

        } detail: {
            if let currentDm = currentDm {
                switch currentDm {
                    case .dm(let id):
                        let channel = viewState.channels[id]!
                        let messages = Binding($viewState.channelMessages[id])!
                        
                        MessageableChannelView(viewModel: MessageableChannelViewModel(viewState: viewState, channel: channel, server: nil, messages: messages), showSidebar: .constant(false))  // TODO: showSidebar

                    case .friends:
                        FriendsList()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Direct Messages")
            }
        }
    }
}
