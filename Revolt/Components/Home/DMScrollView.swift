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
                    VStack {
                        Button {
                            viewState.currentChannel = .home
                        } label: {
                            Image(systemName: "house.fill")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .frame(width: 24, height: 24)

                            Text("Home")
                            
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        
                        Button {
                            viewState.currentChannel = .friends
                        } label: {
                            Image(systemName: "person.fill")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .frame(width: 24, height: 24)
                            
                            Text("Friends")
                            
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
                }
                .padding(.vertical, 8)
                
                Section("Conversations") {
                    VStack {
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
                            .padding(6)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, 8)
        .background(viewState.theme.background2.color)
    }
}
