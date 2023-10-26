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
                ForEach(viewState.dms) { channel in
                    NavigationLink(value: channel.id) {
                        ChannelIcon(channel: channel)
                    }
                }
            }
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
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
