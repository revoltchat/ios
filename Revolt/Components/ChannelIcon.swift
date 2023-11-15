//
//  ChannelIcon.swift
//  Revolt
//
//  Created by Angelo on 18/10/2023.
//

import Foundation
import SwiftUI

struct ChannelIcon: View {
    @EnvironmentObject var viewState: ViewState
    var channel: Channel
    
    var body: some View {
        HStack(spacing: 8) {
            switch channel {
                case .text_channel(let c):
                    if let icon = c.icon {
                        LazyImage(source: .file(icon), height: 24, width: 24, clipTo: Rectangle())
                    } else {
                        Image(systemName: "number")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)
                    }
                    
                    Text(c.name)
                    
                case .voice_channel(let c):
                    if let icon = c.icon {
                        LazyImage(source: .file(icon), height: 24, width: 24, clipTo: Rectangle())
                    } else {
                        Image(systemName: "speaker.wave.2")
                            .symbolRenderingMode(.hierarchical)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)
                    }
                    
                    Text(c.name)
                    
                case .group_dm_channel(let c):
                    if let icon = c.icon {
                        LazyImage(source: .file(icon), height: 24, width: 24, clipTo: Rectangle())
                    } else {
                        Image(systemName: "number")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)
                    }
                    
                    Text(c.name)
                    
                case .dm_channel(let c):
                    let recipient = viewState.users[c.recipients.first(where: { $0 != viewState.currentUser!.id })!]!
                    
                    Avatar(user: recipient)
                        .frame(width: 16, height: 16)
                        .frame(width: 24, height: 24)

                    Text(recipient.username)

                case .saved_messages(_):
                    Image(systemName: "note.text")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .frame(width: 24, height: 24)
                    
                    Text("Saved Messages")
            }
        }
    }
}

struct ChannelIcon_Preview: PreviewProvider {
    static var viewState: ViewState = ViewState.preview()
    
    static var previews: some View {
        ChannelIcon(channel: viewState.channels["0"]!)
            .previewLayout(.sizeThatFits)
    }
}

