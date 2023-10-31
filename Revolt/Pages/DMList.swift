//
//  DMList.swift
//  Revolt
//
//  Created by Angelo on 18/10/2023.
//

import Foundation
import SwiftUI

struct DMList: View {
    @State var currentDm: String?

    @EnvironmentObject var viewState: ViewState
    
    var body: some View {
        NavigationSplitView {
            List(selection: $currentDm) {
                NavigationLink(destination: Text("Friends")) {
                    Image(systemName: "person.fill")
                        .symbolRenderingMode(.hierarchical)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .frame(width: 24, height: 24)
                    
                    Text("Friends")
                }
                .listRowBackground(viewState.theme.background2.color)

                let channel: SavedMessages = viewState.dms.compactMap { channel in
                    if case .saved_messages(let c) = channel {
                        return c
                    }
                    
                    return nil
                }.first!
                                
                NavigationLink(value: channel.id) {
                    ChannelIcon(channel: .saved_messages(channel))
                }
                .listRowBackground(viewState.theme.background2.color)

                Section("Conversations") {
                    ForEach(viewState.dms.filter {
                        switch $0 {
                            case .saved_messages(_):
                                return false
                            default:
                                return true
                        }
                    }) { channel in
                        NavigationLink(value: channel.id) {
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
                let channel = viewState.channels[currentDm]!
                let messages = Binding($viewState.channelMessages[currentDm])!

                MessageableChannelView(viewModel: MessageableChannelViewModel(viewState: viewState, channel: channel, messages: messages))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            ChannelIcon(channel: channel)
                        }
                    }
                    .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Direct Messages")
            }
        }
    }
}
