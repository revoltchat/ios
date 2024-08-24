//
//  DMScrollView.swift
//  Revolt
//
//  Created by Angelo on 27/11/2023.
//

import Foundation
import SwiftUI
import Types

struct DMScrollView: View {
    @EnvironmentObject var viewState: ViewState

    @Binding var currentChannel: ChannelSelection

    var body: some View {
        List {
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
                    Task {
                        let channel = try! await viewState.http.openDm(user: viewState.currentUser!.id).get()
                        viewState.currentChannel = .channel(channel.id)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)
                        
                        Text("Saved Messages")
                        Spacer()
                    }
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(viewState.theme.background2)

            Section("Conversations") {
                ForEach(viewState.dms.filter { switch $0 { case .saved_messages: return false; default: return true } }) { channel in
                    Button {
                        viewState.selectDm(withId: channel.id)
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
        #if os(iOS)
        .listStyle(.grouped)
        #endif
    }
}


struct DMScrollView_Previews: PreviewProvider {
    @StateObject static var viewState = ViewState.preview()

    static var previews: some View {
        DMScrollView(currentChannel: $viewState.currentChannel)
            .applyPreviewModifiers(withState: viewState)
    }
}
