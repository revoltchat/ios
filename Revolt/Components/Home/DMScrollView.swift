//
//  DMScrollView.swift
//  Revolt
//
//  Created by Angelo on 27/11/2023.
//

import Foundation
import SwiftUI

struct DMScrollView: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var currentChannel: ChannelSelection
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                let savedMessagesChannel: SavedMessages = viewState.dms.compactMap { channel in
                    if case .saved_messages(let c) = channel {
                        return c
                    }
                    
                    return nil
                }.first!
                
                Section {
                    Button {
                        viewState.currentChannel = .home
                    } label: {
                        Text("Home")
                        
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    
                    Button {
                        viewState.currentChannel = .channel(savedMessagesChannel.id)
                    } label: {
                        ChannelIcon(channel: .saved_messages(savedMessagesChannel))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                }
                
                Section("Conversations") {
                    ForEach(viewState.dms.filter { $0 != .saved_messages(savedMessagesChannel) }) { channel in
                        Button {
                            viewState.currentChannel = .channel(channel.id)
                        } label: {
                            ChannelIcon(channel: channel)
                            Spacer()
                            if let unread = viewState.getUnreadCountFor(channel: channel) {
                                UnreadCounter(unread: unread)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .padding(.horizontal, 8)
        .background(viewState.theme.background2.color)
    }
}
