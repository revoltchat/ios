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
        List {
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
                    HStack(spacing: 8) {
                        Image(systemName: "house.fill")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)

                        Text("Home")

                        Spacer()
                    }
                }

                Button {
                    viewState.currentChannel = .friends
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)

                        Text("Friends")

                        Spacer()
                    }
                }

                Button {
                    viewState.currentChannel = .channel(savedMessagesChannel.id)
                } label: {
                    HStack {
                        ChannelIcon(channel: .saved_messages(savedMessagesChannel))

                        Spacer()
                    }
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(viewState.theme.background2)

            Section("Conversations") {
                ForEach(viewState.dms.filter { $0 != .saved_messages(savedMessagesChannel) }) { channel in
                    Button {
                        viewState.currentChannel = .channel(channel.id)
                    } label: {
                        HStack {
                            ChannelIcon(channel: channel)
                            Spacer()
                            if let unread = viewState.getUnreadCountFor(channel: channel) {
                                UnreadCounter(unread: unread)
                            }
                        }
                    }
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(viewState.theme.background2)
        }
        .frame(maxWidth: .infinity)
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background2.color)
        .listStyle(.grouped)
    }
}


struct DMScrollView_Previews: PreviewProvider {
    @StateObject static var viewState = ViewState.preview()

    static var previews: some View {
        DMScrollView(currentChannel: $viewState.currentChannel)
            .applyPreviewModifiers(withState: viewState)
    }
}
